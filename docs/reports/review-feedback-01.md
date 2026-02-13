# Reviewer Feedback

General feedback
You have a solid pipeline structure and a mostly correct containerized app setup. The biggest blockers to passing are:

The Docker file should contain the commands needed to install requirements and run the app using a Gunicorn server.
If you address this, this should move to a clean pass quickly

## Docker File Should Contain Correct Commands

Not yet passing ❌ — The rubric requires using python:stretch as the base image and defining the Gunicorn entrypoint exactly as: ["gunicorn", "-b", ":8080", "main:APP"], but the Dockerfile does not match the required base image and/or entrypoint format.

What to fix (simple + rubric-aligned):

Update the Dockerfile to:
Use FROM python:stretch
Use the required entrypoint:
ENTRYPOINT ["gunicorn", "-b", ":8080", "main:APP"]
Extra improvement (recommended):

Avoid using latest tags for base images to prevent future build breakages.