# test-cloudrun-app

Test Cloud Run service (Python/Flask) used to verify the deploy-agent generates correct Cloud Run infrastructure.

## What it does

Flask app with two endpoints:
- `GET /health` — health check
- `GET /query` — runs a BigQuery query

Uses `google-cloud-bigquery` and `google-cloud-storage`, so the agent should infer `roles/bigquery.jobUser` and `roles/storage.objectViewer`.

## Environment variables

See `.env.example`. Sensitive vars: `API_KEY`, `SECRET_KEY`, `STRIPE_TOKEN`.

## Running locally

```bash
pip install -r requirements.txt
flask run --port 8080
```
