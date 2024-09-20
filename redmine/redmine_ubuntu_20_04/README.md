# Redmine (Ubuntu 20.04 variant)
## Intro
Redmine is a great opensource replacement for Jira. I like it not only for software-dev but a way to keep my life organized. The one issue I had was that it was not a simple: `apt-get install redmine`. There were some peculularies with its install and setup, so I captured/fixed/documented those issues by creating a docker image it.

This README covers building the ubuntu 20.04 redmine variant image, starting it and notes about saving, seeding (on restart) the Redmine database with your saved data.

# 1.0 Basic Setup/Workflow
In order to use this Dockerfile & assets/scripts to get redmine going, you will:
1) Need to have a copy of ubuntu and have installed docker. (`sudo apt-get install docker`, etc)
2) Use the contained Dockerfile to build the dockerimage (the built image takes about 2.4 GB once built)
3) Start the docker image.

So, go get ubuntu if you are not using it already (its free), `git clone` this repo and apt-get install docker, then lets get buidling :)

# 2.0 Building the docker image
Assuming you've pulled down this repo, and you have docker installed run something like:

```
cd <location_of_this_repo_checkout>/redmine/redmine_ubuntu_20_04
docker build -t redmine_image .
```
Now wait a bunch of time as the DockerFile is read by docker, and the image is built up, one "RUN" line at a time...

# 3.0 Start the Docker image.
To start the docker image, I sugest you create a directory (outside of the repo tree, so git doesnt pick it up). where we will save our redmine data
**Note** (for those new to Docker): The docker reads the DockerFile to create these read-only images (which we did in step #2.0 using `docker build`). Then,
when a docker container is started, it reads the specified docker image, and does/runs stuff using that read-only image, but doesn't save any changes caused by
running the running container (which is actually super handy/awesome/a key-concept of docker). So in order for our application to save actual data, we need to
tell docker (when we start the docker container), to connect to or 'mount' a directory on the host-PC, where the PIDs running in the container can actually save
data to (or read host-specified data from).

The other thing we need to do is ensure we provide the docker container with any seed-data from a previously started redmine instance.

And finally we also need to make sure we map the web-server port, (for the apache2 server running inside the container) to a port on the HOST PC, so that
web-browsers can talk to/and load the redmine webserver. Here is an example:

```
cd ~
mkdir redmine_workspace
cd redmine_workspace
docker run --name "redmine_container" -dit --rm -p 80:80 -v ${HOME}/redmine_workspace:/workspace redmine_image:latest
```
Here is an explanation of the `docker run` line above:

- the `--name` is used to name the new container we are starting... in this case we called it: "redmine_container" for clarity.
- the `-dit` expands to `-d -i -t` which means to run interactive mode, but put it into the background as a daemon. This is a quick way
  to prevent the docker container from staying in our foreground, but also allowing us to connect to a bash shell in it if we ever need to, at a later time
- the `--rm` means to delete any pre-existing containers with the name "redmine_container"  (so we can name ours that name). It doesnt really matter if
  you wipe an old container, since again, once that container is dead, any changes not in the persisted "workspace" dir are lost anyway. But if a container died
  unexpectedly, you can still get debug info... (well until you `--rm` it that is)
- the `-p 80:80` means to map the container's port 80 to the HOST-PCs port 80, so anytime something talks to port 80 on the HOST PC, it will be forwarded to
  any processes listening to port 80 in the docker container.
- the `-v <first_path>:<second_path>` means to mount (or connect) the HOST-PCS directory (designated as `<first_path>` to a path in the container, named `<second_path>`. I should note the path in container is created if it doesnt already exist.
- the `redmine_image:latest` is the name of the read-only image (and its :version) that the container will run-from

Now, once that `docker run` line is ran, after a couple of seconds to a minute, you should be able to see the redmine web-application, by opening a browser and pointing it to your localmachine:80. e.g, in firefox type URL:
    `http://localhost/redmine`
**Note**: I'm assuming you have no firewalls up, and you are running redmine on the same machine as you are running the browser from.

# Notes on Accessing Docker image directly
## Connecting to Docker Image

Connect to the running docker container with something like this:
```
docker exec -it redmine_container /bin/bash
```
Where:
 - the `-it` means "run the execute interactively, connecting to stdin to the TTY (terminal)"
 - the `/bin/bash` means to run the bash command interpretter.

## Starting/Stoping redmine from within Docker image

**STOPING**

Redmine is written in ruby (on rails), and apache starts it automatically via Passenger, so we can use Apache to handle this:
```
service apache2 stop
```

**STARTING**
```
service apache2 start
```

**LOGS**

* Logs for apache3 are located in:
```
/var/log/apache2
```

* Logs for Redmine are located in:
```
/var/logs/redmine
```


# Notes on Saving and Seeding redmine Data
As noted above, if the docker container dies, the data (not saved to the workspace directory) is lost. Redmine stores its data in mysql, and a non-workspace path
within the container. I wrote a backup script that runs every hour, on the hour (I used cron to run the script), to dump the redmine dbase, and related attachment files, into a tarbal that gets saved in your workspace. You can always run this script in the container your-self if you want to (e.g, you did a bunch of changes, and want to make sure it gets backedup). To do this do:
1) connect to the running docker container with something like this:
```
docker exec -it redmine_container /bin/bash
```
Where:
 - the `-it` means "run the execute interactively, connecting to stdin to the TTY (terminal)"
 - the `/bin/bash` means to run the bash command interpretter.

2) call the backup script with this:
```
cd /assets/run_scripts
./backup_redmine_data.sh
```

Then, after a few minutes all the data will be written into a tarball and stored in the workspace.

## Restoring saved data
This actually happens automagically when the container starts via another script I wrote (in the same directory as the backup_redmine_data.sh script)
Essentially it looks for the same file-name of the tarbal (that the backup-script created and stored to the persisting workspace directory), and loads/seeds the
that data into the mysql server, running in the container. after the data is seeded, it starts apache (The webserver).

In this way as long as you dont touch the workspace directory between starting and restarting, the data-should be re-seeded each time the docker container restarts.

**Side Note:** This is also very handy if you ever want to start more than on redmine container, and seed with test data, incse you are trying to mess with redmine, whilst not messing up your "production" version running (e.g, I can keep production redmine running, but spin up another container on another HOST-port, and using another workspace directory where I copy in my backup datafile... Then in my "sandbox" redmine container I can mess with redmine to say,... install/test new plugins :) ). Docker's pretty rad.

