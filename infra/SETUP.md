# SETUP.md — Pre-Apply Configuration for `test-cloudrun-app`

Before running `terraform apply` for the first time you must complete four manual steps: provision a GCS bucket for Terraform remote state, supply two Cloud Run environment variable values, and — after the first apply — create a DNS record so that Google's managed SSL certificate can be provisioned. Each item is described in detail below. Work through them in order; the DNS step must happen **after** the initial `terraform apply` completes successfully.

---

## Terraform Remote State Bucket

**What it is:** Terraform stores its state file remotely in a GCS bucket so that all team members and CI pipelines share a single source of truth about deployed infrastructure. The bucket must exist before Terraform's `init` command can succeed.

**Steps:**

1. Open [Cloud Storage → Buckets](https://console.cloud.google.com/storage/browser) in the GCP Console, or use the CLI.
2. Choose a globally unique name (recommended pattern: `<project-id>-tfstate`).
3. Create the bucket with versioning enabled so you can recover previous state files:
   ```bash
   gcloud storage buckets create gs://<your-bucket-name> \
     --project=<your-gcp-project-id> \
     --location=<region, e.g. us-central1> \
     --uniform-bucket-level-access

   gcloud storage buckets update gs://<your-bucket-name> \
     --versioning
   ```
4. Confirm the bucket exists:
   ```bash
   gcloud storage buckets describe gs://<your-bucket-name>
   ```

**File to update — `infra/main.tf` line 16:**
```hcl
  backend "gcs" {
    bucket = "<your-bucket-name>"   # ← replace the TODO
    prefix = "test-cloudrun-app"
  }
```

---

## Cloud Run Environment Variables

### `PORT`

**What it is:** The TCP port your container listens on. Cloud Run routes inbound HTTPS traffic to this port, so it must match the `EXPOSE` instruction (or the default listen port) in your application's Dockerfile.

**Steps:**

1. Open your application's `Dockerfile` and locate the `EXPOSE` line, for example `EXPOSE 8080`.
2. If there is no `EXPOSE` line, check your application's startup code for the port it binds to (e.g. `app.listen(3000)` → use `3000`).
3. Use that integer value as the setting. Cloud Run's default — and the most common value — is `8080`.

**File to update — `infra/service.tf` line 47:**
```hcl
      env {
        name  = "PORT"
        value = "8080"   # ← replace the TODO with your actual port
      }
```

---

### `GCP_PROJECT_ID`

**What it is:** The GCP project ID (not the project number or display name) is passed to the application at runtime so it can call GCP APIs (e.g. Firestore, Pub/Sub) without hard-coding the project identifier in application code.

**Steps:**

1. Find your project ID using the Console: open the [project selector](https://console.cloud.google.com/projectselector2/home/dashboard) and note the **ID** column (it looks like `my-project-123`, not the numeric project number).
2. Alternatively, retrieve it with the CLI:
   ```bash
   gcloud config get-value project
   ```
   or list all projects:
   ```bash
   gcloud projects list --format="table(projectId,name)"
   ```
3. Copy the project ID string exactly.

**File to update — `infra/service.tf` line 51:**
```hcl
      env {
        name  = "GCP_PROJECT_ID"
        value = "my-project-123"   # ← replace the TODO with your project ID
      }
```

---

## IAP / Load Balancer — DNS A Record

**What it is:** Google's managed SSL certificate service requires that a public DNS A record pointing your custom domain to the load balancer's external IP exists and is globally resolvable before it will issue a certificate. This step can only be completed **after** the first `terraform apply` creates the load balancer.

**Steps:**

1. Run the first `terraform apply` (after filling in all TODOs above). It will complete but the SSL certificate will remain in a `PROVISIONING` state — that is expected.
2. Retrieve the external IP address that was allocated for the load balancer:
   ```bash
   terraform output load_balancer_ip
   ```
3. Log in to your DNS provider (e.g. Cloud DNS, Cloudflare, Route 53).
4. **If using Cloud DNS:**
   ```bash
   gcloud dns record-sets create <your.domain.com>. \
     --zone=<your-managed-zone-name> \
     --type=A \
     --ttl=300 \
     --rrdatas=<IP from step 2>
   ```
5. **If using an external DNS provider:** create an `A` record for your domain pointing to the IP from step 2 through your provider's web console. Set the TTL to 300 seconds (5 minutes) to allow faster propagation during setup.
6. Verify the record is propagating:
   ```bash
   dig +short <your.domain.com>
   # Should return the load balancer IP
   ```
7. Once DNS resolves correctly, re-apply Terraform with your domain:
   ```bash
   terraform apply -var='domain=your.domain.com'
   ```
8. Google will now provision the managed SSL certificate; this can take up to 20 minutes. Check status:
   ```bash
   gcloud compute ssl-certificates describe app --global \
     --format="get(managed.status, managed.domainStatus)"
   ```

**File reference — `infra/iap.tf` line 70:** No code change is required here; this TODO is a process reminder. The `domain` variable is passed in via the `-var` flag shown in step 7 above.

---

## Verify

After completing all steps above and running `terraform apply`, confirm the deployment is healthy with the following commands:

```bash
# 1. Confirm Terraform state is stored remotely
terraform state list

# 2. Show all Terraform outputs (load balancer IP, service URL, etc.)
terraform output

# 3. Confirm the Cloud Run service is deployed and healthy
gcloud run services describe test-cloudrun-app \
  --region=<your-region> \
  --format="table(status.url, status.conditions[0].type, status.conditions[0].status)"

# 4. Confirm the managed SSL certificate is ACTIVE
gcloud compute ssl-certificates list --global \
  --format="table(name, managed.status)"

# 5. Send a test request through the load balancer
curl -I https://<your.domain.com>/

# 6. Check Cloud Run logs for runtime errors
gcloud run services logs read test-cloudrun-app \
  --region=<your-region> \
  --limit=50
```

All checks pass when:
- `terraform state list` returns resource names without errors
- The Cloud Run service condition is `Ready: True`
- The SSL certificate status is `ACTIVE`
- `curl` returns `HTTP/2 200` (or your application's expected status code)