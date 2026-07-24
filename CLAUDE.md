# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Nahueltrek is a self-administrable single-page site for a trekking tour company in southern Chile: a public marketing site (Inicio, Destinos, Agenda, Tienda, Contacto) plus a password-gated admin panel (Destinos, Agenda, Tienda, Mensajes) for editing content. It is a static Vite/React frontend with Supabase as the only backend — there is no server code in this repo. All UI copy is in Spanish.

## Commands

```bash
npm install      # install dependencies
npm run dev      # start Vite dev server (http://localhost:5173)
npm run build    # production build to dist/
npm run preview  # preview the production build locally
```

There is no test suite, linter, or type checker configured in this repo.

### Local environment

The app requires Supabase credentials to be set as Vite env vars:

```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

Put these in `.env` (not committed) at the project root. If they're missing, `src/lib/supabaseClient.js` logs a warning and creates a client with empty strings, which will fail all Supabase calls.

## Architecture

### Single-file UI

Almost the entire application lives in `src/App.jsx` (~850 lines). It is not split into a `components/` directory — public pages, the admin panel, and shared UI primitives (buttons, cards, form fields) are all defined as sibling functions in this one file. When making changes, search `App.jsx` for the relevant function rather than expecting a directory structure:
- `App` (default export) — top-level state, data loading, and routing between `view: "public" | "admin"`.
- `PublicSite`, `Inicio`, `Destinos`, `Agenda`, `Tienda`, `Contacto` — public pages, switched by the `page` state (`inicio | destinos | agenda | tienda | contacto`), not a router library.
- `AdminArea`, `AdminDestinos`, `AdminAgenda`, `AdminProductos`, `AdminMensajes` — admin panel, switched by `adminTab`.
- Small shared helpers (`btnStyle`, `inputStyle`, `adminInput`, `cardFormStyle`, `rowCardStyle`, `SectionHead`, `Tag`, `IconBtn`, etc.) at the bottom of the file.

Styling is inline JS style objects (no CSS modules/Tailwind/styled-components); `src/index.css` only sets global resets and imports the Google Fonts used (Zilla Slab, Work Sans, IBM Plex Mono). The `COLORS` object at the top of `App.jsx` is the single source of truth for the palette — reuse it rather than hardcoding hex values.

### Data layer and sync pattern

`src/lib/supabaseClient.js` creates the Supabase client from `VITE_SUPABASE_URL`/`VITE_SUPABASE_ANON_KEY`. `src/lib/api.js` exposes two functions used for all data access:
- `fetchTable(table, orderBy)` — selects all rows from a table.
- `syncTable(table, oldList, newList)` — upserts everything in `newList` and deletes rows present in `oldList` but absent from `newList`.

The app **never does one-off inserts/updates/deletes**. Every table (`destinos`, `agenda`, `mensajes`, `productos`) is held in React state as a full in-memory array; admin screens mutate a local copy of that array (add/edit/remove an item) and then call the corresponding `updateX` function in `App` (`updateDestinos`, `updateAgenda`, `updateMensajes`, `updateProductos`), which calls `setState` optimistically and then `syncTable` to reconcile the whole list with Supabase. Follow this same "replace the whole list" pattern for any new admin CRUD screen instead of writing direct insert/update/delete calls.

On first load (`useEffect` in `App`), each table is fetched via `loadTable`; if a table comes back empty, it is seeded once from the `SEED_DESTINOS` / `SEED_AGENDA` / `SEED_PRODUCTOS` constants in `App.jsx` (there is no seed for `mensajes`).

IDs for all records are client-generated via `uid()` (`Math.random().toString(36).slice(2, 9)`), not database-generated — the schema uses `text` primary keys for this reason (see `supabase-schema.sql`).

### Database schema

`supabase-schema.sql` is the canonical schema and must be run manually in the Supabase SQL Editor when setting up a project — there is no migration tooling. Four tables: `destinos`, `agenda` (FK `destinoId` → `destinos.id`), `mensajes`, `productos`. All four have RLS enabled with fully public `select`/`all` policies, because the admin panel does not use real Supabase Auth (see below). If you touch RLS or add a table, keep `supabase-schema.sql` as the up-to-date source of truth and update the comment block explaining the security tradeoff.

### Admin auth is not real auth

`ADMIN_PASSCODE` in `App.jsx` is a hardcoded client-side string compared against the password field — it gates the UI only, not the database. Anyone with the Supabase anon key (visible in the client bundle) can read/write all four tables directly, bypassing the passcode entirely. This is a known, documented tradeoff (see the security note in `supabase-schema.sql` and the README) — don't "fix" it by tightening only the UI; a real fix means migrating to Supabase Auth and restricting RLS policies to authenticated users.

### Deployment and headers

The site is a static build (`npm run build` → `dist/`) meant for Vercel or Netlify with automatic deploy on push. Security headers (HSTS, CSP, X-Frame-Options, etc.) are duplicated in two places for the two hosts and **must be kept in sync**:
- `vercel.json` — used on Vercel.
- `public/_headers` — used on Netlify.

The CSP's `script-src`/`connect-src`/`style-src` allowlist only `'self'`, Google Fonts, and `*.supabase.co`. Adding any third-party script or API (analytics, etc.) requires updating the CSP in **both** files or the browser will block it.
