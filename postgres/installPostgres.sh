#!/bin/bash

echo "############################################################################################"
echo "# This script is designed to build the PostgreSQL database version you specify from source #"
echo "# The main purpose of this script to to quickly test community versions as a result        #"
echo "# the directory locations and settings are not necessarilly PRODUCATION ready              #"
echo "#                                                                                          #"
echo "#                                 Tested for Amazon Linux 2                                #"
echo "############################################################################################"
echo
read -p "Specify PostgreSQL version, eg 16.1... " PGVER
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

#function installDevelopment {
#if [[ "$( echo "$PGVER == dev" |bc)" =1 ]]
#	then downloadUrl="https://ftp.postgresql.org/pub/snapshot/dev/postgresql-snapshot.tar.gz"
#	else downloadUrl="https://ftp.postgresql.org/pub/source/v$PGVER/postgresql-$PGVER.tar.gz"
#fi
#}

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
#if curl --head --silent --fail https://ftp.postgresql.org/pub/source/v$PGVER/postgresql-$PGVER.tar.gz 1>&2> /dev/null;
        then
                echo
                echo "--> Postgres version $PGVER available in community source. <--"
        else
                echo
                echo "^^^ ERROR: We cannot find the version you specific, please verify you entered the correct version number. ^^^"
                exit 2
fi
}

function installPrereqs {
read -p "Do you wish to continue and install the required packages? " RESPONSE
if [[ $RESPONSE =~ ^([Y|y])$ ]]
        then
                echo
                echo "--> Installing required packages <--"
                sudo yum install gcc bison readline-devel zlib-devel sysstat strace stress iotop.noarch perf netperf \
                tcpdump nc wireshark perl-Tk-devel python-devel tcl-devel perl-ExtUtils flex-devel kernel-devel gdb \
                openssl-devel perl-core pam-devel libxml2-devel openldap-devel uuid-devel libicu-devel clang-devel lz4-devel libzstd-devel \
                git make automake libtool pkgconfig libaio-devel mariadb-devel openssl-devel mysql-devel libsystemd-dev -y 1>&2> /dev/null
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
        #wget https://ftp.postgresql.org/pub/source/v$PGVER/postgresql-$PGVER.tar.gz
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
                        echo "^^^ WARNING: Target directory for database intialization exists ^^^"
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
                                        # exit 0
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
if [[ -d !postgresql-$PGVER ]]
        then
                echo
        else
                rm -rf postgresql-$PGVER
                tar xf postgresql-$PGVER.tar.gz
        if [[ $? -ne 0 ]]
                then
                        echo "^^^ ERROR: Could not extract source files ^^^"
                        exit 1
                else
                        if [[ $EXT_REPLY =~ ^(Y|y)$ ]]
                                then
                                AVAILABLE_EXTENSIONS=$(ls postgresql-$PGVER/contrib -m)
                                read -p "Specify extensions to install from the following list: $(echo $AVAILABLE_EXTENSIONS) ... " EXTENSIONS
                        fi
                        cd postgresql-$PGVER/
                        echo
                        echo "--> Running configure <--"
                        #./configure --prefix=$BINDIR --with-pgport=$DEPLOY_PGPORT --with-openssl --with-perl --with-tcl --with-ossp-uuid --with-libxml --with-pam --with-ldap \
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
                                                        echo "--> Binaries installed to: $BINDDIR/bin <--"
                                                        echo "--> Install complete <--"
                                                                if [[ $INIT_REPLY =~ ^(Y|y)$ ]]
                                                                then
                                                                        cd $INIT_DIR
                                                                        initializeDatabase
                                                                else
                                                                        echo "^^^ WARNING: Database not intialized, run $BINDIR/bin/initdb -D $DATADIR later if required. ^^^"
                                                                        cd $INIT_DIR
                                                                        exit 0
                                                                fi
                                        fi
                                fi
                        fi
                fi
fi
}

verifyVersion
checkInstallStatus
