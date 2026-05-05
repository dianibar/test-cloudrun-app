# SETUP.md — `test-cloudrun-app` Pre-Apply Configuration

Before running `terraform apply` you must replace every `TODO` placeholder in the `infra/` directory with real values. This document walks through each one in order. The work falls into four areas: **Terraform Remote State**, **Identity-Aware Proxy (IAP)**, **Custom Domain**, and **Cloud Run Environment Variables**. Complete all sections, then follow the [Verify](#verify) steps at the bottom to confirm everything is wired up correctly.

---

## Terraform Remote State

The Terraform backend must point to a real GCS bucket so that state is stored remotely and can be shared across team members and CI/CD pipelines.

### `infra/main.tf` — line 16

```hcl
bucket = "TODO: set your terraform state bucket"
```

**What it is:** The name of the GCS bucket where Terraform will read and write its state file for `test-cloudrun-app`.

**Steps:**

1. Open the [Cloud Storage Browser](https://console.cloud.google.com/storage/browser) in the GCP Console.
2. Click **Create bucket**.
3. Choose a globally unique name (e.g. `my-org-terraform-state`), select a region close to your workload, and enable **Versioning** (strongly recommended for state buckets).
4. Click **Create**.
5. Alternatively, create it with the CLI:
   ```bash
   gsutil mb -l US-CENTRAL1 gs://my-org-terraform-state
   gsutil versioning set on gs://my-org-terraform-state
   ```
6. Replace the placeholder with your bucket name:
   ```hcl
   bucket = "my-org-terraform-state"
   ```

> **Note:** After updating this value, run `terraform init` (or re-run it) so Terraform configures the new backend.

---

## Identity-Aware Proxy (IAP)

IAP sits in front of your Cloud Run service and enforces Google-identity authentication. It requires an OAuth 2.0 client that you create in the GCP Console.

### `infra/iap.tf` — lines 22–23

```hcl
oauth2_client_id     = "TODO: set your IAP OAuth2 client ID"
oauth2_client_secret = "TODO: set your IAP OAuth2 client secret"
```

**What they are:** The OAuth 2.0 credentials that IAP uses to redirect unauthenticated users to Google's sign-in page and verify the resulting token.

**Steps:**

1. In the GCP Console, go to **APIs & Services → Credentials** ([direct link](https://console.cloud.google.com/apis/credentials)).
2. Click **Create Credentials → OAuth client ID**.
3. If prompted, configure the **OAuth consent screen** first:
   - Choose **Internal** (for a corporate app) or **External**.
   - Fill in the required fields (app name, support email) and click **Save**.
4. Back on the **Create OAuth client ID** screen, select **Web application** as the application type.
5. Under **Authorised redirect URIs**, add:
   ```
   https://iap.googleapis.com/v1/oauth/clientIds/<CLIENT_ID>:handleRedirect
   ```
   (You can come back and add this after the client is created — you'll need the client ID first.)
6. Click **Create**. A dialog shows your **Client ID** and **Client Secret** — copy both immediately.
7. Update `infra/iap.tf`:
   ```hcl
   oauth2_client_id     = "123456789-abcdef.apps.googleusercontent.com"
   oauth2_client_secret = "GOCSPX-xxxxxxxxxxxxxxxxxxxx"
   ```

> **Security tip:** Consider storing the secret in Secret Manager and referencing it via a `data "google_secret_manager_secret_version"` data source instead of hardcoding it in the `.tf` file.

---

## Custom Domain

The managed SSL certificate resource needs the fully-qualified domain name that will route traffic to your Cloud Run service.

### `infra/iap.tf` — line 36

```hcl
domains = ["TODO: set your domain e.g. test-cloudrun-app.example.com"]
```

**What it is:** The public hostname for `test-cloudrun-app`. GCP will provision and auto-renew a managed TLS certificate for this domain.

**Steps:**

1. Decide on the domain you will use, e.g. `test-cloudrun-app.example.com`.
2. Verify you own or control the DNS zone for that domain.
3. Replace the placeholder:
   ```hcl
   domains = ["test-cloudrun-app.example.com"]
   ```
4. After `terraform apply`, GCP will output a **Load Balancer IP address**. Create a DNS `A` record pointing your chosen domain to that IP:
   - In your DNS provider's console, add an `A` record:
     - **Name:** `test-cloudrun-app` (or the full subdomain)
     - **Value:** `<load-balancer-ip>`
     - **TTL:** 300 (or your provider's minimum)
   - If using Cloud DNS, run:
     ```bash
     gcloud dns record-sets create test-cloudrun-app.example.com. \
       --zone=your-managed-zone \
       --type=A \
       --ttl=300 \
       --rrdatas=<load-balancer-ip>
     ```
5. Certificate provisioning can take up to 20 minutes after DNS propagates.

---

## Cloud Run Environment Variables

These values are injected into the running container at startup. Set each one to match your actual infrastructure resources.

### `infra/service.tf` — line 47: `PORT`

```hcl
value = "TODO: set value for PORT"
```

**What it is:** The TCP port your container listens on. Cloud Run routes HTTP traffic to this port.

**Steps:**

1. Check your application code or `Dockerfile` for the `EXPOSE` instruction or the port your HTTP server binds to (common values: `8080`, `3000`, `5000`).
2. Update the line:
   ```hcl
   value = "8080"
   ```

---

### `infra/service.tf` — line 51: `GCP_PROJECT_ID`

```hcl
value = "TODO: set value for GCP_PROJECT_ID"
```

**What it is:** The GCP project ID where `test-cloudrun-app` is deployed. The application uses this to call other GCP APIs (e.g. GCS, Pub/Sub) without hardcoding credentials.

**Steps:**

1. Find your project ID in the [GCP Console dashboard](https://console.cloud.google.com/home/dashboard) — it appears under the project name in the top bar.
2. Or run:
   ```bash
   gcloud config get-value project
   ```
3. Update the line:
   ```hcl
   value = "my-gcp-project-id"
   ```

---

### `infra/service.tf` — line 55: `GCS_BUCKET`

```hcl
value = "TODO: set value for GCS_BUCKET"
```

**What it is:** The name of the GCS bucket the application reads from or writes to at runtime (separate from the Terraform state bucket).

**Steps:**

1. If the bucket already exists, find its name in the [Cloud Storage Browser](https://console.cloud.google.com/storage/browser).
2. If it does not exist yet, create it:
   ```bash
   gsutil mb -l US-CENTRAL1 gs://test-cloudrun-app-data
   ```
3. Ensure the Cloud Run service account has at least `roles/storage.objectAdmin` on this bucket:
   ```bash
   gsutil iam ch serviceAccount:<SERVICE_ACCOUNT_EMAIL>:objectAdmin \
     gs://test-cloudrun-app-data
   ```
4. Update the line:
   ```hcl
   value = "test-cloudrun-app-data"
   ```

---

### `infra/service.tf` — line 59: `DATABASE_URL`

```hcl
value = "TODO: set value for DATABASE_URL"
```

**What it is:** The full connection string for the application's database (e.g. Cloud SQL, AlloyDB, or an external Postgres instance). This is sensitive and should be handled carefully.

**Steps:**

1. **For Cloud SQL (Postgres via Unix socket — recommended for Cloud Run):**
   ```
   postgresql://USER:PASSWORD@/DBNAME?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME
   ```
   - Find your instance connection name in the [Cloud SQL Console](https://console.cloud.google.com/sql/instances) under **Overview → Connect to this instance**.
2. **For Cloud SQL (public IP / TCP):**
   ```
   postgresql://USER:PASSWORD@<PUBLIC_IP>:5432/DBNAME
   ```
3. **Recommended — store the secret in Secret Manager** instead of plaintext:
   ```bash
   echo -n "postgresql://user:pass@/dbname?host=/cloudsql/..." | \
     gcloud secrets create test-cloudrun-app-db-url --data-file=-
   ```
   Then in `service.tf` replace the `env` block with a `secret_env_var` block referencing the secret, and remove the plaintext `value`.
4. If using the plaintext approach for now, update:
   ```hcl
   value = "postgresql://myuser:mypassword@/mydb?host=/cloudsql/my-project:us-central1:my-instance"
   ```

> **Warning:** Never commit a real `DATABASE_URL` containing passwords to source control. Use Secret Manager or a `.tfvars` file that is listed in `.gitignore`.

---

## Verify

After filling in all TODO values, run the following commands in order:

```bash
# 1. Re-initialise Terraform to pick up the updated backend bucket
terraform -chdir=infra init

# 2. Validate that the configuration is syntactically correct
terraform -chdir=infra validate

# 3. Review the execution plan — confirm no unexpected resources are being destroyed
terraform -chdir=infra plan

# 4. Apply the configuration
terraform -chdir=infra apply

# 5. After apply, confirm the Cloud Run service is running
gcloud run services describe test-cloudrun-app \
  --region=<your-region> \
  --format="value(status.url)"

# 6. Check that the managed certificate is provisioning (status should reach ACTIVE within ~20 min)
gcloud compute ssl-certificates list --filter="name~test-cloudrun-app"

# 7. Verify IAP is enabled on the backend service
gcloud compute backend-services list --global \
  --filter="name~test-cloudrun-app" \
  --format="table(name,iap.enabled)"

# 8. Send a test request through the IAP-protected URL (should redirect to Google sign-in or return 200 with valid credentials)
curl -I https://test-cloudrun-app.example.com
```