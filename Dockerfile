#
# doomkin/oracle Dockerfile
#
# Based on:
# https://registry.hub.docker.com/_/oraclelinux/
#

FROM oraclelinux:6.6
MAINTAINER Pavel Nikitin <p.doomkin@ya.ru>

ADD ssh/id_rsa.pub /root/.ssh/authorized_keys

COPY software /u01/app/oracle/software
COPY response /u01/app/oracle/response

RUN \
echo "Oracle Database 11gR2 installation on Oracle Linux 6.6"; \
    groupadd oinstall; \
    groupadd dba; \
    useradd -g oinstall -G dba oracle; \
echo "Create a directory structure"; \
    mkdir -p /u01/app/oracle/software; \
    chown -R oracle:oinstall /u01; \
    mkdir -p /u02/oradata; \
    mkdir -p /u02/dump; \
    chown -R oracle:oinstall /u02; \
    touch /etc/fstab; \
echo "Install package and OS requirements"; \
    yum install -y oracle-rdbms-server-11gR2-preinstall wget mc; \
echo "Build 7za"; \
    cd /tmp; \
    wget http://downloads.sourceforge.net/project/p7zip/p7zip/9.38.1/p7zip_9.38.1_src_all.tar.bz2; \
    tar jxf p7zip_9.38.1_src_all.tar.bz2; \
    cd /tmp/p7zip_9.38.1; \
    make; \
    /tmp/p7zip_9.38.1/install.sh; \
echo "Unzip software"; \
    cd /u01/app/oracle/software; \
    7za x *1of*.zip; \
    7za x *2of*.zip; \
echo "Run Installer in silent mode"; \
    su oracle -c "umask 022; \
        unset ORACLE_SID; unset ORACLE_HOME; unset TNS_ADMIN; \
        /u01/app/oracle/software/database/runInstaller -waitforcompletion -silent -noconfig -ignoreSysPrereqs -ignorePrereq \
            -responseFile /u01/app/oracle/response/db_install.rsp \
            "FROM_LOCATION=/u01/app/oracle/software/database/stage/products.xml""; \
    /u01/app/oraInventory/orainstRoot.sh; \
    /u01/app/oracle/home/root.sh; \
echo "Run NetCA in silent mode"; \
    su oracle -c "umask 022; /u01/app/oracle/home/bin/netca /silent /responsefile /u01/app/oracle/response/netca.rsp"; \
echo "Configure openssh-server"; \
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config; \
    sed -i 's/#PermitRootLogin without-password/PermitRootLogin without-password/' /etc/ssh/sshd_config; \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd; \
    chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys; \
    mkdir -p /home/oracle/.ssh; \
    cp -u /root/.ssh/authorized_keys /home/oracle/.ssh; \
    chown -R oracle:dba /home/oracle/.ssh; \
echo "Cleanup"; \
    rm -fr /u01/app/oracle/software; \
    rm -fr /tmp/*; \
    yum reinstall -y glibc-common; \
    yum clean all

RUN \
    echo "Configure Environment"; \
    echo "export LC_ALL=en_US.UTF-8" >> /etc/profile.d/oracle.sh; \
    echo "export NLS_LANG=AMERICAN_AMERICA.CL8MSWIN1251" >> /etc/profile.d/oracle.sh; \
    echo "export PATH=/u01/app/oracle/home/bin:$PATH" >> /etc/profile.d/oracle.sh; \
    echo "export ORACLE_HOME=/u01/app/oracle/home" >> /etc/profile.d/oracle.sh; \
    chmod 755 /etc/profile.d/oracle.sh

VOLUME /u02/oradata /u02/dump

EXPOSE 22 1521

CMD service sshd start; \
    chown -R oracle:dba /u02; \
    sed -i -E "s/HOST = [^)]+/HOST = $HOSTNAME/g" /u01/app/oracle/home/network/admin/listener.ora; \
    sed -i -E "s/HOST = [^)]+/HOST = $HOSTNAME/g" /u01/app/oracle/home/network/admin/tnsnames.ora; \
    export PATH=/u01/app/oracle/home/bin:$PATH; \
    export ORACLE_HOME=/u01/app/oracle/home; \
    su oracle -c "lsnrctl start LISTENER"; \
    su oracle -c "dbstart ${ORACLE_HOME}"; \
    su - oracle
