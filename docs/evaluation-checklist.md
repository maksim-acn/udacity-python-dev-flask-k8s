# Project Evaluation Checklist

Step-by-step verification checklist for the Flask JWT API Containerization project. Each phase maps to rubric criteria. For automation, see [scripts/README.md](scripts/README.md).

---

## Phase 1: Prerequisites Verification

| # | Check | Validation Command |
|---|-------|-------------------|
| 1.1 | Docker Desktop installed | `docker --version` |
| 1.2 | Python 3.7-3.9 installed | `python --version` |
| 1.3 | PIP 19.x+ installed | `pip --version` |
| 1.4 | AWS CLI configured | `aws sts get-caller-identity` |
| 1.5 | EKSCTL installed | `eksctl version` |
| 1.6 | KUBECTL installed | `kubectl version --client` |

---

## Phase 2: Local Application (Rubric: Running Locally)

| # | Check | Validation |
|---|-------|-----------|
| 2.1 | Dependencies install | `pip install -r requirements.txt` succeeds |
| 2.2 | Environment variables set | `export JWT_SECRET='myjwtsecret'` and `export LOG_LEVEL=DEBUG` |
| 2.3 | App starts | `python main.py` runs without errors |
| 2.4 | Health endpoint works | `curl http://127.0.0.1:8080/` returns `"Healthy"` |
| 2.5 | Auth endpoint works | `curl -X POST http://127.0.0.1:8080/auth -d '{"email":"test@test.com","password":"test"}' -H "Content-Type: application/json"` returns JWT |
| 2.6 | Contents endpoint works | `curl http://127.0.0.1:8080/contents -H "Authorization: Bearer <JWT>"` returns decoded payload |
| 2.7 | Unit tests pass | `python -m pytest test_main.py` |

---

## Phase 3: Containerization (Rubric: Dockerfile & Docker Image)

| # | Check | Validation |
|---|-------|-----------|
| 3.1 | Dockerfile uses correct base image | Contains `FROM public.ecr.aws/sam/build-python3.7:latest` or `python:stretch` |
| 3.2 | Dockerfile copies files to `/app` | Contains `COPY . /app` and `WORKDIR /app` |
| 3.3 | Dockerfile installs requirements | Contains `pip install -r requirements.txt` |
| 3.4 | Dockerfile uses Gunicorn entrypoint | Contains `ENTRYPOINT ["gunicorn", "-b", ":8080", "main:APP"]` |
| 3.5 | `.env_file` created | File exists with `JWT_SECRET=value` and `LOG_LEVEL=DEBUG` (no `export`) |
| 3.6 | `.env_file` in `.gitignore` | `grep ".env_file" .gitignore` returns match |
| 3.7 | Docker image builds | `docker build -t myimage .` succeeds |
| 3.8 | Container runs | `docker run --name myContainer --env-file=.env_file -p 80:8080 myimage` |
| 3.9 | Container health endpoint | `curl http://localhost:80/` returns `"Healthy"` |
| 3.10 | Container auth endpoint | POST to `http://localhost:80/auth` returns JWT |
| 3.11 | Container contents endpoint | GET `http://localhost:80/contents` with JWT returns payload |

---

## Phase 4: EKS Cluster & IAM (Rubric: CodePipeline Deployment)

| # | Check | Validation |
|---|-------|-----------|
| 4.1 | EKS cluster created | `eksctl create cluster --name simple-jwt-api --nodes=2 --version=1.22 --instance-types=t2.medium --region=eu-central-1` |
| 4.2 | Cluster nodes ready | `kubectl get nodes` shows 2 Ready nodes |
| 4.3 | `trust.json` has correct account ID | Verify `<ACCOUNT_ID>` replaced with actual AWS account ID |
| 4.4 | IAM role created | `aws iam get-role --role-name UdacityFlaskDeployCBKubectlRole` returns role |
| 4.5 | IAM policy attached | `aws iam get-role-policy --role-name UdacityFlaskDeployCBKubectlRole --policy-name eks-describe` |
| 4.6 | aws-auth ConfigMap patched | `kubectl get -n kube-system configmap/aws-auth -o yaml` shows `UdacityFlaskDeployCBKubectlRole` |

---

## Phase 5: CI/CD Pipeline (Rubric: CodePipeline & CodeBuild)

| # | Check | Validation |
|---|-------|-----------|
| 5.1 | JWT_SECRET in Parameter Store | `aws ssm get-parameter --name JWT_SECRET` returns value |
| 5.2 | `buildspec.yml` references parameter store | Contains `env: parameter-store: JWT_SECRET: JWT_SECRET` |
| 5.3 | `buildspec.yml` runs tests in pre-build | Contains `python -m pytest test_main.py` |
| 5.4 | `buildspec.yml` installs requirements | Contains `pip3 install -r requirements.txt` |
| 5.5 | `ci-cd-codepipeline.cfn.yml` defaults set | `EksClusterName`, `GitSourceRepo`, `GitHubUser`, `KubectlRoleName` have correct values |
| 5.6 | CloudFormation stack creates successfully | Stack status is `CREATE_COMPLETE` in AWS Console |
| 5.7 | Pipeline runs successfully | All stages (Source → Build → Deploy) show green |

---

## Phase 6: Deployment Verification (Rubric: API Runs from EKS)

| # | Check | Validation |
|---|-------|-----------|
| 6.1 | Service has external IP | `kubectl get services simple-jwt-api -o wide` shows EXTERNAL-IP |
| 6.2 | Health endpoint via ELB | `curl http://<EXTERNAL-IP>/` returns `"Healthy"` |
| 6.3 | Auth endpoint via ELB | POST to `http://<EXTERNAL-IP>/auth` returns JWT |
| 6.4 | Contents endpoint via ELB | GET `http://<EXTERNAL-IP>/contents` with JWT works |
| 6.5 | External IP documented | IP noted for submission |

---

## Phase 7: Test Validation (Rubric: CodeBuild Runs Tests)

| # | Check | Validation |
|---|-------|-----------|
| 7.1 | Intentional test failure | Add `assert False` to a test in `test_main.py` |
| 7.2 | Pipeline fails on bad tests | Push change, verify Build stage fails |
| 7.3 | Revert and verify recovery | Remove `assert False`, push, pipeline succeeds |

---

## Submission Checklist

| # | Item | Status |
|---|------|--------|
| S.1 | GitHub repo URL ready | [ ] |
| S.2 | External IP documented in submission notes | [ ] |
| S.3 | All endpoints accessible via external IP | [ ] |
| S.4 | Pipeline in passing state | [ ] |

---

## Post-Review Cleanup

| # | Task | Command |
|---|------|---------|
| C.1 | Delete EKS cluster | `eksctl delete cluster simple-jwt-api --region=eu-central-1` |
| C.2 | Delete JWT_SECRET parameter | `aws ssm delete-parameter --name JWT_SECRET` |
| C.3 | Delete CloudFormation stack | Via AWS Console or CLI |
