in this post i will show you how to deploy drone on kubernetes and how to write a simple CI file that builds backend and frontend docker images and pushes them to AWS ECR.

1. Deploy:
 I will use helm2 chart to deploy drone, with the values i added on my own:
 
 

create the `.drone.yml` file:

```yaml
kind: pipeline
name: default

steps:
- name: publish_backend 
  image: plugins/ecr
  settings:
    access_key:
      from_secret: DRONE_AWS_ACCESS_KEY
    secret_key:
      from_secret: DRONE_AWS_SECRET_KEY
    registry: 841009486958.dkr.ecr.eu-west-1.amazonaws.com
    repo: $${DRONE_REPO_NAME}_backend_drone
    tags:
      - latest
      - $${DRONE_COMMIT_BRANCH}-$${DRONE_COMMIT_SHA}
    dockerfile: backend/Dockerfile.prod
    context: backend
    build_args:
      - COMMIT_HASH=$${DRONE_COMMIT_SHA}
      - BUILD_ID=$${BUILD_NUMBER}
      - BUILD_DATE=$${DRONE_BUILD_STARTED}

- name: publish_frontend 
  image: plugins/ecr
  settings:
    access_key:
      from_secret: DRONE_AWS_ACCESS_KEY
    secret_key:
      from_secret: DRONE_AWS_SECRET_KEY
    registry: 841009486958.dkr.ecr.eu-west-1.amazonaws.com
    repo: $${DRONE_REPO_NAME}_frontend_drone
    tags:
      - latest
      - $${DRONE_COMMIT_BRANCH}-$${DRONE_COMMIT_SHA}
    dockerfile: frontend/Dockerfile.prod
    context: frontend
    build_args:
      - VERSION_COMMIT_INFO=$${DRONE_COMMIT_SHA}
      - NPM_PASS=$${NPM_TOKEN}
```