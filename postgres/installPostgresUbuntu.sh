#!/bin/bash

function printHeader {

echo "############################################################################################"
echo "# This script is designed to build the PostgreSQL database version you specify from source #"
echo "# The main purpose of this script to to quickly test community versions as a result        #"
echo "# the directory locations and settings are not necessarily PRODUCTION ready                #"
echo "#                                                                                          #"
echo "#                                 Tested for Ubuntu                                        #"
echo "############################################################################################"
echo
checkLatestVersion
read -p "Specify PostgreSQL version, eg $latestVersion... " PGVER
echo Version specified:$PGVER
read -p "Initialize database? " INIT_REPLY
read -p "Compile and install contrib extensions? " EXT_REPLY

INIT_DIR=$PWD
BINDIR=$HOME/postgres-$PGVER-`date +%F`
DATADIR=$BINDIR/data
PG_LOGFILE=$BINDIR/postgres.log
DEPLOY_LOGFILE=$BINDIR/INSTALL.LOG
DEPLOY_PGUSER=`whoami`
DEPLOY_PGPORT=`echo $RANDOM`
downloadUrl="https://ftp.postgresql.org/pub/source/v$PGVER/postgresql-$PGVER.tar.gz"
}


function checkLatestVersion {
    latestVersion=$(curl -s https://ftp.postgresql.org/pub/source/ | grep -oP 'v\K[0-9]+\.[0-9]+' | sort -V | tail -n 1)
}

function checkInstallStatus {
    if [[ -f $BINDIR/bin/pg_ctl ]]
    then
        echo "^^^ WARNING: Postgres version $PGVER appears to be installed in $BINDIR. ^^^"
        exit 17
    else
        installPrereqs
    fi
}

function verifyVersion {
    if curl --head --silent --fail $downloadUrl 1>&2> /dev/null;
    then
        echo
        echo "--> Postgres version $PGVER available in community source. <--"
    else
        echo
        echo "^^^ ERROR: We cannot find the version you specified $PGVER, please verify you entered the correct version number. ^^^"
        exit 2
    fi
}

function installPrereqs {
    read -p "Do you wish to continue and install the required packages? " RESPONSE
    if [[ $RESPONSE =~ ^([Yy])$ ]]
    then
        echo
        echo "--> Installing required packages <--"
        sudo apt-get update
        sudo apt-get install -y build-essential libreadline-dev zlib1g-dev flex bison libxml2-dev libxslt-dev libssl-dev \
            libperl-dev libkrb5-dev libpam0g-dev libldap2-dev libicu-dev clang liblz4-dev libzstd-dev wget 1>&2> /dev/null
        downloadPostgresSrc
    else
        echo "^^^ WARNING: Cancelling per user request ^^^"
        exit 0
    fi
}

function downloadPostgresSrc {
    echo "--> Locating PostgreSQL source files for version $PGVER <--"
    if [[ -f postgresql-$PGVER.tar.gz ]]
    then
        echo
        echo "--> Source files already available locally <--"
        extractCompilePostgres
    else
        echo "--> Downloading PostgreSQL source files for version $PGVER <--"
        wget $downloadUrl
        if [[ $? -ne 0 ]]
        then
            echo "^^^ ERROR: Download failed ^^^"
            exit 1
        else
            extractCompilePostgres
        fi
    fi
}

function initializeDatabase {
    echo "--> Checking for existing data directory for PostgreSQL version: $PGVER <--"
    if [[ -d $DATADIR/global ]]
    then
        echo "^^^ WARNING: Target directory for database initialization exists ^^^"
        exit 17
    else
        echo "--> Initializing database for $PGVER <--"
        $BINDIR/bin/initdb --pgdata=$DATADIR --data-checksums
        if [[ $? -ne 0 ]]
        then
            echo "^^^ ERROR: Initializing database failed ^^^"
            exit 1
        else
            echo "--> Database initialization completed <--" | tee -a $DEPLOY_LOGFILE
            echo "--> Database can be started using: " | tee -a $DEPLOY_LOGFILE
            echo "          $BINDIR/bin/pg_ctl -D $DATADIR -l $PG_LOGFILE start" | tee -a $DEPLOY_LOGFILE
            echo "--> Connect to database using: " | tee -a $DEPLOY_LOGFILE
            echo "          psql -h localhost -p $DEPLOY_PGPORT postgres" | tee -a $DEPLOY_LOGFILE
            echo " " | tee -a $DEPLOY_LOGFILE
            if [[ $EXT_REPLY =~ ^(Y|y)$ ]]
            then
                compileExtensions
            else
                echo "^^^ WARNING: Extensions not compiled, run $BINDIR/bin/pg_config --sharedir to locate extensions directory. ^^^"
                exit 0
            fi
        fi
    fi
}

function compileExtensions {
    echo ""
    echo "--> Compiling extensions for PostgreSQL version: $PGVER <--" | tee -a $DEPLOY_LOGFILE
    echo "-->     User specified extensions: $(echo $EXTENSIONS) <--" | tee -a $DEPLOY_LOGFILE
    for extension in $(echo $EXTENSIONS | sed "s/,/ /g")
    do
        cd $INIT_DIR
        echo "" | tee -a $DEPLOY_LOGFILE
        echo "--> Compiling and installing extension: $extension <--" | tee -a $DEPLOY_LOGFILE
        cd postgresql-$PGVER/contrib/$extension
        make 1>&2> /dev/null
        if [[ $? -ne 0 ]]
        then
            echo "^^^ ERROR: Compile failed for $extension ^^^"
            exit 1
        else
            echo "--> Installing $extension <--"
            sudo make install 1>&2> /dev/null
            if [[ $? -ne 0 ]]
            then
                echo "^^^ ERROR: Install failed for $extension ^^^"
                exit 1
            else
                echo "--> $extension installed successfully <--" | tee -a $DEPLOY_LOGFILE
            fi
        fi
    done
    echo "--> Resetting permissions for installed extensions <--"
    sudo chown -R $DEPLOY_PGUSER $BINDIR/share/extension
    echo "--> Extensions have been installed to: $BINDIR/share/extension <--" | tee -a $DEPLOY_LOGFILE
    exit 0
}

function extractCompilePostgres {
    if [[ ! -d postgresql-$PGVER ]]
    then
        tar xf postgresql-$PGVER.tar.gz
        if [[ $? -ne 0 ]]
        then
            echo "^^^ ERROR: Could not extract source files ^^^"
            exit 1
        fi
    else
        rm -rf postgresql-$PGVER
        tar xf postgresql-$PGVER.tar.gz
        if [[ $? -ne 0 ]]
        then
            echo "^^^ ERROR: Could not extract source files ^^^"
            exit 1
        fi
    fi

    if [[ $EXT_REPLY =~ ^(Y|y)$ ]]
    then
        AVAILABLE_EXTENSIONS=$(ls postgresql-$PGVER/contrib -m)
        read -p "Specify extensions to install from the following list: $(echo $AVAILABLE_EXTENSIONS) ... " EXTENSIONS
    fi

    cd postgresql-$PGVER/
    echo
    echo "--> Running configure <--"
    ./configure --prefix=$BINDIR --with-pgport=$DEPLOY_PGPORT --with-openssl --with-perl --with-tcl --with-ossp-uuid --with-pam --with-ldap \
        --with-krb-srvnam=whatever --with-gssapi --enable-debug 1>&2> /dev/null
    if [[ $? -ne 0 ]]
    then
        echo "^^^ ERROR: Executing configure failed ^^^"
        cd $INIT_DIR
        exit 1
    else
        echo
        echo "--> Compiling $PGVER engine source <--"
        make 1>&2> /dev/null
        if [[ $? -ne 0 ]]
        then
            echo "^^^ ERROR: Compile failed ^^^"
            cd $INIT_DIR
            exit 1
        else
            echo
            echo "--> Installing $PGVER from source <--"
            sudo make install 1>&2> /dev/null
            if [[ $? -ne 0 ]]
            then
                echo "^^^ ERROR: Install from source failed ^^^"
                make clean 1>&2> /dev/null
                cd $INIT_DIR
                exit 1
            else
                make clean 1>&2> /dev/null
                echo "--> Resetting permissions <--"
                sudo chown -R $DEPLOY_PGUSER $BINDIR
                echo "--> Binaries installed to: $BINDIR/bin <--"
                echo "--> Install complete <--"
                if [[ $INIT_REPLY =~ ^(Y|y)$ ]]
                then
                    cd $INIT_DIR
                    initializeDatabase
                else
                    echo "^^^ WARNING: Database not initialized, run $BINDIR/bin/initdb -D $DATADIR later if required. ^^^"
                    cd $INIT_DIR
                    exit 0
                fi
            fi
        fi
    fi
}

printHeader
verifyVersion
checkInstallStatus
