# Pull down the ubuntu 22.04 base image from public docker registry
FROM ubuntu:22.04

# Set the working dir (outside of image). That way we can copy in
# stuff that will become part of the image
WORKDIR assets

#Copy the assets to the container's ~
COPY scripts .


# Now lets install a bunch of deps for our app.
## As per: https://stackoverflow.com/questions/22466255/is-it-possible-to-answer-dialog-questions-when-installing-under-docker
# Make sure apt goes interactive by using ARG (not ENV, since ENV ends up in image, but ARG is for building only)
ARG DEBIAN_FRONTEND=noninteractive

## Basic stuff
RUN apt-get update
RUN apt-get -y install iputils-ping net-tools gcc g++ make cmake vim nmap wget curl

# Redmine deps
## Need ruby and gem.
RUN apt-get -y install gem ruby

# gem update will need these deps (discovered these myself. not in docs)
RUN apt-get -y install ruby-dev zlib1g zlib1g-dev libyaml-dev libyaml-0-2 libyaml-dev libyaml-0-2 libffi8 libffi-dev libreadline-dev libreadline8 libmysqlclient-dev ruby-rmagick imagemagick libmagickwand-dev rsync


## Need apache
RUN apt-get -y install apache2 libapache2-mod-passenger

## Need SQL. might use SQLLite since no sql server needed then
RUN apt-get -y install mysql-server mysql-client

## Need redmine itself
# No stable redmine for 22.04 ubuntu jammy. so try from prebuilt-source bundle:
#RUN apt-get -y install redmine redmine-mysql
RUN wget https://www.redmine.org/releases/redmine-5.0.4.tar.gz
RUN tar -zxf redmine-5.0.4.tar.gz
RUN mv ./redmine-5.0.4 /usr/share/redmine 

#update server name if needed, the timezone, ect.


# Now update gem, and install bundler gem (Ruby specific)
RUN gem update
RUN gem install bundler

# Update some files.

# Need to set sql passwords.
# Need to seed dbase.
# Need to set password for redmine.

# Need to update mysql files.

# As per install doc in image at loc: /usr/share/redmine/doc,
# do step 2: Create utf8 encoded db called "redmine"
RUN ./seed1.sh "CREATE DATABASE redmine;"

# Now step 3. config database.yml file... its essentially the default (mysql2 adapter)
RUN cp /usr/share/redmine/config/database.yml.example /usr/share/redmine/config/database.yml

# Now step 4. Now run bundler to install gems.
WORKDIR /usr/share/redmine
RUN bundle install --without development test

# Step 5 & 6. generate a session secret, and seed dbase
WORKDIR /assets
RUN ./seed2.sh
#WORKDIR /usr/share/redmine
#RUN bundle exec rake generate_secret_token
#
## Step 6. Seed Dbase
#RUN bundle exec rake db:migrate RAILS_ENV="production"


# Step 7. Stuff about perms... hmm we are root right now, but I suspect apache user will be doing stuff
# and we need to get that phusion thing to do its trick... so for now ignore.
# Lets jump to old instructions at: https://www.redmine.org/projects/redmine/wiki/howto_install_redmine_on_ubuntu_step_by_step

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


# DANG! mysql seems to be borked....
# Looks like the mysql gem project is not maintained anymore.... I wonder if we can just use sqlite.
# for now going to try switching over to Ub 20.04 ver... older but at least IVe seen it work.
# FOund this digging around in both the apache2 error logs and the ruby logs in the redmine log dir.



### Now Do specific plugin install steps... 1 at a time.... ###  


## DONE! Post notes:
# since we are actually building the image. Lets update some default startups stuff (like turning my mysql and apache2 to service redmine on container boot)

# Also add in hook to automatically dump the dbase at container exit, so we dont loose precious data.

# If provided (via workspace) on container boot, we should also  restore the dbase instead of re-seeding it.. how does this work with at session secret?
# Can we better encrypt data incase redmine gets hacked.... (as in the mysql dbase)

# https://forums.docker.com/t/dumping-db-before-stopping-the-containers/49201

