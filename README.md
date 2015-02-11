# doomkin/oracle Dockerfile

Oracle Database 11gR2 with SSH key access on Oracle Linux 6.6 Dockerfile for trusted Docker builds.

This [**Dockerfile**](https://github.com/doomkin/oracle/blob/master/Dockerfile) is a [trusted build](https://registry.hub.docker.com/u/doomkin/oracle/) of [Docker Registry](https://registry.hub.docker.com/).

### Base Docker Image

* [oraclelinux:6.6](https://github.com/_/oraclelinux)

### Installation
```
sudo docker pull doomkin/oracle
```

### Run with external Database storage
```
sudo docker run --name orac -it -P \
    -v /media/d2/oradata:/u02/oradata \
    -v /media/d2/dump:/u02/dump \
    doomkin/oracle
```

### Login into Container by SSH
```
ssh-agent -s
ssh-add ssh/id_rsa
ssh root@localhost -p `sudo docker port orac 22 | cut -d":" -f2`
```

### Create Database
```
dbca-create <SID>
```
### Print Oracle port
```
export ORACLE_PORT=`sudo docker port orac 1521 | cut -d":" -f2`
echo $ORACLE_PORT
```

### Print Oracle port
```
export ORACLE_PORT=`sudo docker port orac 1521 | cut -d":" -f2`
echo $ORACLE_PORT
```


### Login into Database
```
sqlplus "sys/oracle123@<SID> as sysdba"
```

### Delete Database
```
dbca-delete <SID>
```

### Build the image with only last layer to compress
```
echo "Build the Docker image"
sudo docker build -t="doomkin/oracle:source" .

echo "Create the Container with only last layer to compress"
sudo docker run --name orac doomkin/oracle:source
sudo docker stop orac

echo "Export the Container to file"
sudo docker export orac > oracle.tar

echo "Import the Container from file to the raw Docker image (without metadata)"
cat oracle.tar | sudo docker import - doomkin/oracle:raw
rm oracle.tar

echo "Remove the Container"
sudo docker rm orac

echo "List images (doomkin/oracle:source can be deleted)"
sudo docker images
```

### To restore metadata rebuild image with following Dockerfile
```
FROM doomkin/oracle:raw
	
COPY script /u01/app/oracle/home/bin
RUN chown oracle:dba /u01/app/oracle/home/bin/dbca-create; \
    chown oracle:dba /u01/app/oracle/home/bin/dbca-delete; \
    chmod 775 /u01/app/oracle/home/bin/dbca-create; \
    chmod 775 /u01/app/oracle/home/bin/dbca-delete

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
```
As a result, the size of the Docker image will be 5 GB
