# Implementation Plan — Simple JWT API (Flask on Kubernetes)

This plan follows the learning sequence in `docs/project_description` (01→09) and is tailored to this repository’s current artifacts (Flask app, Dockerfile, CodePipeline/CodeBuild CloudFormation, EKS, Kubernetes manifest, and verification scripts).

**Project goals**

- Run the Flask JWT API locally and via Docker.
- Provision EKS and deploy the app to Kubernetes.
- Implement CI/CD so that unit tests gate deployments.
- Verify endpoints from the EKS external endpoint.
- Submit repo + external IP/hostname; clean up AWS resources after review.

**Decisions (locked in)**

- Pipeline branch: `main`.
- Image injection into Kubernetes: template substitution for `CONTAINER_IMAGE` in `simple_jwt_api.yml`.
- JWT secret source of truth: AWS SSM Parameter Store (`JWT_SECRET`), injected into the cluster at deploy time.
- Cluster approach: cost-optimized settings as described in the repo README (rather than Udacity’s canonical instance sizing).
- Default node instance type: `t3a.small` (prefer Spot where appropriate), fallback to `t3.small` if capacity is an issue in `eu-central-1`.
- AWS resource tagging: add `Project=max-genai` to any AWS resources we create (unless a project requirement explicitly prevents tagging).

---

## Phase 0 — Prerequisites and tooling

**Objective**: Ensure local tooling and AWS auth are ready.

**Do**

- Install/verify: Docker, Python 3.7–3.9, pip 19+, AWS CLI, eksctl, kubectl.
- Configure AWS auth locally so `aws sts get-caller-identity` works.
- Choose and stick to one AWS region for all resources. For this project, use `eu-central-1`.

**Verify**

- Run: `./scripts/verify-prereqs.sh`

**References**

- docs/project_description/02-prerequisites.md

---

## Phase 1 — Run the app locally (no Docker)

**Objective**: Prove the app and tests work on your machine.

**Do**

- Install Python deps from requirements.
- Set environment variables:
  - `JWT_SECRET` (required)
  - `LOG_LEVEL` (optional)
- Start server: `python main.py`
- Exercise endpoints:
  - `GET /` (health)
  - `POST /auth`
  - `GET /contents` (requires JWT)
- Run unit tests with pytest.

**Verify**

- Run: `./scripts/verify-local.sh`
- Optional strict mode (fails if app not running): `VERIFY_REQUIRE_APP=1 ./scripts/verify-local.sh`

**References**

- docs/project_description/03-app-local.md
- docs/project_description/08-tests.md

---

## Phase 2 — Containerize and verify locally

**Objective**: Build and run the containerized version and verify endpoints.

**Do**

- Ensure Dockerfile runs Gunicorn with `main:APP` on `:8080`.
- Create `.env_file` locally (gitignored) with:
  - `JWT_SECRET=...`
  - `LOG_LEVEL=...`
- Build and run the image and test endpoints through the host port mapping.

**Verify**

- Run: `./scripts/verify-docker.sh`
- To actually run the container check: `VERIFY_RUN_CONTAINER=1 ./scripts/verify-docker.sh`

**References**

- docs/project_description/04-containerizing.md

---

## Phase 3 — Store JWT secret in AWS SSM Parameter Store

**Objective**: Create the deployment-time secret source.

**Do**

- Create/update `JWT_SECRET` in SSM as `SecureString` in `eu-central-1`.
- Add tag `Project=max-genai` to the SSM parameter.

**Verify**

- `aws ssm get-parameter --name JWT_SECRET`
- Run: `VERIFY_REQUIRE_AWS=1 ./scripts/verify-cicd.sh`

**References**

- docs/project_description/05-cd.md

---

## Phase 4 — Provision EKS (cost-optimized)

**Objective**: Create a working Kubernetes cluster and confirm kubectl access.

**Do**

- Create the EKS cluster using the repo’s cost-optimized guidance in `eu-central-1`.
- Confirm kubectl context is set to the new cluster.

**Verify**

- `kubectl get nodes`
- Run: `VERIFY_REQUIRE_AWS=1 ./scripts/verify-eks.sh`

**References**

- docs/project_description/06-eks.md

---

## Phase 5 — IAM role for CodeBuild kubectl access + EKS RBAC

**Objective**: Allow the build system to authenticate to the EKS API.

**Do**

- Update `trust.json` with your AWS account ID.
- Create IAM role `UdacityFlaskDeployCBKubectlRole` using the trust policy.
- Attach the role policy that allows EKS describe + SSM read.
- Patch EKS aws-auth ConfigMap to grant this role Kubernetes permissions.
  - When creating the IAM role, add tag `Project=max-genai`.

**Verify**

- Confirm role exists: `aws iam get-role --role-name UdacityFlaskDeployCBKubectlRole`
- Confirm policy attached: `aws iam get-role-policy --role-name UdacityFlaskDeployCBKubectlRole --policy-name eks-describe`
- Confirm aws-auth includes the role: `kubectl get -n kube-system configmap/aws-auth -o yaml`

**References**

- docs/project_description/07-k8s.md

---

## Phase 6 — CI/CD pipeline via CloudFormation (CodePipeline + CodeBuild)

**Objective**: Automate build/test/deploy from the `main` branch.

**Do**

- Configure CloudFormation parameters in the pipeline template:
  - EKS cluster name (your actual cluster name)
  - GitHub user + repo
  - Branch: `main`
  - Kubectl role name: `UdacityFlaskDeployCBKubectlRole`
- Create/update the stack.
  - Pass stack tags (at minimum `Project=max-genai`) so the stack and supported resources are tagged consistently.

**Verify**

- Pipeline stages show green through deploy.
- Run: `./scripts/verify-cicd.sh` (and `VERIFY_REQUIRE_AWS=1` if you want AWS checks enforced).

**References**

- docs/project_description/05-cd.md

---

## Phase 7 — CodeBuild buildspec: tests gate deployments + deploy wiring

**Objective**: Ensure tests run before deployment and EKS deploy uses correct image + secret injection.

**Do**

- Ensure buildspec includes:
  - install deps
  - `python -m pytest test_main.py`
  - SSM mapping for `JWT_SECRET`
- Implement deployment wiring in the build:
  1) Template substitution: replace `CONTAINER_IMAGE` in `simple_jwt_api.yml` with the built ECR image URI.
  2) Secret injection: create/update the Kubernetes Secret that the Deployment references using the SSM-provided `$JWT_SECRET`.
  3) Apply Kubernetes manifests.
  4) Wait for rollout.

**Verify**

- `kubectl rollout status deployment/simple-jwt-api`
- `kubectl get pods`
- `kubectl get svc`

**References**

- docs/project_description/07-k8s.md
- docs/project_description/08-tests.md

---

## Phase 8 — End-to-end verification from EKS external endpoint

**Objective**: Validate the running service is reachable externally.

**Do**

- Obtain the external endpoint from the LoadBalancer service.
- Curl the three endpoints from outside the cluster.

**Verify**

- Run: `./scripts/verify-deployment.sh`

**References**

- docs/project_description/07-k8s.md

---

## Phase 9 — Prove test gating behavior

**Objective**: Demonstrate failing tests prevent deployments.

**Do**

- Break one test intentionally, push to `main`, confirm pipeline fails before deploy.
- Revert the break, push, confirm pipeline succeeds and deploys.

**References**

- docs/project_description/08-tests.md

---

## Phase 10 — Submission and cleanup

**Objective**: Submit the required proof and avoid ongoing AWS costs.

**Do**

- Submission notes must include the EKS service external IP/hostname.
- After review:
  - delete the EKS cluster
  - delete pipeline stack/resources as appropriate
  - delete the `JWT_SECRET` SSM parameter if it’s project-only

**References**

- docs/project_description/09-submission.md

---

## Optional: Use the automation suite as a “definition of done”

- Run everything: `./scripts/verify-all.sh`
- See usage and toggles: `scripts/README.md`
