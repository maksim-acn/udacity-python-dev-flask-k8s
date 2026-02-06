---
title: "Deploy Your Flask App to Kubernetes Using EKS - II.b. Create an EKS Cluster and IAM Role"
author:
published:
created: 2026-02-06
description:
tags:
  - "clippings"
---
## II.b. Create an EKS Cluster and IAM Role


## Prerequisite

You must have the following:

1. AWS CLI installed and configured using the `aws configure` command.
2. The EKSCTL and KUBECTL command-line utilities installed in your system. Check and note down the KUBECTL version, using:
```bash
kubectl version
```

> **Note** - You must use a kubectl version within one minor version difference of your Amazon EKS cluster control plane. For example, a 1.21 kubectl client works with Kubernetes 1.20, 1.21, and 1.22 clusters.

1. You current working directory must be:
```bash
cd cd0157-Server-Deployment-and-Containerization
```

## 1\. Create an EKS (Kubernetes) Cluster

1. **Create** - Create an EKS cluster named “simple-jwt-api” in a region of your choice:
```bash
eksctl create cluster --name simple-jwt-api --nodes=2 --version=1.22 --instance-types=t2.medium --region=us-east-2
```

> **Known Issue** - If your default region is `us-east-1`, then the cluster creation may fail.

The command above will take a few minutes to execute, and create the following resources:

- EKS cluster
- A nodegroup containing two nodes.

You can view the cluster in the EKS cluster dashboard. If you don’t see any progress, be sure that you are viewing clusters in the same region that they are being created.

![Use a consistent `kubectl` version in your EKS Cluster, local machine, and later in the Codebuild's buildspec.yml file.](https://video.udacity-data.com/topher/2022/May/627cba32_screenshot-2022-05-11-at-6.13.41-pm/screenshot-2022-05-11-at-6.13.41-pm.jpeg)

Use a consistent `kubectl` version in your EKS Cluster, local machine, and later in the Codebuild's buildspec.yml file.

1. **Verify** - After creating the cluster, check the health of your clusters nodes:
```bash
kubectl get nodes
```

![Check your cluster stack and nodegroup stack in the CloudFormation web console](https://video.udacity-data.com/topher/2022/May/627b78ac_screenshot-2022-05-11-at-2.19.24-pm/screenshot-2022-05-11-at-2.19.24-pm.jpeg)

Check your cluster stack and nodegroup stack in the CloudFormation web console

1. **Delete when the project is over**  
	Remember, in case you wish to delete the cluster, you can do it using eksctl:
```bash
eksctl delete cluster simple-jwt-api  --region=us-east-2
```

**This deletion step is crucial after you receive your project feedback.**

## 2\. Create an IAM Role for CodeBuild

You will need an **IAM role that the CodeBuild will assume to access your EKS cluster**. In the previous lesson, you have already created such an IAM role with a custom trust-relationship and a policy. In case you have deleted that role, you can follow the steps below to quickly set up an IAM role. Otherwise, you can ignore the current step.

1. Get your AWS account id::
```bash
aws sts get-caller-identity --query Account --output text
# Returns the AWS account id similar to 
# 519002666132
```
1. Update the [trust.json (opens in a new tab)](https://github.com/udacity/cd0157-Server-Deployment-and-Containerization/blob/master/trust.json) file with your AWS account id.
```json
{
"Version": "2012-10-17",
"Statement": [
    {
        "Effect": "Allow",
        "Principal": {
            "AWS": "arn:aws:iam::<ACCOUNT_ID>:root"
        },
        "Action": "sts:AssumeRole"
    }
]
}
```

**Replace the <ACCOUNT\_ID> with your actual AWS account ID.**

1. Create a role, 'UdacityFlaskDeployCBKubectlRole', using the *trust.json* trust relationship:
```bash
aws iam create-role --role-name UdacityFlaskDeployCBKubectlRole --assume-role-policy-document file://trust.json --output text --query 'Role.Arn'
# Returns something similar to 
# arn:aws:iam::519002666132:role/UdacityFlaskDeployCBKubectlRole
```
1. Policy is also a JSON file where we will define the set of permissible actions that the Codebuild can perform.  
	We have given you a policy file, [iam-role-policy.json (opens in a new tab)](https://github.com/udacity/cd0157_Final_Pipeline/blob/main/iam-role-policy.json), containing the following permissible actions: "eks:Describe\*" and "ssm:GetParameters".
```json
{
 "Version": "2012-10-17",
 "Statement": [
     {
         "Effect": "Allow",
         "Action": [
             "eks:Describe*",
                "ssm:GetParameters"
         ],
         "Resource": "*"
     }
 ]
}
```
1. Attach the *iam-role-policy.json* policy to the 'UdacityFlaskDeployCBKubectlRole' as:
```bash
aws iam put-role-policy --role-name UdacityFlaskDeployCBKubectlRole --policy-name eks-describe --policy-document file://iam-role-policy.json
```

![Screenshot showing the newly created role in the IAM service](https://video.udacity-data.com/topher/2022/May/627b696d_screenshot-2022-05-11-at-1.14.31-pm/screenshot-2022-05-11-at-1.14.31-pm.jpeg)

Verify the newly created role in the IAM service

## 3\. Authorize the CodeBuild using EKS RBAC

> You will have to repeat this step every time you create a new EKS cluster.

For the CodeBuild too administer the cluster, you will have to add an entry of this new role into the 'aws-auth ConfigMap'. The [aws-auth ConfigMap (opens in a new tab)](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html) is used to grant role-based access control to your cluster.

1. **Fetch** - Get the current configmap and save it to a file:
```bash
# Mac/Linux - The file will be created at \`/System/Volumes/Data/private/tmp/aws-auth-patch.yml\` path
kubectl get -n kube-system configmap/aws-auth -o yaml > /tmp/aws-auth-patch.yml
# Windows - The file will be created in the current working directory
kubectl get -n kube-system configmap/aws-auth -o yaml > aws-auth-patch.yml
```
1. **Edit** - Open the *aws-auth-patch.yml* file using any editor, such as VS code editor:
```bash
# Mac/Linux
code /System/Volumes/Data/private/tmp/aws-auth-patch.yml
# Windows
code aws-auth-patch.yml
```

Add the following group in the **data → mapRoles** section of this file. YAML is indentation-sensitive, therefore refer to the snapshot below for a correct indentation:

```yml
- groups:
       - system:masters
     rolearn: arn:aws:iam::<ACCOUNT_ID>:role/UdacityFlaskDeployCBKubectlRole
     username: build
```

Don't forget to replace the `<ACCOUNT_ID>` with your AWS account Id. Do not copy-paste the code snippet from above. Instead, look at this sample [aws-auth-patch.yml (opens in a new tab)](https://github.com/udacity/cd0157-Server-Deployment-and-Containerization/blob/master/aws-auth-patch.yml) file and the snapshot below to stay careful with the indentations.

![Screenshot of the file aws-auth-patch.yml in the editor, with the mapRoles section highlighted in yellow. - groups is indented more than mapRoles, and - system:masters is indented one more level.]

File **aws-auth-patch.yml** in the editor. Notice the indentation of the highlighted part.

1. **Update** - Update your cluster's configmap:
```bash
# Mac/Linux
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat /tmp/aws-auth-patch.yml)"
# Windows
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat aws-auth-patch.yml)"
```

The command above must show you `configmap/aws-auth patched` as a response.

1. **Troubleshoot** - In case of the following error, re-run the above three steps beginning from the `kubectl get` command.

> Error from server (Conflict): Operation cannot be fulfilled on configmaps "aws-auth": the object has been modified; please apply your changes to the latest version and try again

1. Check the health of your clusters nodes:
```bash
kubectl get nodes
```

![Get the cluster node status]

Get the cluster node status

## Checklist
