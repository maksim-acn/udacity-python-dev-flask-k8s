# Scripts

Automation helpers to verify project readiness and deployments.

## Quick Start

```bash
chmod +x *.sh
./verify-all.sh
```

## Individual Checks

```bash
./verify-prereqs.sh
./verify-local.sh
./verify-docker.sh
./verify-cicd.sh
./verify-eks.sh
./verify-deployment.sh
```

## Environment Variables

- `APP_URL` - local app URL for endpoint checks (default: http://127.0.0.1:8080)
- `VERIFY_SKIP_INSTALL=1` - skip dependency install in local check
- `VERIFY_SKIP_TESTS=1` - skip pytest in local check
- `VERIFY_REQUIRE_APP=1` - fail if local app is not reachable
- `VERIFY_SKIP_DOCKER_BUILD=1` - skip docker build
- `VERIFY_RUN_CONTAINER=1` - run container check on port 18080
- `VERIFY_REQUIRE_AWS=1` - require AWS access for CI/CD and EKS checks
- `IMAGE_TAG` - override docker image tag
- `CONTAINER_NAME` - override docker container name
- `CLUSTER_NAME` - override EKS cluster name
- `AWS_REGION` - override AWS region for EKS (default: eu-central-1)
- `SERVICE_NAME` - override Kubernetes service name
- `K8S_NAMESPACE` - override Kubernetes namespace

## Exit Codes

Scripts exit with non-zero status if any required check fails. Warnings do not fail the run.
