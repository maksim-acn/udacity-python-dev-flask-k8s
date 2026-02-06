---
title: "Deploy Your Flask App to Kubernetes Using EKS - Prerequisites and App Overview"
author:
published:
created: 2026-02-06
description:
tags:
  - "clippings"
---
## Prerequisites and App Overview

## Prerequisites

- Docker Desktop - Installation instructions can be found [here (opens in a new tab)](https://docs.docker.com/install/).
- Git: See the download instructions [here (opens in a new tab)](https://git-scm.com/downloads).
- Code editor: You can [download and install VS code (opens in a new tab)](https://code.visualstudio.com/download) here.
- AWS Account
- Python version between 3.7 and 3.9. Check the current version using:
```bash
#  Mac/Linux/Windows 
python --version
```

You can download a specific release version from [here (opens in a new tab)](https://www.python.org/downloads/).

- Python package manager - PIP 19.x or higher. PIP is already installed in Python 3 >=3.4 downloaded from python.org. However, you can upgrade to a specific version, say 20.2.3, using the command:
```bash
#  Mac/Linux/Windows Check the current version
pip --version
# Mac/Linux
pip install --upgrade pip==20.2.3
# Windows
python -m pip install --upgrade pip==20.2.3
```
- Terminal
	- Mac/Linux users can use the default terminal.
	- Windows users can use either the GitBash terminal or WSL.
- Command line utilities:
	- AWS CLI: Installation instructions can be found [here (opens in a new tab)](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). AWS CLI should be configured using the `aws configure` command. **Important**: Do not use the *us-east-1* because the EKS cluster creation may fails in *us-east-1* mostly. Change the default region to:
	```bash
	aws configure set region us-east-2
	# Run this command to see if the AWSCLI is configured correctly. It should return the list of IAM users. 
	aws iam list-users
	```
	**Ensure to create all your resources in a single region.**
	- EKSCTL: Installation instructions can be found [here (opens in a new tab)](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html#installing-eksctl) or [here (opens in a new tab)](https://eksctl.io/introduction/#installation) to download and install `eksctl` utility.
	- KUBECTL: Installation instructions can be found [here (opens in a new tab)](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

## Initial setup

Fork the [Server and Deployment Containerization Github repo (opens in a new tab)](https://github.com/udacity/cd0157-Server-Deployment-and-Containerization) to your Github account. Locally clone your forked version to begin working on the project.

```bash
git clone https://github.com/[username]/cd0157-Server-Deployment-and-Containerization.git
cd cd0157-Server-Deployment-and-Containerization/
```

These are the files relevant for the current project:

```bash
.
├── Dockerfile
├── aws-auth-patch.yml           # TODO - A sample EKS Cluster configMap file. 
├── ci-cd-codepipeline.cfn.yml   # TODO - YAML template to create CodePipeline pipeline and CodeBuild resources
├── buildspec.yml
├── simple_jwt_api.yml
├── trust.json              # TODO - Used for creating an IAM role for Codebuild
├── iam-role-policy.json    
├── main.py                 
├── requirements.txt        
└── test_main.py            # TODO - Unit Test file
```

Most of the files needed in this project are already available to you. You will have to make changes in the following files aligned with the upcoming instructions:

1. *trust.json*: This file and *iam-role-policy.json* file will be used for creating an IAM role for Codebuild to assume while building your code and deploying to the EKS cluster.
2. *aws-auth-patch.yml*: You will create a file similar to this one after creating en EKS cluster. We have given you a sample file so that the YAML indentations will not trouble you.
3. *ci-cd-codepipeline.cfn.yml*: This is the Cloudformation template that we will use to create Codebuild, Codepipeline, and related resources like IAM roles and S3 bucket. This file is almost complete, except for you to write a few parameter values specific to you. Once the Codebuild resource is created, it will run the commands mentioned in the *buildspec.yml*.
4. *test\_main.py*: You will write unit tests in this file.

## Overview - The Endpoints of the Flask App

The Flask app that will be used for this project consists of a simple API with three endpoints:

1. `GET '/'`: This is a simple health check, which returns the response 'Healthy'.
2. `POST '/auth'`: This takes an email and password as json arguments and returns a JWT based on a custom secret.
3. `GET '/contents'`: This requires a valid JWT, and returns the decrypted contents of that token.

The app relies on a secret set as the environment variable `JWT_SECRET` to produce a JWT. The built-in Flask server is adequate for local development, but not production, so you will be using the production-ready [Gunicorn (opens in a new tab)](https://gunicorn.org/) server when deploying the app.

---