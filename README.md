# doomkin/oracle Dockerfile

Oracle Database 11gR2 with SSH key access on Oracle Linux 6.6 Dockerfile for trusted Docker builds.

This [**Dockerfile**](https://github.com/doomkin/oracle/blob/master/Dockerfile) is a [trusted build](https://registry.hub.docker.com/u/doomkin/oracle/) of [Docker Registry](https://registry.hub.docker.com/).

### Base Docker Image

* [oraclelinux:6.6](https://github.com/_/oraclelinux)

### Installation
```
sudo docker pull doomkin/oracle
```

### Run
```
sudo docker run --name orac -it -P \
    -v /media/d2/oradata:/u02/oradata \
    -v /media/d2/dump:/u02/dump \
    doomkin/oracle
```

### Login by SSH
```
ssh-agent -s
ssh-add ssh/id_rsa
ssh root@localhost -p `sudo docker port orac 22 | cut -d":" -f2`
```

### Keep last layer
```
sudo docker export orac > oracle.tar
cat oracle.tar | sudo docker import - doomkin/oracle:raw
```

### To restore metadata rebuild image with Dockerfile
```
FROM doomkin/oracle:raw
	
VOLUME ["/u02/oradata", "/u02/dump"]

EXPOSE 22 1521

CMD service sshd start; \
    export ORACLE_HOME=/u01/app/oracle/home; \
    export PATH=/u01/app/oracle/home/bin:$PATH; \
    su oracle -c "lsnrctl start LISTENER"; \
    bash
```
As a result, the size of the Docker image will be 5 GB
