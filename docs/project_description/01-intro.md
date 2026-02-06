---
title: "Deploy Your Flask App to Kubernetes Using EKS - Project Overview"
author:
published:
created: 2026-02-06
description:
tags:
  - "clippings"
---
## Project Overview



## Containerize and Deploy using Continuous Delivery

### Project Overview

The prime objective of this project is to create a CI/CD pipeline. You will associate the pipeline's one end to your Github repository, and connect the other end to the EKS cluster. You will create this CI/CD pipeline programmatically using the code (Cloudformation template file) that we will provide to you.

The subsequent pages of this lesson will guide you to create an and EKS cluster using a single command, AWS CodeBuild and CodePipeline programmatically using a CloudFormation template available to you.


Overarching diagram of the final deployed application

The diagram above shows the various stages of the Pipeline. The actions marked as 1, 2, 3, and 4 signify the following:

1. **Code check-in** - The application code for the Flask app is hosted on Github. Multiple contributors can contribute to the repository collaboratively.
2. **Trigger Build** - As soon as a *commit* happens in the Github repository, it will trigger the CodeBuild. This step requires connecting your Github account to the AWS CodeBuild service using a GitHub access token. Codebuld will build a new image for your application, and push it to a container registry.
3. **Automatic Deployment** - The CodePipeline service will automatically deploy the application image to your Kubernetes cluster.
4. **Service** - Kubernetes cluster will start serving the application endpoints.

### Project ToDos

The current project lesson has two major parts, and each part has incremental steps to follow:

1. **Run the App locally**
	- First, you will get familiar with the Flask app by running it locally
	- Next, you will containerize the same app locally so that you know the necessary environment for your (containerized) app to run. This step will make you familiar with writing a Dockerfile, building an image, and how to run a container.
2. **Run the App at scale on AWS Cloud**  
	This part aims to create a CI/CD pipeline (using AWS Codebuild and CodePipeline). The steps you will follow are:
- **Create EKS Cluster and an IAM role**  
	You will start with creating an EKS cluster in your preferred region, using AWS CLI. Then, you will create an IAM role that the Codebuild will assume to access your k8s/EKS cluster. This IAM role will have the necessary access permissions, and you will also have to add this role to the k8s cluster's configMap.
- **Create Github access token**  
	Next, you will generate an access-token from your Github account. You will share this token with the AWS Codebuild service (programmatically) so that it can build and test your code.
- **Create Codebuild and CodePipeline resources using CloudFormation template**  
	Now, you will create the necessary AWS resources using a script, Cloudformation template (.yaml) file, available to you. These resources collectively are called **stack**. It will automatically create the Codebuild and Codepipeline instances for you.
- **Build and deploy**  
	Finally, you will trigger the manual **build** (on Codebuild web console) to deploy and run the app on the K8s cluster. Besides, any GitHub check-ins will also trigger the pipeline.

---
