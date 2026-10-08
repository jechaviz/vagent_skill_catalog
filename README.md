# vagent_skill_catalog

Product-neutral V contracts for agent capabilities and skill catalogs.

The module has two reusable surfaces:

- **Site actions** — deterministic phrases, lexical matching, host scope, route resolution, side-effect metadata, and confirmation policy. Hebrowser consumes this surface for site-aware actions such as GitHub navigation and mutations.
- **Agent skill catalog** — generic skill entries, JSON decode/encode, search, adapter discovery, and aggregate statistics. Agent products such as Veloclaw consume these contracts instead of defining reusable catalog schemas under product branding.

The module does not execute actions, call providers, or own product policy. Product runtimes decide how a matched action/skill is activated and must enforce the returned `vaction_contracts` policy where applicable.
