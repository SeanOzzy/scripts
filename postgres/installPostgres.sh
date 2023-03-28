#!/bin/bash

echo "############################################################################################"
echo "# This script is designed to build the PostgreSQL database version you specify from source #"
echo "#                                                                                          #"
echo "#                                 Tested for Amazon Linux 2                                 #"
echo "############################################################################################"
echo
read -p "Specify PostgreSQL version, eg 15.2... " PGVER
read -p "Initialize database? " INIT_REPLY
BINDIR=$HOME/postgres-$PGVER-`date +%F`
DATADIR=$BINDIR/data
PGUSER=`whoami`
PGPORT=`echo $RANDOM`

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
if curl --head --silent --fail https://ftp.postgresql.org/pub/source/v$PGVER/postgresql-$PGVER.tar.gz 1>&2> /dev/null;
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
        wget https://ftp.postgresql.org/pub/source/v$PGVER/postgresql-$PGVER.tar.gz
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
                                        echo "--> Database initialization completed <--"
                                        echo "--> Database can be started using: "
                                        echo "          $BINDIR/bin/pg_ctl -D $DATADIR -l logfile start"
                                        echo "--> Connect to database using: "
                                        echo "          psql -h localhost -p $PGPORT postgres"
                                        exit 0
                        fi
        fi
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
                        cd postgresql-$PGVER/
                        echo
                        echo "--> Running configure <--"
                        ./configure --prefix=$BINDIR --with-pgport=$PGPORT --with-openssl --with-perl --with-tcl --with-ossp-uuid --with-libxml --with-pam --with-ldap \
                        --with-krb-srvnam=whatever --with-gssapi --enable-debug 1>&2> /dev/null
                if [[ $? -ne 0 ]]
                        then
                                echo "^^^ ERROR: Executing configure failed ^^^"
                                exit 1
                        else
                                echo
                                echo "--> Compiling source <--"
                                make 1>&2> /dev/null
                        if [[ $? -ne 0 ]]
                                then
                                        echo "^^^ ERROR: Compile failed ^^^"
                                        exit 1
                                else
                                        echo
                                        echo "--> Installing from source <--"
                                        sudo make install 1>&2> /dev/null
                                        if [[ $? -ne 0 ]]
                                                then
                                                        echo "^^^ ERROR: Install from source failed ^^^"
                                                        make clean 1>&2> /dev/null
                                                        exit 1
                                                else
                                                        make clean 1>&2> /dev/null
                                                        echo "--> Resetting permissions <--"
                                                        sudo chown -R $PGUSER $BINDIR
                                                        echo "--> Binaries installed to: $BINDDIR/bin <--"
                                                        echo "--> Install complete <--"
                                                                if [[ $INIT_REPLY =~ ^(Y|y)$ ]]
                                                                then
                                                                        initializeDatabase
                                                                else
                                                                        echo "^^^ WARNING: Database not intialized, run $BINDIR/bin/initdb -D $DATADIR later if required. ^^^"
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
