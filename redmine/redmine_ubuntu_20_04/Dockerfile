# Written By: Nate Groendyk
# Purpose: This dockerfile will pull down an ubuntu 20.04 image, and build
#          up all the components and configurations to get redmine running.
#          It also provides supplemental scripts to start & seed the redmine
#          dbase, as well as take backups of the database.
#          This Dockerfile is also configured to auto-start redmine and
#          add configures CRON to run the backup-script every hour.

# Pull down the ubuntu 20.04 base image from public docker registry
FROM ubuntu:20.04

# Set the working dir (outside of image). That way we can copy in
# stuff that will become part of the image
WORKDIR /assets/build

#Copy the build assets to the container
COPY build_scripts .

# Copy the runscript assets to container
WORkDIR /assets/run_scripts
COPY run_scripts .

# Now lets install a bunch of deps for our app.
## As per: https://stackoverflow.com/questions/22466255/is-it-possible-to-answer-dialog-questions-when-installing-under-docker
# Make sure apt goes interactive by using ARG (not ENV, since ENV ends up in image, but ARG is for building only)
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NONINTERACTIVE_SEEN true
## preesed tzdata, update package index, upgrade packages and install needed software
RUN truncate -s0 /tmp/preseed.cfg; \
    echo "tzdata tzdata/Areas select America" >> /tmp/preseed.cfg; \
    echo "tzdata tzdata/Zones/America select Toronto" >> /tmp/preseed.cfg; \
    debconf-set-selections /tmp/preseed.cfg && \
    rm -f /etc/timezone /etc/localtime && \
    apt-get update && \
    apt-get install -y tzdata



## Basic stuff
RUN apt-get update
RUN apt-get -y install iputils-ping net-tools gcc g++ make cmake vim nmap wget curl

# Redmine deps
## Need ruby and gem.
RUN apt-get -y install gem ruby

# gem update will need these deps (discovered these myself. not in docs)
RUN apt-get -y install ruby-dev zlib1g zlib1g-dev libyaml-dev libyaml-0-2 libffi7 libffi-dev libreadline-dev libreadline8 libmysqlclient-dev ruby-rmagick imagemagick libmagickwand-dev rsync cron

## Need apache
RUN apt-get -y install apache2 libapache2-mod-passenger

## Need SQL. might use SQLLite since no sql server needed then
RUN apt-get -y install mysql-server mysql-client

## Need git
RUN apt-get -y install git

## Need redmine itself. Use script to install since we need mysql up
## and also need to mod some file perms.
WORKDIR /assets/build
RUN ./seed1.sh

#update server name if needed, the timezone, ect.


# Now update gem, and install bundler gem (Ruby specific)
RUN gem install nokogiri -v 1.15.6
RUN gem update
RUN gem install bundler -v 2.4.22

# Bug with stringio, where 2 versions get installed. this uninstalls the non-default one.
RUN gem uninstall stringio

# Another bug, with class Mark. Essentially its due to uneeded-bundle packs interfering with eachother
# Documented here: https://www.redmine.org/boards/2/topics/65152
WORKDIR /usr/share/redmine
RUN bundle clean --force


# -- Plugin setup -- #
WORKDIR /assets/build

RUN ./setup_plugins.sh

# -- Done Plugin Setup -- #

WORKDIR /assets/run_scripts

# instructions at: https://www.redmine.org/projects/redmine/wiki/howto_install_redmine_on_ubuntu_step_by_step
# Config Apache. update passenger mod (adds this line to second line in file)
RUN sed -i '2i\  PassengerDefaultUser www-data' /etc/apache2/mods-available/passenger.conf

# Add symlink, set perms
RUN ln -s /usr/share/redmine/public /var/www/html/redmine

# Append Directory-redirect to apache2 config for sites.
RUN sed -i '30i<Directory /var/www/html/redmine>' /etc/apache2/sites-available/000-default.conf
RUN sed -i '31i\    RailsBaseURI /redmine' /etc/apache2/sites-available/000-default.conf
# See note below aboute apache2 having issues
RUN sed -i '32i\#    PassengerResolveSymlinksInDocumentRoot on' /etc/apache2/sites-available/000-default.conf
RUN sed -i '33i</Directory>' /etc/apache2/sites-available/000-default.conf

# Now add in a few gemfile.lock changes, as per current setup doc.
RUN touch /usr/share/redmine/Gemfile.lock
RUN chown www-data:www-data /usr/share/redmine/Gemfile.lock

# apache2 seems to have issue with PassengerResolveSymlinksInDocumentRoot. fix with this: https://serverfault.com/questions/895581/apache-passenger-resolve-symlinks-stopped-working-invalid-command
RUN sed -i '13i\       PassengerAppRoot /usr/share/redmine' /etc/apache2/sites-available/000-default.conf

# Look into saving dbase on container death:
# https://forums.docker.com/t/dumping-db-before-stopping-the-containers/49201


## set some perms, so scripts will run
RUN chmod -R 777 /assets

# Mod the crontab to call backup every hour.
## Build the crontab file to call our backup every hour at the 0th minute
RUN echo "0 * * * * cd /assets/run_scripts && /assets/run_scripts/execute_and_do_backup.sh > /dev/null 2>&1" > /etc/cron.d/backup_redmine-cron
## Need an empty line at EOF for a valid cron-file
RUN echo " " >> /etc/cron.d/backup_redmine-cron
RUN chmod 777 /etc/cron.d/backup_redmine-cron
# Install the cron-file into the cron-tab
RUN crontab /etc/cron.d/backup_redmine-cron

# It appears I can use ENTRY-POINT to specify a command that must always run on docker-container
# startup. Even if a docker run has more startup commands.
ENTRYPOINT /assets/run_scripts/start_redmine.sh

