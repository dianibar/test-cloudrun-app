# SETUP.md — Pre-Apply Configuration for `test-cloudrun-app`

Before running `terraform apply`, you must replace every `TODO` placeholder in the generated Terraform files with real values. This document walks through each one in order. The changes touch four areas: the remote state backend (GCS bucket), the Cloud Run service environment variables, and the IAP-managed SSL certificate domain. Complete all sections below, then follow the Verify steps at the end to confirm everything is ready.

---

## Terraform Remote State (GCS Backend)

The Terraform backend stores your state file remotely in a GCS bucket so that state is shared across machines and teammates. A dedicated bucket must exist before Terraform can initialise.

### `infra/main.tf` — line 16

**What it is:** The name of the GCS bucket that will hold the `test-cloudrun-app` Terraform state file.

**Steps to obtain or create the bucket:**

1. Open the [Google Cloud Console](https://console.cloud.google.com/) and select the project you are deploying into.
2. Navigate to **Cloud Storage → Buckets** and click **Create**.
3. Give the bucket a globally unique name (e.g. `my-company-terraform-state`). Record this name.
4. Choose a region consistent with your service deployment region.
5. Under **Object versioning**, enable versioning — this allows state-file rollback.
6. Leave all other settings at their defaults and click **Create**.
7. Alternatively, create the bucket with the CLI:
   ```bash
   gcloud storage buckets create gs://my-company-terraform-state \
     --project=YOUR_PROJECT_ID \
     --location=us-central1 \
     --uniform-bucket-level-access
   gcloud storage buckets update gs://my-company-terraform-state \
     --versioning
   ```
8. Ensure the account running Terraform has the `roles/storage.admin` role on this bucket.

**Line to update:**
```hcl
bucket = "TODO: set your terraform state bucket"
```
Replace `TODO: set your terraform state bucket` with the bucket name, e.g.:
```hcl
bucket = "my-company-terraform-state"
```

---

## Cloud Run Environment Variables

These values are injected into the `test-cloudrun-app` Cloud Run container at runtime. They must be set to concrete values before the service can start successfully.

### `infra/service.tf` — line 47 (`PORT`)

**What it is:** The TCP port your container's HTTP server listens on. Cloud Run routes incoming requests to this port.

**Steps to determine the correct value:**

1. Check your application's source code or `Dockerfile` for the port your server binds to (common values: `8080`, `3000`, `5000`).
2. If the port is set via an environment variable in code (e.g. `process.env.PORT` or `os.environ["PORT"]`), confirm the default or required value in the application README.
3. If you are free to choose, `8080` is the Cloud Run convention and requires no extra firewall configuration.

**Line to update:**
```hcl
value = "TODO: set value for PORT"
```
Replace with your chosen port, e.g.:
```hcl
value = "8080"
```

---

### `infra/service.tf` — line 51 (`GCP_PROJECT_ID`)

**What it is:** The GCP project ID that the running service will use when making calls to Google Cloud APIs (e.g. Pub/Sub, Firestore, Secret Manager). This is the short identifier, not the display name or project number.

**Steps to obtain the project ID:**

1. In the [Cloud Console](https://console.cloud.google.com/), open the project selector at the top of the page. The **ID** column shows the project ID (e.g. `my-project-123`).
2. Alternatively, run:
   ```bash
   gcloud config get-value project
   ```
3. Or list all projects:
   ```bash
   gcloud projects list --format="table(projectId,name)"
   ```
4. Use the `projectId` value (all lowercase, may include hyphens and numbers).

**Line to update:**
```hcl
value = "TODO: set value for GCP_PROJECT_ID"
```
Replace with your project ID, e.g.:
```hcl
value = "my-project-123"
```

---

## IAP — Managed SSL Certificate Domain

Identity-Aware Proxy in front of Cloud Run requires a Google-managed SSL certificate bound to the public domain name that will serve the application. Google auto-provisions and renews the certificate, but it needs the fully qualified domain name (FQDN) upfront.

### `infra/iap.tf` — line 70

**What it is:** The public domain (or subdomain) at which `test-cloudrun-app` will be reachable. Google uses this to provision a managed TLS certificate via Let's Encrypt.

**Steps to obtain and configure the domain:**

1. Decide on the FQDN you will use, e.g. `test-cloudrun-app.example.com`.
2. Confirm you own or control DNS for that domain. Log in to your DNS provider (e.g. Google Domains, Cloudflare, Route 53).
3. After Terraform creates the load balancer, you will need to add an **A record** pointing your chosen domain to the load balancer's external IP. To retrieve that IP after apply:
   ```bash
   gcloud compute forwarding-rules list --format="table(name,IPAddress)"
   ```
4. In your DNS provider's control panel, create:
   - **Type:** A
   - **Name:** `test-cloudrun-app` (or the full subdomain)
   - **Value:** the external IP from step 3
   - **TTL:** 300 (5 minutes) during initial setup
5. Note: Google-managed certificate provisioning can take up to 20–30 minutes after DNS propagates. Check status with:
   ```bash
   gcloud compute ssl-certificates describe test-cloudrun-app-cert \
     --format="table(name,managed.status,managed.domainStatus)"
   ```

**Line to update:**
```hcl
domains = ["TODO: set your domain e.g. test-cloudrun-app.example.com"]
```
Replace with your FQDN, e.g.:
```hcl
domains = ["test-cloudrun-app.example.com"]
```

---

## Verify

Once all TODOs have been replaced, run the following commands in order to confirm the configuration is valid and ready to apply.

**1. Confirm no TODOs remain in the infra directory:**
```bash
grep -rn "TODO" infra/
```
This should return no output. If any lines are printed, address them before continuing.

**2. Check that the GCS state bucket exists and is accessible:**
```bash
gcloud storage buckets describe gs://YOUR_STATE_BUCKET_NAME
```

**3. Initialise Terraform with the remote backend:**
```bash
cd infra
terraform init
```
Terraform should print `Backend successfully configured` with no errors.

**4. Validate the Terraform configuration:**
```bash
terraform validate
```
Expected output: `Success! The configuration is valid.`

**5. Review the execution plan:**
```bash
terraform plan -out=tfplan
```
Review the planned changes carefully. Confirm that the Cloud Run service, IAP resources, and certificate all appear as expected.

**6. Apply the configuration:**
```bash
terraform apply tfplan
```

**7. After apply, verify the Cloud Run service is running:**
```bash
gcloud run services describe test-cloudrun-app \
  --region=YOUR_REGION \
  --format="table(status.conditions[0].type,status.conditions[0].status)"
```
Expected: `Ready  True`

**8. Check the managed certificate provisioning status:**
```bash
gcloud compute ssl-certificates list \
  --format="table(name,managed.status)"
```
Expected status: `ACTIVE` (may take up to 30 minutes after DNS propagation).