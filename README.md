# Tinka

iOS SwiftUI app for sales, catalog, voice parsing, and Supabase REST workflows.

## Hackathon documentation

Full project documentation for presentation:

`HACKATHON_DOCUMENTATION.md`

## Voice catalog learning

Tinka can learn new products directly from a voice sale. If the user says a product that is not in the current catalog and includes a price, the app proposes adding it to the catalog before confirming the sale.

Supported examples:

- `Vendí un pollo frito a doce bolivianos`
- `Vendí un pollo frito a doce pesos`
- `Vendí una fanta a 5`
- `Vendí un pollo frito a doce bolivianos y una fanta a 5`

When confirmed, Tinka:

- adds each new product to the current user's catalog,
- stores the detected price,
- supports Bolivian daily speech such as `pesos`, `bolivianos`, and `bs`,
- keeps any already-known products in the same sale,
- prepares the full sale for final confirmation.

## Supabase hackathon setup

For hackathon runs, disable email confirmation so registration returns a session immediately and avoids confirmation email rate limits:

Supabase Dashboard -> Authentication -> Providers -> Email -> disable **Confirm Email**.

With Confirm Email disabled, Tinka signs the new user in, creates or updates `business_profiles`, and routes to the dashboard. New users start with an empty catalog; starter products are only loaded if the user taps **Cargar base** in Catálogo.

## Supabase data isolation

Run `supabase/rls_policies.sql` in Supabase Dashboard -> SQL Editor before testing with multiple users.

That script enables RLS for the app tables and adds `user_id` ownership to `combo_items` and `sale_items`, so products, combos, sales, report data, and chat history stay independent per account.
