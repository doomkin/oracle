#
# doomkin/oracle Dockerfile
#
# Based on:
# https://github.com/doomkin/oraclelinux
#

# Pull base image
FROM doomkin/oraclelinux
MAINTAINER Pavel Nikitin <p.doomkin@ya.ru>

# Copy distributive
COPY install /opt/install
COPY response /opt/response

# Install Oracle Database Server
RUN \
echo "Extracting distributive..."; \
    cd /opt/install; \
    unzip -x *1of2.zip; \
    unzip -x *2of2.zip; \
    rm -fr /opt/install/*.zip; \
echo "Creating Oracle user and groups..."; \
    groupadd oinstall; \
    groupadd dba; \
    useradd -g oinstall -G dba oracle; \
echo "Prepare folders..."; \
    mkdir -p /opt/oracle; \
    mkdir -p /opt/oraInventory; \
    chown -R oracle:oinstall /opt/oracle; \
	chown -R oracle:oinstall /opt/oraInventory; \
	chown -R oracle:oinstall /opt/response; \
echo "Installing Oracle Database Server..."; \
     su oracle -c "umask 022; \
     unset ORACLE_SID; unset ORACLE_HOME; unset TNS_ADMIN; \
     /opt/install/database/runInstaller -waitforcompletion -silent -noconfig -ignoreSysPrereqs -ignorePrereq \
         -responseFile /opt/response/db_install.rsp \
         "FROM_LOCATION=/opt/install/database/stage/products.xml" \
         "ORACLE_HOSTNAME=localhost""; \
    /opt/oraInventory/orainstRoot.sh; \
    /opt/oracle/home/root.sh; \
echo "Runnig NetCA in silent mode..."; \
    su oracle -c "umask 022; /opt/oracle/home/bin/netca /silent /responsefile /opt/response/netca.rsp"; \
    sed -i -E "s/HOST = [^)]+/HOST = localhost/g" /opt/oracle/home/network/admin/listener.ora; \
echo "Creating script to run DBCA in silent mode..."; \
    echo "/opt/oracle/home/bin/dbca -silent -responsefile /opt/response/dbca.rsp" > /opt/response/dbca-silent.sh; \
    chmod 775 /opt/response/dbca-silent.sh; \
echo "Configuring..."; \
    echo "export LANGUAGE=en_US.UTF-8" >> /home/oracle/.bashrc; \
    echo "export LANG=en_US.UTF-8" >> /home/oracle/.bashrc; \
    echo "export LC_ALL=en_US.UTF-8" >> /home/oracle/.bashrc; \
    echo "export ORACLE_HOME=/opt/oracle/home" >> /home/oracle/.bashrc; \
    echo "export PATH=/opt/oracle/home/bin:$PATH" >> /home/oracle/.bashrc; \
    mkdir -p /home/oracle/.ssh; \
    cp -u /root/.ssh/authorized_keys /home/oracle/.ssh; \
    chowm -R oracle:dba /home/oracle/.ssh; \
echo "Cleaning..."; \
    rm -fr /opt/install; \
    rm -rf /var/cache/*

# Expose sshd port
EXPOSE 22 1521

# Startup
CMD service sshd start; \
    export ORACLE_HOME=/opt/oracle/home; \
    export PATH=/opt/oracle/home/bin:$PATH; \
    su oracle -c "lsnrctl start LISTENER"; \
    bash
