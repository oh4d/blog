DR site dlayed sync

In my company we managed to create a site for DR - disater recovery, in case something goes wrong with the main site.

Now, there are a few methodoliges about how to syncronize the codebase.
We went for the delayed one - I wanted the DR site to synchronize itself every night at 00:00, and in this post I will cover the way to implement it both in CircleCI and GitLabCI.

CircleCI scheduled workflow - triggered by a crontab. the scheduled workflow finds out the production commit, and tags it as prod-stable-{ID}. once the tag is being pushed back to the repo, it will trigger the tag workflow, which will push a new docker tag to the prod registry.

Since we were using FluxCD for deployment automation, once that tag is pushed, it will automatically be depliyed to the DR site.

Implementation on CircleCI:

```yaml
worflows:
	version: 2
	  nightly:
	    triggers:
	      - schedule:
	          cron: "0 0 * * *"
	          filters:
	            branches:
	              only: /.*/
	    jobs:
	    - tag_production_commit
	    
jobs:
    tag_production_commit:
        docker:
        - image: circleci/node
        steps:
        - checkout
        - run: echo "export STABLE_COMMIT=$(curl -s https://prd.my-site.com/api/version | jq -r '.commit')" >> $BASH_ENV
        - run: echo "export ORIGIN=https://y2devops:${Y2DEVOPS_TOKEN}@github.com/${YOUR_ORG}/${CIRCLE_PROJECT_REPONAME}.git" >> $BASH_ENV
        - run: git tag -a "stable-${STABLE_COMMIT}" ${STABLE_COMMIT} -m "productiob $(date)"
        - run: git push $ORIGIN stable-${STABLE_COMMIT}
```

Now, GitLabCI requires a little more effort - go ahead and create a scheduked run:
```yaml
tag_production:
  stage: tag
  only:
    - schedules
  script:
    - apk add curl jq git 
    - git config --global user.email "<>"
    - git config --global user.name "nightly_tag"
    - export STABLE_COMMIT=$(curl -s https://prd.my-site.com/api/version | jq -r '.commit')
    - git tag -a "prod-stable-${CI_PIPELINE_ID}" ${STABLE_COMMIT} -m "production $(date) from commit ${STABLE_COMMIT}"
    - git push https://y2nightBuild:${NIGHT_BUILD_TOKEN}@gitlab.yad2.co.il/develeap/yad2site.git prod-stable-${CI_PIPELINE_ID}
    - |
      curl --silent -X POST -k -H "Content-type: application/json" --data "{\"text\":\"syncing DR prod-site from production\ncommit ${STABLE_COMMIT} :first_quarter_moon_with_face:\",\"attachments\": [   {  \"fallback\": \"go to build ${CI_PIPELINE_URL}\",  \"actions\": [ {  \"type\": \"button\", \"text\": \"go to build\", \"url\": \"${CI_PIPELINE_URL}\"  }  ] }]}" ${SLACK_TAG_URL}
  allow_failure: true
```

remember to create a scheduled run on the dashbord, otherwise it would nerver run.

Here is the complete CircleCI workflow for pushing a tag to production:

```yaml
version: 2.1
orbs:
    aws-ecr: circleci/aws-ecr@6.7.0
    promote-to-prod: datacamp/ecr@0.1.1
    docker: circleci/docker@0.5.20

master_only: &master_only
    filters:
        branches:
            only: master

tag_only: &tag_only
    filters:
        tags:
            only: /.*/
        branches:
            ignore: /.*/

ecr_dev_params: &ecr_dev_params
        account-url: DEV_AWS_ECR_ACCOUNT_URL
        aws-access-key-id: DEV_ACCESS_KEY_ID
        aws-secret-access-key: DEV_SECRET_ACCESS_KEY
        create-repo: true
        dockerfile: Dockerfile.prod
        region: AWS_DEFAULT_REGION
        tag: '${CIRCLE_BRANCH}${CIRCLE_TAG}-${CIRCLE_SHA1}'

promote_to_prod_params: &promote_to_prod_params
    from-aws-access-key-id: ${DEV_ACCESS_KEY_ID}
    from-aws-secret-access-key: ${DEV_SECRET_ACCESS_KEY}
    to-aws-access-key-id: ${PROD_ACCESS_KEY_ID}
    to-aws-secret-access-key: ${PROD_SECRET_ACCESS_KEY}
    region: ${AWS_DEFAULT_REGION}
    from-account-url: ${DEV_AWS_ECR_ACCOUNT_URL}
    to-account-url: ${PROD_AWS_ECR_ACCOUNT_URL}
    tag: ${CIRCLE_TAG}-${CIRCLE_SHA1}
    to-tag: '${CIRCLE_TAG}-${CIRCLE_SHA1}'

backend_params: &backend_params
    path: /home/circleci/project/backend
    extra-build-args: --build-arg COMMIT_HASH=${CIRCLE_SHA1} --build-arg BUILD_ID=${CIRCLE_WORKFLOW_ID} --build-arg BUILD_DATE="$(date)"
    repo: '${CIRCLE_PROJECT_REPONAME}_backend'

web-client_params: &web-client_params
    path: /home/circleci/project/web-client
    extra-build-args: --build-arg VERSION_COMMIT_INFO=${CIRCLE_SHA1} --build-arg NPM_PASS=${NPM_LOGIN_TOKEN}
    repo: '${CIRCLE_PROJECT_REPONAME}_web-client'

workflows:
  version: 2
  on_push:
    jobs:
    - unit_tests_web-client:
        <<: *master_only
    - coverage_web-client:
        <<: *master_only
    - unit_tests_backend:
        <<: *master_only
    - docker/publish:
        name: run_unittests
        <<: *master_only
        deploy: false
        dockerfile: Dockerfile.unittests
        image: ${CIRCLE_PROJECT_REPONAME}
    - aws-ecr/build-and-push-image:
        name: build_backend
        <<: *master_only
        <<: *ecr_dev_params
        <<: *backend_params
    - aws-ecr/build-and-push-image:
        name: build_web-client
        <<: *master_only
        <<: *ecr_dev_params
        <<: *web-client_params
  on_release:
   jobs:
    - aws-ecr/build-and-push-image:
        name: build_backend
        <<: *tag_only
        <<: *ecr_dev_params
        <<: *backend_params
    - aws-ecr/build-and-push-image:
        name: build_web-client
        <<: *tag_only
        <<: *ecr_dev_params
        <<: *web-client_params
    -  promote-to-prod/pull_push_to_account:
        name: promote_backend  
        <<: *tag_only
        <<: *promote_to_prod_params
        repo: '${CIRCLE_PROJECT_REPONAME}_backend'
        requires:
            - build_backend
    -  promote-to-prod/pull_push_to_account:
        name: promote_web-client 
        <<: *tag_only
        <<: *promote_to_prod_params
        repo: '${CIRCLE_PROJECT_REPONAME}_web-client'
        requires:
            - build_web-client
   
executors:
  node:
    docker:
      - image: circleci/node
    working_directory: web-client

  php:
    docker:
      - image: epcallan/php7-testing-phpunit:7.1-phpunit5
    working_directory: backend/unit_tests_backend/Unit

prepare_web-client: &prepare_web-client
    - run: echo $'@axel-springer-kugawana:registry=https://npm.pkg.github.com/\n//npm.pkg.github.com/:_authToken=${NPM_LOGIN_TOKEN}' >> ~/.npmrc
    - run: cat ~/.npmrc
    - run: yarn install

jobs:
    unit_tests_web-client:
        executor: node
        steps:
        - checkout
        - <<: *prepare_web-client
        - run: cd tests
        - run: ./run_tests.sh runTests

    coverage_web-client:
        executor: node
        steps:
        - checkout
        - <<: *prepare_web-client
        - run: yarn_coverage

    unit_tests_backend:
        executor: php
        steps:
        - checkout
        - run: phpunit --coverage-text --colors=never


```