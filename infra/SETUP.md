# SETUP.md — Pre-Apply Configuration for `test-cloudrun-app`

Before running `terraform apply` you must replace every `TODO` placeholder in the `infra/` directory with real values. This document walks through each one in order. The work falls into four areas: **Terraform Remote State**, **IAP OAuth2 Credentials**, **Custom Domain**, and **Cloud Run Environment Variables**. Complete every section, then follow the Verify steps at the bottom to confirm everything is wired up correctly.

---

## Terraform Remote State

Terraform needs a GCS bucket to store its state file. This keeps state out of version control and allows team members to share it safely.

### `infra/main.tf` — line 16

```hcl
bucket = "TODO: set your terraform state bucket"
```

**What it is:** The name of the GCS bucket where Terraform will read and write its state file for this service.

**Steps to obtain or create the bucket:**

1. Open the [Cloud Storage Browser](https://console.cloud.google.com/storage/browser) in the GCP console, or use the CLI.
2. Create a dedicated state bucket if one does not already exist:
   ```bash
   gsutil mb -p YOUR_PROJECT_ID -l YOUR_REGION gs://YOUR_PROJECT_ID-tf-state
   ```
3. Enable versioning so you can recover from accidental state corruption:
   ```bash
   gsutil versioning set on gs://YOUR_PROJECT_ID-tf-state
   ```
4. Note the bucket name (e.g. `my-project-tf-state`).
5. Replace the TODO in **`infra/main.tf` line 16**:
   ```hcl
   bucket = "my-project-tf-state"
   ```

---

## IAP (Identity-Aware Proxy)

IAP protects the Cloud Run service by requiring Google-authenticated users before any request reaches your container. It needs an OAuth2 client so Google's authorization servers can issue tokens on your behalf.

### `infra/iap.tf` — lines 22–23 · `oauth2_client_id` and `oauth2_client_secret`

```hcl
oauth2_client_id     = "TODO: set your IAP OAuth2 client ID"
oauth2_client_secret = "TODO: set your IAP OAuth2 client secret"
```

**What they are:** The client ID and secret of an OAuth 2.0 credential that IAP uses to identify itself to Google's OAuth endpoints. Without them IAP cannot authenticate users.

**Steps to obtain the credentials:**

1. Go to **APIs & Services → Credentials** in the [GCP Console](https://console.cloud.google.com/apis/credentials).
2. Click **+ Create Credentials → OAuth client ID**.
3. If prompted, configure the **OAuth consent screen** first:
   - Choose **Internal** (for Workspace users only) or **External**.
   - Fill in the required app name and support email, then save.
4. Back on the **Create OAuth client ID** screen:
   - **Application type:** Web application
   - **Name:** `test-cloudrun-app-iap` (or any descriptive name)
   - **Authorised redirect URIs:** Add `https://iap.googleapis.com/v1/oauth/clientIds/YOUR_CLIENT_ID:handleRedirect` — you will need to come back and add this after the client is first created (see the [IAP docs](https://cloud.google.com/iap/docs/enabling-cloud-run#oauth-credentials)).
5. Click **Create**. A dialog shows the **Client ID** and **Client secret**. Copy both values immediately.
6. Replace the TODOs in **`infra/iap.tf` lines 22–23**:
   ```hcl
   oauth2_client_id     = "123456789-abcdefg.apps.googleusercontent.com"
   oauth2_client_secret = "GOCSPX-xxxxxxxxxxxxxxxxxxxx"
   ```

> **Security note:** Consider storing the secret in Secret Manager and referencing it via a `data "google_secret_manager_secret_version"` block rather than hard-coding it in source. At minimum, ensure `infra/` is not committed to a public repository.

---

## Custom Domain

The `google_compute_managed_ssl_certificate` resource provisions a Google-managed TLS certificate for your service. It requires a fully-qualified domain name (FQDN) that you control so Google can complete the domain validation challenge.

### `infra/iap.tf` — line 36 · `domains`

```hcl
domains = ["TODO: set your domain e.g. test-cloudrun-app.example.com"]
```

**What it is:** The public hostname that will front the Cloud Run service. Google uses this to issue and auto-renew a managed TLS certificate.

**Steps to configure the domain:**

1. Decide on the hostname you will use, for example `test-cloudrun-app.example.com`.
2. Confirm you have DNS control over that domain (e.g. access to Cloud DNS, Route 53, Cloudflare, or your registrar's DNS panel).
3. Replace the TODO in **`infra/iap.tf` line 36**:
   ```hcl
   domains = ["test-cloudrun-app.example.com"]
   ```
4. After `terraform apply` completes, retrieve the IP address of the forwarding rule:
   ```bash
   terraform output load_balancer_ip
   # or
   gcloud compute forwarding-rules list --filter="name~test-cloudrun-app"
   ```
5. Create an **A record** in your DNS provider pointing `test-cloudrun-app.example.com` → the IP address returned above.
6. Certificate provisioning can take up to 60 minutes after the DNS record propagates. Monitor status with:
   ```bash
   gcloud compute ssl-certificates describe test-cloudrun-app-cert \
     --format="value(managed.status, managed.domainStatus)"
   ```

---

## Cloud Run Environment Variables

These values are injected into the container at runtime via Cloud Run's environment variable mechanism. Each one configures a different aspect of the application.

### `infra/service.tf` — line 47 · `PORT`

```hcl
value = "TODO: set value for PORT"
```

**What it is:** The TCP port the container's HTTP server listens on. Cloud Run routes traffic to this port.

**Steps:**
1. Check your application code or `Dockerfile` for the port it binds to (commonly `8080`).
2. If it is configurable, `8080` is the Cloud Run default and recommended value.
3. Replace the TODO in **`infra/service.tf` line 47**:
   ```hcl
   value = "8080"
   ```

---

### `infra/service.tf` — line 51 · `GCP_PROJECT_ID`

```hcl
value = "TODO: set value for GCP_PROJECT_ID"
```

**What it is:** The GCP project ID passed to the application so it can construct resource references (e.g. when calling GCP client libraries).

**Steps:**
1. Find your project ID:
   ```bash
   gcloud config get-value project
   ```
   or check the [GCP Console dashboard](https://console.cloud.google.com/home/dashboard) under **Project info**.
2. Replace the TODO in **`infra/service.tf` line 51**:
   ```hcl
   value = "my-gcp-project-id"
   ```

---

### `infra/service.tf` — line 55 · `GCS_BUCKET`

```hcl
value = "TODO: set value for GCS_BUCKET"
```

**What it is:** The name of the GCS bucket the application uses for object storage (uploads, exports, assets, etc.).

**Steps:**
1. Identify or create the application-data bucket (this is separate from the Terraform state bucket):
   ```bash
   gsutil mb -p YOUR_PROJECT_ID -l YOUR_REGION gs://test-cloudrun-app-data
   ```
2. Ensure the Cloud Run service account has the `roles/storage.objectAdmin` role on the bucket:
   ```bash
   gsutil iam ch serviceAccount:SA_EMAIL:roles/storage.objectAdmin \
     gs://test-cloudrun-app-data
   ```
3. Replace the TODO in **`infra/service.tf` line 55**:
   ```hcl
   value = "test-cloudrun-app-data"
   ```

---

### `infra/service.tf` — line 59 · `DATABASE_URL`

```hcl
value = "TODO: set value for DATABASE_URL"
```

**What it is:** The full connection string the application uses to reach its database (e.g. PostgreSQL, MySQL, or Cloud SQL).

**Steps for Cloud SQL (PostgreSQL example):**

1. Find your Cloud SQL instance connection name:
   ```bash
   gcloud sql instances describe INSTANCE_NAME --format="value(connectionName)"
   # returns: YOUR_PROJECT:REGION:INSTANCE_NAME
   ```
2. The URL format when using the Cloud SQL Auth Proxy (socket) is:
   ```
   postgresql://USER:PASSWORD@localhost/DB_NAME?host=/cloudsql/PROJECT:REGION:INSTANCE
   ```
3. **Do not hard-code passwords in Terraform files.** Store the full URL as a Secret Manager secret and reference it:
   ```bash
   echo -n "postgresql://app:s3cr3t@localhost/appdb?host=/cloudsql/proj:us-central1:inst" \
     | gcloud secrets create test-cloudrun-app-db-url --data-file=-
   ```
   Then in `service.tf`, replace the plain `env` block with a `env` + `value_source` secret reference (see the [Cloud Run secret docs](https://cloud.google.com/run/docs/configuring/secrets)).

4. If you are using a plain connection string for now (non-production only), replace the TODO in **`infra/service.tf` line 59**:
   ```hcl
   value = "postgresql://user:password@host:5432/dbname"
   ```

---

## Verify

After all TODOs have been replaced, run the following commands in order:

```bash
# 1. Confirm there are no remaining TODO strings in the infra directory
grep -rn "TODO" infra/ && echo "TODOs remain — fix before proceeding" || echo "No TODOs found"

# 2. Initialise Terraform (downloads providers and configures the remote backend)
cd infra
terraform init

# 3. Validate syntax and internal consistency
terraform validate

# 4. Review the execution plan — inspect every resource before applying
terraform plan -out=tfplan

# 5. Apply the plan
terraform apply tfplan

# 6. Confirm the Cloud Run service is active
gcloud run services describe test-cloudrun-app \
  --region=YOUR_REGION \
  --format="value(status.url, status.conditions[0].type)"

# 7. Check the managed TLS certificate status (allow up to 60 min after DNS propagation)
gcloud compute ssl-certificates list --filter="name~test-cloudrun-app"

# 8. Verify IAP is protecting the URL (expect a Google login redirect)
curl -I https://test-cloudrun-app.example.com
```