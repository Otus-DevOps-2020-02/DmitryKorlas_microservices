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

`docker-compose` use some kind of special naming of containers. See output of the "names" column of command `docker ps`:
```shell script
src_post_db_1
src_ui_1
src_comment_1
src_post_db_1
```
we can manage it using `container_name` parameter

## Helpful links
- https://docs.docker.com/compose/extends/#understanding-multiple-compose-files


# Homework 17: GitLab CI

creating a machine: see requirements page = https://docs.gitlab.com/ce/install/requirements.html
```shell script
gcloud compute instances create "gitlab-ci" \
	--image-family="ubuntu-1604-lts" \
	--image-project=ubuntu-os-cloud \
	--machine-type="n1-standard-1" \
	--boot-disk-size="100" \
	--zone="europe-west1-b" \
	--tags="default-allow-http,default-allow-ssh,http-server,https-server"
```

Lightweight setup process to be used for demo purposes https://docs.gitlab.com/omnibus/README.html, https://docs.gitlab.com/omnibus/docker/README.html.
Is bad for maintenance, but ok for quick-your of GitLab CI features overview.

Install docker using playbooks from the previous home work:
```shell script
cd REPO_ROOT/docker-monolith/infra/ansible
ansible-inventory --graph
ansible-playbook ./playbooks/install_docker.yml --limit gitlab
```

Install gitlab
```shell script
mkdir -p /srv/gitlab/config /srv/gitlab/data /srv/gitlab/logs
cd /srv/gitlab/
touch docker-compose.yml
```

```shell script
web:
  image: 'gitlab/gitlab-ce:latest'
  restart: always
  hostname: 'gitlab.example.com'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'http://<YOUR-VM-IP>'
  ports:
    - '80:80'
    - '443:443'
    - '2222:22'
  volumes:
    - '/srv/gitlab/config:/etc/gitlab'
    - '/srv/gitlab/logs:/var/log/gitlab'
    - '/srv/gitlab/data:/var/opt/gitlab'
```

script taken from https://docs.gitlab.com/omnibus/docker/README.html#install-gitlab-using-docker-compose

Visit gitlab on http://<YOUR-VM-IP>

After setup the new password and sign in, create group **homework** and repository **example**.

**Install gitlab-runner**
Make ssh connection to the `gitlab-ci` host
```shell script
docker run -d --name gitlab-runner --restart always \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest
```

register runner
```shell script
docker exec -it gitlab-runner gitlab-runner register --run-untagged --locked=false
```
It will ask few questions:
```shell script
Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
http://34.78.40.221/
Please enter the gitlab-ci token for this runner:
yk5mBRb4tYaUqwqZ3xsg # copy it from CI/CD settings of the repository you created
Please enter the gitlab-ci description for this runner:
[58b845540b82]: my-runner
Please enter the gitlab-ci tags for this runner (comma separated):
linux,xenial,ubuntu,docker
Registering runner... succeeded                     runner=yk5mBRb4
Please enter the executor: ssh, custom, docker, parallels, shell, kubernetes, docker-ssh, virtualbox, docker+machine, docker-ssh+machine:
docker
Please enter the default Docker image (e.g. ruby:2.6):
alpine:latest
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
root@gitlab-ci:/home/appuser#
```

Create an executor code:
```shell script
git clone https://github.com/express42/reddit.git && rm -rf ./reddit/.git
git add reddit/
git commit -m "gitlab-ci-1: Add reddit app"
git push gitlab gitlab-ci-1
```

see content of `.gitlab-ci.yml`

After push to the repo, the pipeline should run the tests and other described things


# Homework 18: Monitoring

## Run prometheus:
```shell script
gcloud compute firewall-rules create prometheus-default --allow tcp:9090
gcloud compute firewall-rules create puma-default --allow tcp:9292

export GOOGLE_PROJECT=docker-279121

# create docker host
docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-zone europe-west1-b \
    docker-host

# configure local env
eval $(docker-machine env docker-host)

docker run --rm -p 9090:9090 -d --name prometheus prom/prometheus
```

```shell script
# check the ip
docker-machine ip docker-host
34.88.251.183
```

then, visit the page http://34.88.251.183:9090 to see prometheus control panel.

```shell script
docker stop prometheus
```

## connect prometheus to the puma application

add this content into `monitoring/prometheus/Dockerfile`

```shell script
FROM prom/prometheus:v2.1.0
ADD prometheus.yml /etc/prometheus/
```

add file `monitoring/prometheus/prometheus.yml`

then, run docker build inside the `monitoring/prometheus`
```shell script
cd monitoring/prometheus
export USER_NAME=dmitrykorlas
docker build -t $USER_NAME/prometheus .

dmitrykorlas is <YOUR_DOCKER_HUB_LOGIN>
```

Create builds of app components
```shell script
# in src/ui
bash docker_build.sh

# in src/post-py
bash docker_build.sh

# in src/comment
bash docker_build.sh
```

or via batch script:
```shell script
for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done
```

Modify `docker/docker-compose.yml` by adding new prometheus service

check versions of images in the .env file (set to latest)

run the compose
```shell script
cd docker
# -f docker-compose.yml is added to omit using docker-compose.override.yml
docker-compose -f docker-compose.yml up -d

# use this command, if you run it on the local machine:
docker-compose up -d
```

In case app is not available, check the http/https ports is not blocked on GCP: check docker-host machine settings

## check how it works
let's stop post service
```shell script
docker-compose stop post
```

then, open the prometheus control panel and set **ui_health** into the search field.
Click on *Execute* button and open the chart. You will see that it show UI service down.
Check chart **ui_health_comment** the same way - it's available
Check chart **ui_health_post** - it's down.

Now, let's bring it to live using `docker-compose start post` command
Check the carts again - it shows the service is UP.

## Exporters
Is a some kind of agent to collect te metrics. When we unable to use prometheus inside the app, exporters can be suitable.
It transforms the status of application into the prometheus compatible metrics format.

Let's add new service in *docker-compose.yml* for node_exporter named `node-exporter`.

add new job into the prometheus config file at *monitoring/prometheus/prometheus.yml*
```shell script
- job_name: 'node'
  static_configs:
    - targets:
      - 'node-exporter:9100'
```

then, build the new image:
```shell script
cd monitoring/prometheus
docker build -t $USER_NAME/prometheus .
```

let's recreate our services
```shell script
docker-compose down
docker-compose -f docker-compose.yml up -d
```

Check targets on prometheus control panel - new endpoint named 'node' appears

Let's try to use it.
Set node_load1 at the search field, and push "Execute" button - it displays the overall load chart.

Let's continue to play around this chart.
connect to the docker-machine via ssh and generate the load to the machine:
```shell script
docker-machine ssh docker-host
yes > /dev/null
```

Now chart displays a leap.

push the results to the dockerhub:

```shell script
docker login
docker push $USER_NAME/ui
docker push $USER_NAME/comment
docker push $USER_NAME/post
docker push $USER_NAME/prometheus
```

As result, there are four builds available:
- https://hub.docker.com/repository/docker/dmitrykorlas/ui
- https://hub.docker.com/repository/docker/dmitrykorlas/comment
- https://hub.docker.com/repository/docker/dmitrykorlas/post
- https://hub.docker.com/repository/docker/dmitrykorlas/prometheus


# Helpful links
- https://github.com/prometheus/node_exporter
- https://github.com/prometheus/blackbox_exporter
- https://github.com/google/cloudprober


# Homework: Lecture 21. Monitoring visualisation.

Prepare docker-host using docker-machine - see details in previous homework.

Monitoring services moved to separate *docker-compose-monitoring.yml*
Now, app and monitoring runs separately.
```shell script
docker-compose -f docker-compose.yml up -d
docker-compose -f docker-compose-monitoring.yml up -d
```

## cAdvisor
cAdvisor is a service for containers monitoring. It will be used in this homework.
See changes, the new service 'cadvisor' added to docker-compose-monitoring.yml. Also, the new scrape config added to prometheus.yml.

re-build the prometheus image
```shell script
# run in monitoring/prometheus folder
export USER_NAME=dmitrykorlas
docker build -t $USER_NAME/prometheus .
```

then, start services using commands above.

add firewall rules to allow 8080 port
```shell script
gcloud compute firewall-rules create cadvisor-default --allow tcp:8080
```

visit http://<docker-machinehost-ip>:8080 to see cAdvisor control panel
visit http://<docker-machinehost-ip>:8080/metrics to see metrics collected for prometheus

Let's check that prometheus understand this metrics:
visit http://<docker-machinehost-ip>:9090 to see prometheus control panel

set `container_cpu_system_seconds_total` and see the chart

## Grafana

Grafana is a visualisation tool.
See grafana config in `docker-compose-monitoring.yml`

Run grafana:
```shell script
docker-compose -f docker-compose-monitoring.yml up -d grafana
```

visit http://<docker-machinehost-ip>:3000 to see grafana control panel

Now, let's add data source:
- Name: Prometheus Server
- Type: Prometheus
- URL: http://prometheus:9090
- Access: Proxy

then, press 'Add' button.

## Add grafana dashboard

visit https://grafana.com/grafana/dashboards/893 and press "download JSON" link.
save it as *monitoring/grafana/dashboards/DockerMonitoring.json*

then, in grafana control panel, press '+' icon at the left and import.
Use received JSON file.
Set "Prometheus Server" at "Options > Prometheus" field.

Now, the new dashboard appears.

## Add charts to the dashboard

UI HTTP requests:
rate(ui_request_count{http_status=~"[123].*"}[1m])

HTTP errors:
rate(ui_request_count{http_status=~"[45].*"}[1m])

95 percentile response time:
histogram_quantile(0.95, sum(rate(ui_request_response_time_bucket[5m])) by (le))

Rate of new posts
rate(post_count[1h])

Rate of new comments
rate(comment_count[1h])

## Alertmanager

It requires slack web-hooks integration:
- open slack group on the web http://devops-team-otus.slack.com
- navigate to "Apps" on the left side menu
- search for "Incoming web hooks"
- click "Add to Slack"
- choose the channel (#dmitry_korlas)
- choose Add incoming web-hooks integration
- it should display web-hook URL like this one *https://hooks.slack.com/services/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*
- add it to add into `monitoring/alertmanager/config.yml`

build alertmanager container and add it to the `docker-compose-monitoring.yml` (don't forget to allow 9093 port if it's blocked on GCP)
```shell script
# in monitoring/alertmanager
docker build -t $USER_NAME/alertmanager .
```

see `monitoring/prometheus/alerts.yml` to overview the basic alert example

See section alerts on prometheus control panel: http://IP:9090/alerts.
Also, see the separate alert control panel: http://IP:9093.

Let's try how it works:
stop post container:
```shell script
docker-compose stop post
```

wait for 1m, you have to receive new Slack notification. Also, check alerts in prometheus and http://IP:9093.
It displays that alert is FIRED.
After post service is UP, alert will be displayed as inactive

## Helpful links:
- https://github.com/google/cadvisor
- https://grafana.com/dashboards
- https://grafana.com/grafana/dashboards/893


# Homework: Lecture 23. Logging.

Create new machine
```shell script
export GOOGLE_PROJECT=docker-279121
docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-open-port 5601/tcp \
    --google-open-port 9292/tcp \
    --google-open-port 9411/tcp \
    logging

# switch docker to host machine
eval $(docker-machine env logging)

# find IP address
docker-machine ip logging
```

re-create builds due to tag has switched to 'logging'
```shell script
# in /src/ui
bash docker_build.sh && docker push $USER_NAME/ui

# in /src/post-py
bash docker_build.sh && docker push $USER_NAME/post

# in /src/comment
bash docker_build.sh && docker push $USER_NAME/comment
```

new logging services added into `docker-compose-logging.yml`
new container added to logging/fluentd/Dockerfile

**Fluentd is a tool for send, aggregate and convert (transform) log messages.**

build fluentd
```shell script
export USER_NAME=dmitrykorlas
docker build -t $USER_NAME/fluentd .
```

set version to 'logging' in `.env` (due to it was changed during build), then start services
`docker-compose -f docker-compose.yml up -d`

## see logs
run `docker-compose logs -f post` to see post logs in console

During Kibana installation, this link has been helpful
https://github.com/elastic/elasticsearch-docker/issues/92#issuecomment-318086404
Elasticsearch service has run with env variable `- discovery.type=single-node` due to following errors:
>
> [1] bootstrap checks failed
> [1]: the default discovery settings are unsuitable for production use; at least one of [discovery.seed_hosts, discovery.seed_providers, cluster.initial_master_nodes] must be configured
>

## Filter logs
Add section `<filter service.post>` in logging/fluentd/fluentd.conf

rebuild fluentd image
```shell script
docker build -t $USER_NAME/fluentd .
```

start fluentd
```
docker-compose -f docker-compose-logging.yml up -d fluentd
```

To see logs in Kibana, naviage to <DOCKER_MACHINE_IP>:5601

## Zipkin
**Zipkin is a tool for request tracing in a distributed systems**

See changes on docker-compose.yml docker-compose-logging.yml
all app services receives `- ZIPKIN_ENABLED=${ZIPKIN_ENABLED}` variable
and zipkin service has been added into `docker-compose-logging.yml`

Let's re-create services
```shell script
docker-compose -f docker-compose-logging.yml -f docker-compose.yml down
docker-compose -f docker-compose-logging.yml -f docker-compose.yml up -d
```

Explore zipkin control panel on <DOCKER_MACHINE_IP>:9411
To see the data, we have to reload our service frontpage (to submit requests)

## Task with *
> Using https://github.com/Artemmkin/bugged-code, find why the 'post' button produce delay of page loading.
>
method find_post contains `time.sleep(3)` - this is why it's processed too long

## Helpful links
- https://docs.docker.com/config/containers/logging/configure/
- https://peter.bourgon.org/blog/2017/02/21/metrics-tracing-and-logging.html
- https://docs.docker.com/engine/admin/logging/fluentd/


# Homework: Lecture 25. Kubernetes introduction.

This homework is step-by-step following the guide, described at: https://github.com/kelseyhightower/kubernetes-the-hard-way

To run the same command in multiple terminal sessions (which useful) we can use this hint:
**tmux sync panels mode:**
type `ctrl+b`, then `shift+:`
type `set synchronize-panes on` or `set synchronize-panes off` to sync or un-sync the panels.


Kubernetes components are stateless and store cluster state in [etcd](https://github.com/etcd-io/etcd).

Few commands
```shell script
kubectl get componentstatuses

kubectl get nodes

kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.7.0.yaml

kubectl get pods -l k8s-app=kube-dns -n kube-system

kubectl run busybox --image=busybox:1.28 --command -- sleep 3600
kubectl get pods -l run=busybox

# Retrieve the full name of the busybox pod:
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")

#Execute a DNS lookup for the kubernetes service inside the busybox pod:
kubectl exec -ti $POD_NAME -- nslookup kubernetes


kubectl create deployment nginx --image=nginx

kubectl logs $POD_NAME

kubectl exec -ti $POD_NAME -- nginx -v
```


## Helpful links
- https://github.com/kelseyhightower/kubernetes-the-hard-way
- https://kubernetes.io/docs/concepts/overview/components
- https://kubernetes.io/docs/reference/kubectl/cheatsheet/

# Homework: Lecture 27. Running Kubernetes cluster and application inside it. Model of security.

- **kubectl** - main tool to work with kubernetes API
- **~/.kube** stores a local info for kubectl
- **minikube** - utilites for the local kubernetes running and management

install kubectl:
```shell script
brew install kubectl
brew install kubectl-cli
kubectl version --client
```

install minikube:
```shell script
brew install minikube
```

create the cluster inside virtualbox:
```shell script
minikube start
```

```shell script
# check nodes
kubectl get nodes

kubectl config current-context
kubectl config get-contexts
```

Explore `~/.kube/config`, it contains info about context. Context is a combination of cluster+user+namespace.


update ui-deplayments.yml, then run ui-component in minikube
```shell script
kubectl apply -f ui-deployment.yml
kubectl get deployment
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     3/3     3            3           64s
```

important that AVAILABLE coutner is 3 - this number we set in ui-deployment.yml

Network adjustment:
```shell script
# find the pods of application using selector
kubectl get pods --selector component=ui
NAME                 READY   STATUS    RESTARTS   AGE
ui-74f6f754b-b4zrw   1/1     Running   0          4m56s
ui-74f6f754b-fn2ff   1/1     Running   0          4m56s
ui-74f6f754b-nsq7k   1/1     Running   0          4m56s

# setup port forwarding from local-port:pod:port
kubectl port-forward ui-74f6f754b-b4zrw 8080:9292
```

check http://localhost:8080 - it should display UI


## Helpful links
- https://kubernetes.io/docs/tasks/tools/install-kubectl/
- https://kubernetes.io/docs/tasks/tools/install-minikube/
