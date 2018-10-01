FROM oraclelinux:7-slim

ENV ORACLE_BASE=/u01/app/oracle \
    ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe \
    ORACLE_SID=XE \
    INSTALL_FILE_1="oracle-xe-11.2.0-1.0.x86_64.rpm.zip" \
    INSTALL_DIR="$HOME/install" \
    CONFIG_RSP="xe.rsp" \
    RUN_FILE="runOracle.sh" \
    PWD_FILE="setPassword.sh" \
    CHECK_DB_FILE="checkDBStatus.sh"

ENV PATH=$ORACLE_HOME/bin:$PATH

COPY $INSTALL_FILE_1 $CONFIG_RSP $RUN_FILE $PWD_FILE $CHECK_DB_FILE $INSTALL_DIR/

# ------------------------------
# Install Oracle XE
# ------------------------------

RUN yum -y install unzip libaio bc initscripts net-tools openssl && \
    rm -rf /var/cache/yum && \
    cd $INSTALL_DIR && \
    unzip $INSTALL_FILE_1 && \
    rm $INSTALL_FILE_1 &&    \
    cat() { declare -A PROC=(["/proc/sys/kernel/shmmax"]=4294967295 ["/proc/sys/kernel/shmmni"]=4096 ["/proc/sys/kernel/shmall"]=2097152 ["/proc/sys/fs/file-max"]=6815744); [[ ${PROC[$1]} == "" ]] && /usr/bin/cat $* || echo ${PROC[$1]}; } && \
    free() { echo "Swap: 2048 0 2048"; } && \
    export -f cat free && \
    rpm -i Disk1/*.rpm &&    \
    unset -f cat free && \
    mkdir -p $ORACLE_BASE/scripts/setup && \
    mkdir $ORACLE_BASE/scripts/startup && \
    ln -s $ORACLE_BASE/scripts /docker-entrypoint-initdb.d && \
    mkdir $ORACLE_BASE/oradata && \
    chown -R oracle:dba $ORACLE_BASE && \
    mv $INSTALL_DIR/$CONFIG_RSP $ORACLE_BASE/ && \
    mv $INSTALL_DIR/$RUN_FILE $ORACLE_BASE/ && \
    mv $INSTALL_DIR/$PWD_FILE $ORACLE_BASE/ && \
    mv $INSTALL_DIR/$CHECK_DB_FILE $ORACLE_BASE/ && \
    ln -s $ORACLE_BASE/$PWD_FILE / && \
    cd $HOME && \
    rm -rf $INSTALL_DIR && \
    chmod ug+x $ORACLE_BASE/*.sh

HEALTHCHECK --interval=1m --start-period=5m \
   CMD "$ORACLE_BASE/$CHECK_DB_FILE" >/dev/null || exit 1

EXPOSE 1521 8080 5500

VOLUME ["$ORACLE_BASE/oradata"]

CMD exec $ORACLE_BASE/$RUN_FILE
