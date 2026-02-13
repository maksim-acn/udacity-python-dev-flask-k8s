# Simple JWT API - Flask on Kubernetes

Udacity Project: Deploy Your Flask App to Kubernetes Using EKS

A containerized Flask API with JWT authentication, deployed to AWS EKS via CI/CD pipeline.

**🚀 Live Demo:** [http://a961d15c30a36483d805f6a1105ccd4a-1671082022.eu-north-1.elb.amazonaws.com](http://a961d15c30a36483d805f6a1105ccd4a-1671082022.eu-north-1.elb.amazonaws.com)

## Endpoints

| Method | Path       | Description                          |
|--------|------------|--------------------------------------|
| GET    | `/`        | Health check - returns "Healthy"     |
| POST   | `/auth`    | Generate JWT token                   |
| GET    | `/contents`| Decode JWT and return payload        |

## Quick Start - Local Development

### Prerequisites
- Python 3.9+
- `uv` (Fast Python package installer and venv manager)
- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- AWS CLI v2
- `eksctl`
- `kubectl`

### Status
Current build and verification status: [Validation Report](docs/reports/validation_report.md)

### 1. Run without Docker (using uv)

```bash
# Create virtual environment with Python 3.9
uv venv --python 3.9

# Activate virtual environment
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
uv pip install -r requirements.txt

# Run tests
python -m pytest test_main.py -v

# Set environment variable and run
export JWT_SECRET=your-secret-key
python main.py
```

### 2. Run with Docker

```bash
# Build the image
docker build -t simple-jwt-api .

# Run the container
docker run -p 8080:8080 --env-file .env_file simple-jwt-api
```

### 3. Test the API

```bash
# Health check
curl http://localhost:8080/

# Get JWT token
TOKEN=$(curl -s -X POST http://localhost:8080/auth \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass"}' | jq -r '.token')

# Verify token
curl http://localhost:8080/contents \
  -H "Authorization: Bearer $TOKEN"
```

## Verification Scripts

Automated checks are available in the `scripts` directory.

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run the full verification suite
./scripts/verify-all.sh

# Or run individual phases
./scripts/verify-prereqs.sh
./scripts/verify-local.sh
./scripts/verify-docker.sh
./scripts/verify-cicd.sh
./scripts/verify-eks.sh
./scripts/verify-deployment.sh
```

Common controls:

- `VERIFY_SKIP_TESTS=1` to skip pytest
- `VERIFY_SKIP_DOCKER_BUILD=1` to skip docker build
- `VERIFY_RUN_CONTAINER=1` to run the container check
- `VERIFY_REQUIRE_AWS=1` to require AWS access
- `APP_URL=http://127.0.0.1:8080` to override local URL

## AWS Deployment (Cost-Optimized)

### Estimated Costs
| Resource             | Hourly Cost |
|----------------------|-------------|
| EKS Control Plane    | $0.10       |
| 2x t3a.small (Spot)  | ~$0.02      |
| NAT Gateway          | $0.045      |
| **Total**            | **~$0.17/hr** |

### 1. Create EKS Cluster (with Spot Instances)

```bash
eksctl create cluster \
  --name simple-jwt-api \
  --region eu-central-1 \
  --version 1.22 \
  --nodegroup-name spot-nodes \
  --node-type t3a.small \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 2 \
  --managed \
  --spot \
  --tags Project=max-genai
```

### 2. Store JWT Secret in Parameter Store

```bash
aws ssm put-parameter \
  --name JWT_SECRET \
  --value "your-production-secret" \
  --type SecureString \
  --region eu-central-1

# Tag the parameter
aws ssm add-tags-to-resource \
  --resource-type Parameter \
  --resource-id JWT_SECRET \
  --tags Key=Project,Value=max-genai \
  --region eu-central-1
```

### 3. Create IAM Role for CodeBuild

```bash
# Create trust policy
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create role
aws iam create-role \
  --role-name UdacityFlaskDeployCBKubectlRole \
  --assume-role-policy-document file://trust-policy.json

# Attach EKS describe policy
aws iam put-role-policy \
  --role-name UdacityFlaskDeployCBKubectlRole \
  --policy-name eks-describe \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["eks:Describe*", "ssm:GetParameters"],
        "Resource": "*"
      }
    ]
  }'
```

### 4. Update EKS aws-auth ConfigMap

```bash
kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth.yaml
# Add the role to mapRoles section, then apply
kubectl apply -f aws-auth.yaml
```

### 5. Deploy CloudFormation Stack

```bash
aws cloudformation create-stack \
  --stack-name simple-jwt-api-pipeline \
  --template-body file://ci-cd-codepipeline.cfn.yml \
  --parameters \
    ParameterKey=GitHubUser,ParameterValue=YOUR_GITHUB_USERNAME \
    ParameterKey=GitHubToken,ParameterValue=YOUR_GITHUB_TOKEN \
  --capabilities CAPABILITY_NAMED_IAM \
  --tags Project=max-genai \
  --region eu-central-1
```

### 6. Get External IP

```bash
kubectl get svc simple-jwt-api
```

## Cleanup (IMPORTANT - Save Money!)

```bash
# Delete EKS cluster
eksctl delete cluster simple-jwt-api --region=us-east-2
eksctl delete cluster simple-jwt-api --region=eu-central-1

# Delete CloudFormation stack
aws cloudformation delete-stack \
  --stack-name simple-jwt-api-pipeline \
  --region eu-central-1

# Delete ECR repository
aws ecr delete-repository \
  --repository-name simple-jwt-api \
  --force \
  --region eu-central-1
```

## Project Structure

```
.
├── main.py                    # Flask application
├── test_main.py              # Unit tests
├── requirements.txt          # Python dependencies
├── Dockerfile                # Container definition
├── .env_file                 # Local environment variables (gitignored)
├── buildspec.yml             # AWS CodeBuild specification
├── simple_jwt_api.yml        # Kubernetes deployment manifest
├── ci-cd-codepipeline.cfn.yml # CloudFormation template
└── README.md                 # This file
```

## Environment Variables

| Variable    | Description               | Required |
|-------------|---------------------------|----------|
| JWT_SECRET  | Secret key for JWT signing | Yes      |
| LOG_LEVEL   | Logging level (DEBUG/INFO) | No       |
