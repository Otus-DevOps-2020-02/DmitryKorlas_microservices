# DmitryKorlas_microservices
DmitryKorlas microservices repository

# ChatOps setup
Create the new slack channel, say 'baz_channel_name'
Follow https://slack.com/intl/en-ru/help/articles/232289568-GitHub-for-Slack to connect it to github
In your channel 'baz_channel_name' type this command:
```shell script
/github subscribe Otus-DevOps-2020-02/<GITHUB_USER>_infra commits:all
```
Github can request the authorization for permissions to read from repo.

That's all. The next section is about using slack notification about travis build results:
Create `.travis.yml` with such content:
```
dist: trusty
sudo: required
language: bash
before_install:
- curl https://raw.githubusercontent.com/express42/otus-homeworks/2020-02/run.sh | bash
```
visit [configuring-slack-notifications](https://docs.travis-ci.com/user/notifications/#configuring-slack-notifications) to install travis to slack integration.
Then, run it from toe repository root
```shell script
gem install travis
travis login --com
travis encrypt "devops-team-otus:<key_from_travis>#<baz_channel_name>" --add notifications.slack.rooms --com
```
it will generate an encrypted token in your `.travis.yml` file which could be safety commited into the repo.
So, commit it.
Then, visit https://travis-ci.com/github/Otus-DevOps-2020-02/DmitryKorlas_microservices to see build info.


# Homework 15: Docker containers

## Docker basic commands
```shell script
# docker daemon status info
docker info

# docker check
docker run hello-world

# displays the list of running containers
docker ps

# displays the list of all containers
docker ps -a

# displays the list of saved images
docker images

# create and run a container from the image
docker run -it ubuntu:16.04 /bin/bash

# formatted info about containers
docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.CreatedAt}}\t{{.Names}}"

# start container
docker start <container_id>

# attach to container
docker attach <container_id>
```

docker run = docker create + docker start + docker attach

Docker run - flags:
**-i** - run container in foreground mode (docker attach)
```shell script
docker run -it ubuntu:16.04 bash
```


```shell script
# see logs
docker logs <container_id|container_name> -f

# see fs changes
docker diff <container_id|container_name>
```

**-d** run container in background mode (as daemon)
**-t** create TTY
```shell script
docker run -dt nginx:latest
```

```shell script
# run new process inside container (attach to bash)
docker exec -it <container_id|container_name> bash
```

```shell script
# stop docker container
docker ps -q
0c68e1616a66

# using SIGTERM
docker stop 0c68e1616a66

# using SIGKILL
docker kill 0c68e1616a66

# one-liner
docker kill $(docker ps -q)
```

```shell script
# see space usage
docker system df
```

```shell script
# remove stopped container
docker rm <container_id>

# remove running container
docker rm <container_id> -f

# remove docker image by id/name
docker rmi <image_id>

# remove all containers
docker rm $(docker ps -a -q)

# remove all images
docker rmi $(docker images -q)
```

## Docker machine
```
# is not a part of docker anymore, it have to be installed separatelly (at least on OSX)
brew install docker-machine
```

```shell script
# display a list of machines
docker-machine ls

# create new host
docker-machine create <machine-name>

# switch to another machine
# important! after this command, all docker commands will be invoked on remote docker host <machine-name>
eval $(docker-machine env <machine-name>)

# switch back to local docker
eval $(docker-machine env --unset)

# remove machine
docker-machine rm <machine-name>
```

```shell script
export GOOGLE_PROJECT=<GCLOUD_PROJECT_ID>
docker-machine create --driver google \
 --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
 --google-machine-type n1-standard-1 \
 --google-zone europe-west1-b \
 docker-host
```

optionally, we able to login into the machine via ssh
```shell script
docker-machine ssh docker-host
pwd
/home/docker-user
```

Make the new image and run the container
```shell script
# create docker image - see dot (.) is required - it define a path to the docker context
# "-t" creates a tag
docker build -t reddit:latest .

# run container
docker run --name reddit -d --network=host reddit:latest

# see result
docker-machine ls
NAME          ACTIVE   DRIVER   STATE     URL                       SWARM   DOCKER      ERRORS
docker-host   *        google   Running   tcp://34.76.235.37:2376           v19.03.11
```

now, visit the page http://34.76.235.37:9292 - it will not be accessible because of firewall disallow it.
Lets reconfigure the firewall rules:
```shell script
gcloud compute firewall-rules create reddit-app \
 --allow tcp:9292 \
 --target-tags=docker-machine \
 --description="Allow PUMA connections" \
 --direction=INGRESS
```

now, visit the page http://34.76.235.37:9292 again it should be accessible.

Push it into https://dockerhub.com
```shell script
# login into dockerhub
docker login

# push
docker tag reddit:latest <your-login>/otus-reddit:1.0
docker push <your-login>/otus-reddit:1.0
```

then, check it in another terminal
```shell script
docker run --name reddit -d -p 9292:9292 <your-login>/otus-reddit:1.0
```

## The task *
> Describe Container vs image difference
>
Docker image is readonly it could use another image (extend) as a base. Image contains the app dependencies and libraries. Docker container has read+write layer and run docker image in runtime virtual environment, so container depends on image. Container provides the final phase of virtualization.

## The task **
> Automate container running
> - create an image with docker inside using packer
> - create terraform environment using dynamic inventory. Amount of VM's should be configurable by the parameter.
> - use ansible playbooks
> - run container from this lecture <your-login>/otus-reddit:1.0
>
How to use:
prepare `packer/variables.json` and `terraform/terraform.tfvars`
activate service-account in gcloud console. Follow instructions [creating-managing-service-account-keys](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#iam-service-account-keys-create-gcloud)
```shell script
cd REPO/docker-monolyth/infra

# create an image in GCP
./build_packer_image.sh

# create vm instances
cd REPO/docker-monolyth/infra/terraform
terraform init
terraform plan

# check dynamic inventory works
cd REPO/docker-monolyth/infra/ansible
ansible-inventory --graph
ansible all -m ping

# run monolith container
cd REPO/docker-monolyth/infra/ansible
ansible-playbook ./playbooks/run_monolith_container.yml
```

## Helpful links
- https://docs.travis-ci.com/user/notifications/#configuring-slack-notifications
- https://docs.docker.com/engine/reference/commandline
- https://phoenixnap.com/kb/docker-image-vs-container
- https://ru.wikipedia.org/wiki/Сигнал_(Unix)
- https://github.com/jpetazzo/dind
- https://docs.docker.com/engine/security/userns-remap/
- https://docs.docker.com/engine/reference/run/#example-run-htop-inside-a-container
- https://github.com/bcicen/ctop
- https://www.rechberger.io/tutorial-install-docker-using-ansible-on-a-remote-server/


# Homework 16: Docker images and microservices

```shell script
# switch docker env to the docker host (created in previouse homework)
eval $(docker-machine env docker-host)

# download the latest mongo image
docker pull mongo:latest

# build images
# dmitrykorlas is <your-dockerhub-login>
docker build -t dmitrykorlas/post:1.0 ./post-py
docker build -t dmitrykorlas/comment:1.0 ./comment
docker build -t dmitrykorlas/ui:1.0 ./ui

# create dedicated bridge network
docker network create reddit

# run containers
docker run -d --network=reddit \
  --network-alias=post_db \
  --network-alias=comment_db mongo:latest

docker run -d --network=reddit \
  --network-alias=post dmitrykorlas/post:1.0

docker run -d --network=reddit \
  --network-alias=comment dmitrykorlas/comment:1.0

docker run -d --network=reddit \
  --name=service_ui \
  -p 9292:9292 dmitrykorlas/ui:1.0
```

### Run containers with persistent storage

```shell script

# kill+remove (optional)
docker kill $(docker ps -aq)

docker volume create reddit_db

# run containers
docker run -d --network=reddit \
  --network-alias=post_db \
  --network-alias=comment_db \
  -v reddit_db:/data/db mongo:latest

docker run -d --network=reddit \
  --network-alias=post dmitrykorlas/post:1.0

docker run -d --network=reddit \
  --network-alias=comment dmitrykorlas/comment:1.0

docker run -d --network=reddit \
  --name=service_ui \
  -p 9292:9292 dmitrykorlas/ui:3.0

# now, the data will not be lost between containers re-run
# we can inspect containers via this command:
docker volume ls
docker volume inspect reddit_db
```


## Task *
> run containers using custom network aliases. Setup communication between them using env variables.

```shell script
docker run -d --network=reddit \
  --network-alias=service_post_db \
  --network-alias=service_comment_db mongo:latest

docker run -d --network=reddit \
  --env POST_DATABASE_HOST=service_post_db \
  --network-alias=service_post dmitrykorlas/post:1.0

docker run -d --network=reddit \
  --env COMMENT_DATABASE_HOST=service_comment_db \
  --network-alias=service_comment dmitrykorlas/comment:1.0

docker run -d --network=reddit \
  --env POST_SERVICE_HOST=service_post \
  --env COMMENT_SERVICE_HOST=service_comment \
  -p 9292:9292 dmitrykorlas/ui:1.0
```

## Task **
> - Try to use Alpine based image
> - Find how to reduce the image size

- Created multi-stage build for reducing an image size. See result in **Dockerfile.3.0** file.
- Used lightweight **ruby:2.6.5-alpine** image vs initial heavy **ruby:2.2**.
- The final sizes of images: v1.0=**770MB**, v2.0=**447MB**, v3.0=**67.2MB**

## Helpful links
- https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- https://github.com/hadolint/hadolint
- https://pypi.org/project/py-zipkin/
- https://hub.helm.sh/charts/stable/kube-ops-view
- https://lipanski.com/posts/dockerfile-ruby-best-practices
- https://github.com/codeRIT/brickhack.io/blob/4bc5629a2bea97b88953b0a9cccaf9a71e3143ca/Dockerfile
- https://github.com/bmedici/service-graph/blob/a643ea7571e106ac682b6a564b0532b8272e8fb2/Dockerfile


# Homework 16: Docker compose and network management

```shell script
docker run -ti --rm --network none joffotron/docker-net-tools -c ifconfig
docker run -ti --rm --network host joffotron/docker-net-tools -c ifconfig
```

## run front_net + back_net docker configuration with the separate access to the db host
```shell script
# run docker build, see the instructions from the previous HW
docker network create back_net --subnet=10.0.2.0/24
docker network create front_net --subnet=10.0.1.0/24
docker run -d --network=front_net -p 9292:9292 --name ui dmitrykorlas/ui:1.0
docker run -d --network=back_net --name comment dmitrykorlas/comment:1.0
docker run -d --network=back_net --name post dmitrykorlas/post:1.0

docker run -d --network=back_net --name mongo_db \
    --network-alias=post_db --network-alias=comment_db mongo:latest

# connect post and connect to the second network
docker network connect front_net post
docker network connect front_net comment
```

Check iptables. See POSTROUTING section - this is how bridget network connects container with host.
```shell script
sudo iptables -nL -t nat
```

Check docker-proxy
```shell script
ps ax | grep docker-proxy
```

## Docker compose

```shell script
cd ./src
export USERNAME=dmitrykorlas
docker-compose up -d
```

To make the app be available on the 80 port, we have to allow firewall on GCP on the docker-host image

To re-create images use this command:
```shell script
docker-compose up -d --force-recreate
```
