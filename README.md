# Tinka

iOS SwiftUI app for sales, catalog, voice parsing, and Supabase REST workflows.

## Hackathon documentation

Full project documentation for presentation:

`HACKATHON_DOCUMENTATION.md`

## Supabase hackathon setup

For hackathon runs, disable email confirmation so registration returns a session immediately and avoids confirmation email rate limits:

Supabase Dashboard -> Authentication -> Providers -> Email -> disable **Confirm Email**.

With Confirm Email disabled, Tinka signs the new user in, creates or updates `business_profiles`, and routes to the dashboard. New users start with an empty catalog; starter products are only loaded if the user taps **Cargar base** in Catálogo.

## Supabase data isolation

Run `supabase/rls_policies.sql` in Supabase Dashboard -> SQL Editor before testing with multiple users.

That script enables RLS for the app tables and adds `user_id` ownership to `combo_items` and `sale_items`, so products, combos, sales, report data, and chat history stay independent per account.
