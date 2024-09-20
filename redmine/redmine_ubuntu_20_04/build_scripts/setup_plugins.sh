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


# 4.0 next plugin...


