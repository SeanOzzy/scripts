#!/bin/bash

function printHelp {
    echo "Usage: $(basename $0) [OPTIONS]"
    echo
    echo "Build and install PostgreSQL from source on Ubuntu."
    echo
    echo "Options:"
    echo "  (no options)            Interactive mode: prompts for a release version to download and build"
    echo "  --branch <branch_name>  Clone and build from a named git branch (e.g. master, REL_17_STABLE)"
    echo "  --commit <hash>         Clone and build from a specific git commit hash"
    echo "  -h, --help              Show this help message and exit"
    echo
    echo "Examples:"
    echo "  $(basename $0)"
    echo "  $(basename $0) --branch master"
    echo "  $(basename $0) --branch REL_17_STABLE"
    echo "  $(basename $0) --commit abc1234def5678"
}

function parseArgs {
    SOURCE_MODE="version"
    BRANCH_NAME=""
    COMMIT_HASH=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --branch)
                if [[ -n $COMMIT_HASH ]]; then
                    echo "^^^ ERROR: --branch and --commit are mutually exclusive ^^^"
                    exit 2
                fi
                if [[ -z $2 || $2 == --* ]]; then
                    echo "^^^ ERROR: --branch requires a value ^^^"
                    exit 2
                fi
                SOURCE_MODE="branch"
                BRANCH_NAME=$2
                shift 2
                ;;
            --commit)
                if [[ -n $BRANCH_NAME ]]; then
                    echo "^^^ ERROR: --branch and --commit are mutually exclusive ^^^"
                    exit 2
                fi
                if [[ -z $2 || $2 == --* ]]; then
                    echo "^^^ ERROR: --commit requires a value ^^^"
                    exit 2
                fi
                SOURCE_MODE="commit"
                COMMIT_HASH=$2
                shift 2
                ;;
            -h|--help)
                printHelp
                exit 0
                ;;
            *)
                echo "^^^ ERROR: Unknown option: $1 ^^^"
                echo
                printHelp
                exit 2
                ;;
        esac
    done
}

function printHeader {

echo "############################################################################################"
echo "# This script is designed to build the PostgreSQL database version you specify from source #"
echo "# The main purpose of this script to to quickly test community versions as a result        #"
echo "# the directory locations and settings are not necessarily PRODUCTION ready                #"
echo "#                                                                                          #"
echo "#                                 Tested for Ubuntu                                        #"
echo "############################################################################################"
echo

if [[ $SOURCE_MODE == "version" ]]; then
    checkLatestVersion
    read -p "Specify PostgreSQL version, eg $latestVersion... " PGVER
    echo Version specified:$PGVER
    downloadUrl="https://ftp.postgresql.org/pub/source/v$PGVER/postgresql-$PGVER.tar.gz"
elif [[ $SOURCE_MODE == "branch" ]]; then
    PGVER=$BRANCH_NAME
    echo "--> Building from branch: $BRANCH_NAME <--"
elif [[ $SOURCE_MODE == "commit" ]]; then
    PGVER=${COMMIT_HASH:0:8}
    echo "--> Building from commit: $COMMIT_HASH <--"
fi

read -p "Initialize database? " INIT_REPLY
read -p "Compile and install contrib extensions? " EXT_REPLY

INIT_DIR=$PWD
BINDIR=$HOME/postgres-$PGVER-`date +%F`
DATADIR=$BINDIR/data
PG_LOGFILE=$BINDIR/postgres.log
DEPLOY_LOGFILE=$BINDIR/INSTALL.LOG
DEPLOY_PGUSER=`whoami`
DEPLOY_PGPORT=`echo $RANDOM`
SOURCE_DIR="postgresql-$PGVER"
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
            libperl-dev libkrb5-dev libpam0g-dev libldap2-dev libicu-dev clang liblz4-dev libzstd-dev wget git 1>&2> /dev/null
        if [[ $SOURCE_MODE == "version" ]]; then
            downloadPostgresSrc
        else
            clonePostgresSrc
        fi
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

function clonePostgresSrc {
    local repo="https://github.com/postgres/postgres.git"

    if [[ -d $SOURCE_DIR ]]; then
        rm -rf $SOURCE_DIR
    fi

    if [[ $SOURCE_MODE == "branch" ]]; then
        echo "--> Cloning PostgreSQL source from branch: $BRANCH_NAME <--"
        git clone --branch $BRANCH_NAME --single-branch --depth 1 $repo $SOURCE_DIR
        if [[ $? -ne 0 ]]; then
            echo "^^^ ERROR: Clone failed ^^^"
            exit 1
        fi
    elif [[ $SOURCE_MODE == "commit" ]]; then
        echo "--> Cloning PostgreSQL source for commit: $COMMIT_HASH <--"
        git clone $repo $SOURCE_DIR
        if [[ $? -ne 0 ]]; then
            echo "^^^ ERROR: Clone failed ^^^"
            exit 1
        fi
        git -C $SOURCE_DIR checkout $COMMIT_HASH
        if [[ $? -ne 0 ]]; then
            echo "^^^ ERROR: Checkout of commit $COMMIT_HASH failed ^^^"
            exit 1
        fi
    fi

    extractCompilePostgres
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
        cd $SOURCE_DIR/contrib/$extension
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
    if [[ $SOURCE_MODE == "version" ]]; then
        if [[ ! -d $SOURCE_DIR ]]
        then
            tar xf postgresql-$PGVER.tar.gz
            if [[ $? -ne 0 ]]
            then
                echo "^^^ ERROR: Could not extract source files ^^^"
                exit 1
            fi
        else
            rm -rf $SOURCE_DIR
            tar xf postgresql-$PGVER.tar.gz
            if [[ $? -ne 0 ]]
            then
                echo "^^^ ERROR: Could not extract source files ^^^"
                exit 1
            fi
        fi
    fi

    if [[ $EXT_REPLY =~ ^(Y|y)$ ]]
    then
        AVAILABLE_EXTENSIONS=$(ls $SOURCE_DIR/contrib -m)
        read -p "Specify extensions to install from the following list: $(echo $AVAILABLE_EXTENSIONS) ... " EXTENSIONS
    fi

    cd $SOURCE_DIR/
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

parseArgs "$@"
printHeader
[[ $SOURCE_MODE == "version" ]] && verifyVersion
checkInstallStatus
