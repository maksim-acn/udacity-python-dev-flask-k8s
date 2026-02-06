---
title: "Deploy Your Flask App to Kubernetes Using EKS - II.d. Adding Tests to the Build"
author:
published:
created: 2026-02-06
description:
tags:
  - "clippings"
---
## II.d. Adding Tests to the Build



## Adding Tests to the Build

The final part of this project involves adding tests to your deployment. You can follow the steps below to accomplish this.

1. Add running tests as part of the build. To require the unit tests to pass before our build will deploy new code to your cluster, you will add the tests to the build stage. Remember you installed the requirements and ran the unit tests locally at the beginning of this project. You will add the same commands to the *buildspec.yml*:
	- Open *buildspec.yml*
	- In the prebuild section, add a line to install the requirements and a line to run the tests. You may need to refer to 'pip' as 'pip3' and 'python' as 'python3', as:
	```yaml
	pre_build:
	  commands:
	    - pip3 install -r requirements.txt 
	    - python -m pytest test_main.py
	```
	- Save the file
2. You can check the tests prevent a bad deployment by breaking the tests on purpose:
	- Open the *test\_main.py* file
	- Add `assert False` to any of the tests
	- Commit your code and push it to Github
	- Check that the build fails in [CodePipeline (opens in a new tab)](https://console.aws.amazon.com/codesuite/codepipeline/start?region=us-east-2)

### Concept Checklist
