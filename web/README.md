# Web

Public landing and interactive map for Baches Tizimín.

## Stack

- Astro 6 with the Node adapter (server-side data fetching)
- React islands for the map explorer
- Tailwind CSS v4
- shadcn/ui components on top of Radix primitives
- MapLibre GL JS with OpenFreeMap tiles
- Self-hosted Archivo, Public Sans and DM Mono fonts

## Run

The backend must be running at `http://localhost:3000`.

```bash
cp .env.example .env
npm install --include=dev
npm run dev
```

- Landing: `http://localhost:4321/`
- Full map: `http://localhost:4321/mapa`
- App status page: `http://localhost:4321/app`

## Environment

| Variable | Purpose |
|---|---|
| `API_URL` | Backend URL used by Astro on the server |
| `PUBLIC_API_URL` | Backend URL used by the browser for photos |
| `PUBLIC_APP_URL` | Destination for the citizen app links |
| `PUBLIC_MAP_STYLE_URL` | MapLibre style URL |

## Components

The UI lives in `src/components/ui` and is generated with shadcn/ui. To add another component:

```bash
npx shadcn@latest add <component>
```

The map explorer (`src/components/map/PotholeExplorer.tsx`) uses `Tabs`, `ToggleGroup`, `Select`, `Input`, `ScrollArea`, `Dialog`, `Badge`, `Alert` and `Skeleton`. The landing uses a live MapLibre preview and the full map reuses the same GeoJSON data.

## Checks

```bash
npm run check
npm run build
```
