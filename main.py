import os
from flask import Flask, jsonify
from google.cloud import bigquery, storage

app = Flask(__name__)
bq_client = bigquery.Client()
gcs_client = storage.Client()


@app.route("/health")
def health():
    return jsonify({"status": "ok"})


@app.route("/query")
def query():
    project = os.environ.get("GCP_PROJECT_ID", "")
    rows = list(bq_client.query("SELECT CURRENT_TIMESTAMP() AS ts").result())
    return jsonify({"project": project, "ts": str(rows[0]["ts"])})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
