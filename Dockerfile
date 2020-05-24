#
# doomkin/oracle Dockerfile
#
# Based on:
# https://registry.hub.docker.com/_/oraclelinux/
#

FROM oraclelinux:6.6
MAINTAINER Pavel Nikitin

# Oracle Database 11gR2 installation on Oracle Linux 6.6
RUN groupadd dba; \
    useradd -g dba oracle; \
    mkdir -p /u01/app/oracle/software; \
    chown -R oracle:dba /u01; \
    mkdir -p /u02/oradata; \
    mkdir -p /u02/dump; \
    chown -R oracle:dba /u02; \
    touch /etc/fstab; \
    yum install -y oracle-rdbms-server-11gR2-preinstall wget mc sudo

# Build 7za
RUN cd /tmp; \
    wget http://downloads.sourceforge.net/project/p7zip/p7zip/9.38.1/p7zip_9.38.1_src_all.tar.bz2; \
    tar jxf p7zip_9.38.1_src_all.tar.bz2; \
    cd /tmp/p7zip_9.38.1; \
    make; \
    /tmp/p7zip_9.38.1/install.sh

# Oracle installation files
COPY software /u01/app/oracle/software
COPY response /u01/app/oracle/response

# Unzip Oracle installation files
RUN cd /u01/app/oracle/software; \
    7za x *1of*.zip; \
    7za x *2of*.zip

# Run Installer in silent mode
USER oracle
RUN umask 022; \
    /u01/app/oracle/software/database/runInstaller -waitforcompletion -silent -noconfig -ignoreSysPrereqs -ignorePrereq \
      -responseFile /u01/app/oracle/response/db_install.rsp \
      "FROM_LOCATION=/u01/app/oracle/software/database/stage/products.xml" \
      "ORACLE_HOSTNAME=$HOSTNAME"

# After install
USER root
RUN /u01/app/oraInventory/orainstRoot.sh; \
    /u01/app/oracle/home/root.sh

# Run NetCA in silent mode
USER oracle
RUN umask 022; \
    /u01/app/oracle/home/bin/netca /silent /responsefile /u01/app/oracle/response/netca.rsp

# Configure openssh-server, Cleanup, Startup
USER root
ADD ssh/id_rsa.pub /root/.ssh/authorized_keys
RUN sed 's|PasswordAuthentication yes|PasswordAuthentication no|' /etc/ssh/sshd_config; \
    sed 's|#PermitRootLogin without-password|PermitRootLogin without-password|' /etc/ssh/sshd_config; \
    sed 's|session\s*required\s*pam_loginuid.so|session optional pam_loginuid.so|g' -i /etc/pam.d/sshd; \
    chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys; \
    mkdir -p /home/oracle/.ssh; \
    cp -u /root/.ssh/authorized_keys /home/oracle/.ssh; \
    chown -R oracle:dba /home/oracle/.ssh; \
echo "Cleanup"; \
    rm -fr /u01/app/oracle/software; \
    rm -fr /tmp/*; \
    yum reinstall -y glibc-common; \
    yum clean all; \
echo "Configure Startup"; \
    echo 'service sshd start' >> /etc/rc.local; \
    echo 'export LC_ALL=en_US.UTF-8' >> /etc/rc.local; \
    echo 'export NLS_LANG=AMERICAN_AMERICA.CL8MSWIN1251' >> /etc/rc.local; \
    echo 'export PATH=/u01/app/oracle/home/bin:$PATH' >> /etc/rc.local; \
    echo 'export ORACLE_HOME=/u01/app/oracle/home' >> /etc/rc.local; \
    echo 'sudo -u oracle /bin/sh -c "lsnrctl start LISTENER"' >> /etc/rc.local; \
    echo 'sudo -u oracle /bin/sh -c "dbstart ${ORACLE_HOME}"' >> /etc/rc.local

VOLUME /u02/oradata /u02/dump

EXPOSE 22 1521

CMD /etc/rc.local; bash
