# NEBox Review Server

Minimal BoxJS-compatible mock backend for TestFlight review.

## Local Run

```bash
cd review-server
npm install
npm start
```

Default port: `8787` (or `PORT` env).

## Required Endpoints

- `GET /query/boxdata`
- `GET /query/versions`
- `GET /query/data/:key`
- `POST /api/update`
- `POST /api/save`
- `POST /api/saveData`
- `POST /api/runScript`

Additional mutation endpoints are stubbed to return success with full `boxdata`.

## Deploy (Render)

This repository includes `render.yaml`.

1. Push this branch to GitHub.
2. In Render, create **Blueprint** from this repo.
3. Deploy service `nebox-review-server`.
4. Copy the HTTPS URL and set it in app `ApiManager.defaultAPIURL` for TF review builds.

## Health Check

- `GET /healthz`

