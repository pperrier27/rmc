#!/bin/bash

set -e

MONGODB_VERSION=3.2  # latest stable, Nov. 2016
NODEJS_MAJ_VERSION=6 # idem
SPARK_VERSION=2.0.1  # idem
HADOOP_VERSION=2.6   # idem

SUDO="sudo"
# Debian doesn't have $SUDO, so adapt to that
if ! which sudo > /dev/null; then
    $SUDO=""
fi

install_packages() {
    # mongod starts automatically after install. We don't want that.
    should_stop_mongo=""
    if ! which mongod >/dev/null; then
      should_stop_mongo=yes
    fi

    updated_apt_repo=""

    # To get the most recent nodejs, later.
    # This will also get you npm, which will also be needed later.
    if ! ls /etc/apt/sources.list.d/ 2>&1 | grep -q chris-lea*node_js; then
        curl -sL https://deb.nodesource.com/setup_"${NODEJS_MAJ_VERSION}".x | $SUDO -E bash - # straight from the nodejs install instructions for version 6.x
        updated_apt_repo=yes
    fi

    # To get the most recent redis-server
    wget http://download.redis.io/redis-stable.tar.gz
    tar xvzf redis-stable.tar.gz
    cd redis-stable
    $SUDO make install
    cd ..
    $SUDO rm -rf redis-stable
    $SUDO rm -rf redis-stable.tar.gz

    # To get the most recent mongodb, dependent on the version specified in $MONGODB_VERSION
    if ! ls /etc/apt/sources.list.d/ 2>&1 | grep -q mongo; then
        $SUDO apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
	echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/"${MONGODB_VERSION}" multiverse" | \
$SUDO tee /etc/apt/sources.list.d/mongodb-org-"${MONGDB_VERSION}".list
        updated_apt_repo=yes
    fi

    # Register all that stuff we just did.
    if [ -n "$updated_apt_repo" ]; then
        $SUDO apt-get update -qq -y || true
    fi

    $SUDO apt-get install -y \
        build-essential \
	git \
        python-setuptools python-pip python-dev \
        libxml2-dev libxslt-dev \
        ruby rubygems-integration ruby-dev \
        nodejs \
        redis-server \
        mongodb-org \
	nodejs \
	nodejs-legacy \ # need this for some things to work with the node alias
        unzip

    if [ -n "$should_stop_mongo" ]; then
        $SUDO service mongodb stop
    fi
}

# Uses npm to install PhantomJS. npm should have been obtained from the NodeJS install in install_packages
install_phantomjs() {
    if ! which phantomjs >/dev/null; then
	$SUDO npm install phantomjs
        which phantomjs >/dev/null
    fi
}

# Assumes that Chrome is installed
# Uses npm to install chromedriver. npm should have been obtained from the NodeJS install in intall_packages
install_chromedriver() {
    if ! which chromedriver >/dev/null; then
        $SUDO npm install chromedriver
        which chromedriver >/dev/null
    fi
}

install_spark() {
    rm -rf spark
    wget "http://apache.mirror.vexxhost.com/spark/spark-"${SPARK_VERSION}"/spark-"${SPARK_VERSION}"-bin-hadoop"${HADOOP_VERSION}".tgz" -O tempfile
    mkdir spark
    tar xzf tempfile -C spark --strip-components=1
    rm tempfile
    export SPARK_HOME=${PWD}"/spark"
}

# Must run this as root
if (( $(id -u) -ne 0 )); then
  echo "ERROR: This script must be run as root."
  exit 1
fi

install_packages
install_phantomjs
install_chromedriver
install_spark
