import Foundation

// MARK: - Voice Normalizer
// All string normalization lives here so both Parser and Model can share it.

enum VoiceNormalizer {

    /// Lowercase + strip diacritics + collapse whitespace + remove punctuation
    static func normalize(_ s: String) -> String {
        let lower = s.lowercased()
        // Remove diacritics
        let noDiac = lower.folding(options: .diacriticInsensitive, locale: .current)
        // Remove non-alphanumeric except spaces
        let cleaned = noDiac.unicodeScalars.filter {
            CharacterSet.alphanumerics.union(.whitespaces).contains($0)
        }
        let str = String(cleaned)
        // Collapse multiple spaces
        return str.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Generate common plural variants for a normalized base
    static func plurals(of base: String) -> [String] {
        var result: [String] = []
        if base.hasSuffix("a") || base.hasSuffix("e") || base.hasSuffix("o") {
            result.append(base + "s")
        } else if base.hasSuffix("n") || base.hasSuffix("r") || base.hasSuffix("z") || base.hasSuffix("l") {
            result.append(base + "es")
        } else {
            result.append(base + "s")
        }
        // First word plural for multi-word names ("pique macho" → "piques macho")
        let parts = base.components(separatedBy: " ")
        if parts.count > 1 {
            let firstPlurals = plurals(of: parts[0])
            let rest = parts.dropFirst().joined(separator: " ")
            for fp in firstPlurals { result.append("\(fp) \(rest)") }
        }
        return result
    }
}

// MARK: - Levenshtein fuzzy distance

enum Levenshtein {
    static func distance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        let m = a.count, n = b.count
        if m == 0 { return n }; if n == 0 { return m }
        var prev = Array(0...n)
        for i in 1...m {
            var curr = [i] + Array(repeating: 0, count: n)
            for j in 1...n {
                if a[i-1] == b[j-1] { curr[j] = prev[j-1] }
                else { curr[j] = 1 + min(prev[j-1], prev[j], curr[j-1]) }
            }
            prev = curr
        }
        return prev[n]
    }

    /// Returns true if strings are "close enough" given their lengths
    static func isFuzzyMatch(_ query: String, _ target: String) -> Bool {
        let d = distance(query, target)
        let maxLen = max(query.count, target.count)
        guard maxLen > 0 else { return true }
        // Allow 1 edit per 4 chars (25%), minimum threshold 1 for short words
        let threshold = max(1, maxLen / 4)
        return d <= threshold
    }
}

// MARK: - Parse Result

struct ParsedMatch {
    let product: CatalogProduct
    let qty: Int
    let confidence: MatchConfidence

    enum MatchConfidence {
        case exact      // direct term match
        case fuzzy      // Levenshtein close match
    }
}

// MARK: - Voice Parser

enum VoiceParser {

    private static let numberWords: [(String, Int)] = [
        ("veinte", 20), ("dieciocho", 18), ("diecisiete", 17), ("dieciseis", 16),
        ("quince", 15), ("catorce", 14), ("trece", 13), ("doce", 12),
        ("once", 11), ("diez", 10), ("nueve", 9), ("ocho", 8),
        ("siete", 7), ("seis", 6), ("cinco", 5), ("cuatro", 4),
        ("tres", 3), ("dos", 2), ("media", 1), ("una", 1), ("uno", 1), ("un", 1)
    ]

    // MARK: - Public API

    /// Full parse returning high-confidence matches + low-confidence suggestions
    static func parse(_ raw: String) -> VoiceParseResult {
        let text = VoiceNormalizer.normalize(raw)
        guard !text.isEmpty else { return VoiceParseResult(confirmed: [], ambiguous: []) }

        let catalog = AppState.shared.catalogProducts.filter { $0.isActive }
        let combos  = AppState.shared.combos.filter { $0.isActive }

        // Build matchable entries: products and combos share the same voice pipeline.
        var entries: [(id: UUID, terms: [String], name: String, price: Double, emoji: String)] = []
        for p in catalog {
            entries.append((id: p.id, terms: p.allVoiceTerms, name: p.name, price: p.price, emoji: p.emoji))
        }
        for c in combos {
            let base = VoiceNormalizer.normalize(c.name)
            var terms = [base] + VoiceNormalizer.plurals(of: base)
            for alias in c.aliases {
                let normalized = VoiceNormalizer.normalize(alias)
                terms.append(normalized)
                terms.append(contentsOf: VoiceNormalizer.plurals(of: normalized))
            }
            let parts = base.components(separatedBy: " ")
            if parts.count > 1 { terms.append(contentsOf: [parts[0], parts[0] + "s"]) }
            entries.append((id: c.id, terms: Array(Set(terms)), name: c.name, price: c.finalPrice, emoji: c.emoji))
        }

        // Split on connectors
        let segments = splitSegments(text)
        var confirmed: [SaleProduct] = []
        var ambiguousCandidates: [(query: String, matches: [ParsedMatch])] = []
        var usedNames = Set<String>()

        // Pass 1: exact term matching per segment
        for seg in segments {
            let qty = detectNumber(in: seg) ?? detectNumber(in: text) ?? 1
            if isGenericCombo(seg), combos.count > 1 {
                let candidates = combos.map {
                    ParsedMatch(product: CatalogProduct(id: $0.id, name: $0.name, price: $0.finalPrice,
                                                        category: "Combo", emoji: $0.emoji,
                                                        aliases: $0.aliases),
                                qty: qty, confidence: .fuzzy)
                }
                ambiguousCandidates.append((query: seg, matches: candidates))
                continue
            }
            if let match = exactMatch(seg, entries: entries, usedNames: usedNames) {
                confirmed.append(SaleProduct(name: match.name, qty: qty, price: match.price))
                usedNames.insert(match.name)
            }
        }

        // Pass 2: full-text exact scan for anything still unmatched
        if confirmed.isEmpty {
            for entry in entries where !usedNames.contains(entry.name) {
                if entry.terms.contains(where: { text.contains($0) }) {
                    let qty = detectNumber(in: text) ?? 1
                    confirmed.append(SaleProduct(name: entry.name, qty: qty, price: entry.price))
                    usedNames.insert(entry.name)
                }
            }
        }

        // Pass 3: fuzzy matching on each segment token for unmatched content
        let unmatchedSegs = segments.filter { seg in
            exactMatch(seg, entries: entries, usedNames: Set()) == nil
                && !isGenericCombo(seg)
        }
        for seg in unmatchedSegs {
            let fuzzyHits = fuzzyMatch(seg, entries: entries, usedNames: usedNames)
            if fuzzyHits.count == 1 {
                // Single fuzzy match → add as confirmed (high confidence)
                let hit = fuzzyHits[0]
                if !usedNames.contains(hit.product.name) {
                    let qty = detectNumber(in: seg) ?? detectNumber(in: text) ?? 1
                    confirmed.append(SaleProduct(name: hit.product.name, qty: qty, price: hit.product.price))
                    usedNames.insert(hit.product.name)
                }
            } else if fuzzyHits.count > 1 {
                // Multiple fuzzy matches → ambiguous, ask user
                let qty = detectNumber(in: seg) ?? detectNumber(in: text) ?? 1
                let candidates = fuzzyHits.map {
                    ParsedMatch(product: $0.product, qty: qty, confidence: .fuzzy)
                }
                ambiguousCandidates.append((query: seg, matches: candidates))
            }
        }

        let merged = mergeDuplicates(confirmed)
        return VoiceParseResult(confirmed: merged, ambiguous: ambiguousCandidates.first.map { $0.matches } ?? [])
    }

    // MARK: - Private helpers

    private static func splitSegments(_ text: String) -> [String] {
        text.components(separatedBy: ",")
            .flatMap { $0.components(separatedBy: " y ") }
            .flatMap { $0.components(separatedBy: " mas ") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func exactMatch(
        _ seg: String,
        entries: [(id: UUID, terms: [String], name: String, price: Double, emoji: String)],
        usedNames: Set<String>
    ) -> (name: String, price: Double)? {
        for entry in entries where !usedNames.contains(entry.name) {
            for term in entry.terms {
                // Whole-word containment check
                let pattern = "(^|\\s)\(NSRegularExpression.escapedPattern(for: term))(\\s|$)"
                if seg.range(of: pattern, options: .regularExpression) != nil {
                    return (entry.name, entry.price)
                }
                // Also try simple containment for single-word terms
                if term.count >= 4 && seg.contains(term) {
                    return (entry.name, entry.price)
                }
            }
        }
        return nil
    }

    private static func fuzzyMatch(
        _ seg: String,
        entries: [(id: UUID, terms: [String], name: String, price: Double, emoji: String)],
        usedNames: Set<String>
    ) -> [ParsedMatch] {
        // Extract meaningful tokens (skip number words and filler)
        let fillers = Set(["vendi", "compre", "dame", "quiero", "un", "una", "uno", "dos", "tres",
                           "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "diez",
                           "vende", "vendio", "de", "del", "la", "el", "los", "las", "una", "y", "mas"])
        let tokens = seg.components(separatedBy: .whitespaces)
            .filter { $0.count >= 3 && !fillers.contains($0) }
        let query = tokens.joined(separator: " ")

        var hits: [ParsedMatch] = []
        let catalog = AppState.shared.catalogProducts.filter { $0.isActive }

        for entry in entries where !usedNames.contains(entry.name) {
            var bestDist = Int.max
            if !query.isEmpty {
                for term in entry.terms {
                    bestDist = min(bestDist, Levenshtein.distance(query, term))
                    if term.contains(query) || query.contains(term) { bestDist = min(bestDist, 0) }
                }
            }
            for token in tokens {
                for term in entry.terms {
                    let d = Levenshtein.distance(token, term)
                    if d < bestDist { bestDist = d }
                    // Also check if token is a substring of term or vice versa
                    if term.contains(token) || token.contains(term) { bestDist = min(bestDist, 0) }
                }
            }
            let maxLen = max(tokens.first?.count ?? 1, entry.terms.first?.count ?? 1)
            let threshold = max(1, maxLen / 4)
            if bestDist <= threshold {
                let prod = catalog.first { $0.name == entry.name }
                    ?? CatalogProduct(id: entry.id, name: entry.name, price: entry.price,
                                      category: "", emoji: "", description: "")
                hits.append(ParsedMatch(product: prod, qty: 1,
                                        confidence: bestDist == 0 ? .exact : .fuzzy))
            }
        }
        return hits.sorted { $0.confidence == .exact && $1.confidence != .exact }
    }

    // MARK: - Number detection

    static func detectNumber(in text: String) -> Int? {
        let words = text.components(separatedBy: .whitespaces)
        for w in words { if let n = Int(w), n > 0, n <= 99 { return n } }
        for (word, value) in numberWords {
            let pattern = "(^|\\s)\(word)(\\s|$)"
            if text.range(of: pattern, options: .regularExpression) != nil { return value }
        }
        return nil
    }

    private static func isGenericCombo(_ seg: String) -> Bool {
        let cleaned = seg.components(separatedBy: .whitespaces)
            .filter { !["un", "una", "uno", "dos", "tres", "cuatro", "cinco", "vendi", "vendí", "dame"].contains($0) }
            .joined(separator: " ")
        return cleaned == "combo" || cleaned == "combos"
    }

    private static func mergeDuplicates(_ products: [SaleProduct]) -> [SaleProduct] {
        var order: [String] = []
        var totals: [String: (qty: Int, price: Double)] = [:]
        for product in products {
            if totals[product.name] == nil { order.append(product.name) }
            let current = totals[product.name] ?? (0, product.price)
            totals[product.name] = (current.qty + product.qty, product.price)
        }
        return order.compactMap { name in
            guard let value = totals[name] else { return nil }
            return SaleProduct(name: name, qty: value.qty, price: value.price)
        }
    }
}

// MARK: - Parse Result Type

struct VoiceParseResult {
    /// Products detected with high confidence
    var confirmed: [SaleProduct]
    /// Fuzzy candidates needing user confirmation ("did you mean?")
    var ambiguous: [ParsedMatch]

    var hasAmbiguity: Bool { !ambiguous.isEmpty }
    var isEmpty: Bool { confirmed.isEmpty && ambiguous.isEmpty }
}
