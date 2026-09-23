# Business / Brand Tier

How the brand-partnership offering works, and where each piece lives. Built to stay outside Apple's In-App Purchase requirement — see the IAP note in `AppStoreListing.md` for why this shape specifically.

## The four pieces

1. **Backend tagging** (`supabase/migrations/0002_business_tier_and_scan_analytics.sql`)
   `public.profiles.is_business` / `business_name` — admin-only, no client write path. Set manually in Supabase Studio after a deal is made. **The app never reads or branches on this flag.** "Priority review" is you personally checking Studio and approving business-tagged triggers first — a manual operational choice, not an app feature. This is the whole reason it doesn't need In-App Purchase.

2. **Scan logging** (`MagicKettle/ViewController.swift`, `logScan(for:)`)
   Every time a community trigger is recognized, a row is logged to `public.trigger_scans`. Works with or without sign-in, since scanning never requires an account. This is what gives the analytics page real data to show.

3. **Brand analytics page** — https://arwwaawaoazbrqgutxxz.supabase.co/functions/v1/brand-analytics
   A Supabase Edge Function (`supabase/functions/brand-analytics/`), **not a Claude Artifact** — Artifacts run under a CSP that blocks fetch to arbitrary hosts, and every runtime capability that could bridge that is scoped to signed-in Claude users, which doesn't work for an external brand contact with no Claude account. This is a normal HTTP endpoint instead: paste a trigger's ID into the lookup form (or visit `?trigger=<uuid>` directly) to see its total scan count and a 30-day daily chart. No login. `verify_jwt` is intentionally off — the trigger UUID itself acts as an unguessable share token.

   **To get a trigger's ID**: Supabase Studio → Table Editor → `triggers` → copy the `id` column for the row you want.

4. **Brand pitch page** — https://magicmediaapp.com
   The actual sales asset — explains the offer, how it works, what's included, and routes to your email. Source lives in `web/magicmediaapp.com/` and deploys as a Cloudflare Worker with static assets (not Pages — Cloudflare now steers new deployments to Workers). Domain `magicmediaapp.com` was bought via Cloudflare Registrar and its zone is in the same Cloudflare account, so the Worker is bound to it directly via a Custom Domain route — no separate DNS setup needed. Also still live at the original Claude Artifact (https://claude.ai/artifact/6zm8T5MUY3XLTBiomLWZnK) if that's ever useful, but the real domain is the one to share.

   **To redeploy after editing `web/magicmediaapp.com/public/index.html`**:
   ```
   cd web/magicmediaapp.com && npx wrangler deploy
   ```
   Needs `wrangler` authenticated (`npx wrangler login`) with an account that has the `magicmediaapp.com` zone.

   The hero proof image is referenced via its raw GitHub URL (`raw.githubusercontent.com/.../docs/AppStoreScreenshots/1-hero.png`) rather than bundled into the deploy — keeps the deploy tiny and the image stays in sync with the repo automatically. If the repo goes private or that file moves, this breaks.

## Also published (from earlier work, linked here for the full picture)

- Privacy Policy & Content Guidelines — https://claude.ai/artifact/V8hp3r5icarPowzXKGTHPy
- Support / FAQ — https://claude.ai/artifact/1gs6gn9xuNdWBgUR7Ym3v6

## Workflow for a new brand deal

1. Brand contacts you (via the pitch page's email link, or however).
2. They send you their target image + content, same as any user would — either they get their own account and upload it, or you upload it on their behalf using your own account.
3. Once it's live, mark it in `profiles.is_business = true` for their account (Studio, manual).
4. Approve their trigger (same manual `triggers.status = 'approved'` flow as any other upload).
5. Send them their trigger's analytics link: `https://arwwaawaoazbrqgutxxz.supabase.co/functions/v1/brand-analytics?trigger=<their-trigger-id>`.

## A hard lesson from building the analytics page

The first attempt was a Claude Artifact that made client-side `fetch()` calls to Supabase's REST API with per-trigger links via `?trigger=<uuid>` query params. Two separate things broke it:

- Artifacts' CSP blocks `fetch`/XHR to hosts outside a small CDN allowlist — Supabase's REST API isn't on it, so every request silently failed.
- Artifacts don't forward the outer `claude.ai/artifact/...` URL's query string into the page at all — `location.search` inside the page was always empty, regardless of what was appended to the link that was shared.

Moving to a Supabase Edge Function fixed both at once: no browser CSP for server-side code, and it's a real HTTP endpoint with real query params.
