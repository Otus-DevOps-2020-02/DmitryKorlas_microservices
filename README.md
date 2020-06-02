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

**-d** run container in background mode (as daemon)
**-t** create TTY
```shell script
docker run -dt nginx:latest
```

```shell script
run new process inside container
docker exec -it <container_id> bash
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

## The task *
> Describe Container vs image difference
>
Docker image is readonly it could use another image (extend) as a base. Image contains the app dependencies and libraries. Docker container has read+write layer and run docker image in runtime virtual environment, so container depends on image. Container provides the final phase of virtualization.

## Helpful links
- https://docs.travis-ci.com/user/notifications/#configuring-slack-notifications
- https://docs.docker.com/engine/reference/commandline
- https://phoenixnap.com/kb/docker-image-vs-container
- https://ru.wikipedia.org/wiki/Сигнал_(Unix)
- https://github.com/jpetazzo/dind
- https://docs.docker.com/engine/security/userns-remap/
- https://docs.docker.com/engine/reference/run/#example-run-htop-inside-a-container
