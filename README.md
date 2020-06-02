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

## Helpful links
- https://docs.travis-ci.com/user/notifications/#configuring-slack-notifications
- https://docs.docker.com/engine/reference/commandline
- https://phoenixnap.com/kb/docker-image-vs-container
