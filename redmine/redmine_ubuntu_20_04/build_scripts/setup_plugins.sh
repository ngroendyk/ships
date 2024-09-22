#!/bin/bash
# Purpose: Sets up the plugins stuff architecture so that they are built into the docker image

# 1. Fix some directories
mkdir /usr/share/redmine/plugins
cd /usr/share/redmine/plugins

# 2.0 Get draw.io plugin
git clone https://github.com/mikitex70/redmine_drawio.git

# 2.1 fix the public_assets dir
cd /usr/share/redmine/public/plugin_assets
rm empt*
ln -s /var/cache/redmine/default/plugin_assets/redmine_drawio/


# 3.0 Get the MathJax Plugin
cd /usr/share/redmine/plugins
git clone https://github.com/mboratko/redmine_latex_mathjax.git
cd /usr/share/redmine
bundle install

# 4.0 Do the CRM plugin
cp -r /assets/build/plugins/redmine_contacts /usr/share/redmine/plugins
cd /usr/share/redmine
bundler install

service mysql start
bundle exec rake redmine:plugins NAME=redmine_contacts RAILS_ENV=production
service mysql stop
# Link in the assets to fix some styling and icons (gravitars)
ln -s /usr/share/redmine/plugins/redmine_contacts/assets /usr/share/redmine/public/plugin_assets/redmine_contacts

# 5.0 Do the Resubmission plugin (so you can pull back in tasks after some time)
cd /usr/share/redmine/plugins
git clone https://github.com/HugoHasenbein/redmine_auto_resubmission.git
cd /usr/share/redmine
bundle install

# 6.0 Do the PDF (and other plugins) plugin
cd /usr/share/redmine/plugins
git clone https://github.com/HugoHasenbein/redmine_more_previews.git
cd /usr/share/redmine
bundle install

# 7.0 next plugin

