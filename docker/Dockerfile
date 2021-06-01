FROM alpine:latest
ARG JD_SHELL_URL=https://gitee.com/djxiao71/dj77.git
ARG JD_SHELL_BRANCH=main
ARG JD_SCRIPTS_URL=git@gitee.com:djxiao71/jd_scripts.git
ARG JD_SCRIPTS_BRANCH=master
ARG KEY="-----BEGIN RSA PRIVATE KEY-----\nMIIEogIBAAKCAQEAu9wQJ7GjnZ4Pz4ce0MzsH6VpvbMfihIwowmEak/CJETgA6ib\nbGQH8VAfkDuEr5ylM0aZCJFh66B8Kpw5DXAwJSAMoG/xjXtFKvr+c3c3ouGdvyrT\nIxeYnlLYtmqm/6Gyxhjrs6vtMJkqYeZJafMgkzpgGnkZjBBnJ8btxSWBGOMH5hfk\nTw4Vn7dGwCkrra1plVLjzAUZoRbiEbduXIicczjx01rHUn+1/PYR0etgrHFU3fuA\njsT9jaOtN1xmjYqO//gC/o6NFcWTNFN9dcFyoH7ie51jL78DNHv/UOEi8VPQX3o/\nk99phKxc7SkW5Xrl5u6KV7tqHBysQvjwazO/DwIDAQABAoIBAEz0vk10cMEdwf5S\nrOX+PHBOU73ZRf9Kqk/vkyX13GL9MANvq5PAepx5JSTxrM4/zlDuB7zByao7yQGv\nk5OUtLRQp7uFgB9kMxaDUX89hDYeVH++bFXA0c1xxMMdd6HavKB4Dv5AXN7+r6UB\nMGvNpDeLv1i46SU+hvN9g2OylGr7yOw5kU9ZEYEC+awpcVJ+bXm7gflZ8YxW3PWS\nl0VLtaaCsjSTWZ19WI3PqGDOysHM1tJ+8PRqC6Ryhx1BMg4W6OeiJ2WYTRYUqfKt\nKvWRE+SIbXIyhEyzAFKDHfd/i7/gMWreO9SM6F6UjkuSUASIvVp8oeliDNTx8whw\nfiDOdGECgYEA+GF0Hy6FH6rlVyD9GXjTNS5u8ffSbSEwD9S2vFVk8UoAU7gxEfLH\n8qK/hYlDBjumVQObjoLYTBi/F5pt9bmXnf8ev3NZ/4ccr3PJnwvLOhrYu/g5I22E\nz47MFkFYbaqQhJrF3kRSQdcdR6tLtTiWZY9ol8RtEFSsHdDywjDf5T8CgYEAwZ9V\noYNDGuCIkDBjLol98ukUN1qLa/05F0CQUiPLMtb7yxKwqa9UiT3QdX1PpgXiddyD\nU9blx4bRbBaBm+M5qCgFIH5dI5+ipMRLYGKyBLW0eRW5VtoGbufSQLSM/ynBok13\nX/CPoo64xgQUD+Z193n5pdB6DMeh6Zd5gdn5ojECgYAeWJG+aYmcN93zSjWCEjAD\n1Ft7tqJ/8MkVdhCpa+l8TWVC1UMxhS8GpvmtT/rfXRRSWLF9tODGU1Oth5GdrwIm\nLJBOJcK+JHzNtuDQTLmUrMkEFiys9ml+jlzC71LleyxS9zHrmP9Pyf9qzTPfvT0q\nxV2rBTWqBB5POkMelKgWMwKBgCIopAjMiYgyWKVng/fv1cKHEEP7u2Ef2XSatVto\naS7c8qsO7w/gmL9lomM36ldV7m/wqVKfNQaQaF3zUoZX/hIGjXEAGhpwzVbYMpwc\njV97Vw2NoZcK+9uRFmzH7aAOk9S4afkJDa4WE88LZSaw99rjMAHq171tcsktKgiY\nlgvhAoGAN7q3fKLPj32GA46UhG1WkFDA0EEOheAkMbskZMwxoN0QUyaarWHh0qu8\nfQEKlJoa34AxTT+aUtmrsXbUAVaVKrCDpV7gnCee2c3MK2F5UguvVBH5JsFtUHsX\nM+ZhAgfJzilYvU83GBL1uo/iqkaC38JwvRJ+PZXRHk0i8xUg6wM=\n-----END RSA PRIVATE KEY-----"

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    LANG=zh_CN.UTF-8 \
    SHELL=/bin/bash \
    PS1="\u@\h:\w \$ " \
    JD_DIR=/jd \
    ENABLE_HANGUP=true \
    ENABLE_WEB_PANEL=true 
WORKDIR $JD_DIR
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk update -f \
    && apk upgrade \
    && apk --no-cache add -f bash \
                             coreutils \
                             diffutils \
                             git \
                             wget \
                             curl \
                             nano \
                             tzdata \
                             perl \
                             openssh-client \
                             nodejs-lts \
                             npm \
    && echo "========= 修改时区 =========" \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && echo "========= 部署SSH KEY =========" \
    && mkdir -p /root/.ssh \
    && echo -e $KEY > /root/.ssh/id_rsa \
    && chmod 600 /root/.ssh/id_rsa \
    && ssh-keyscan gitee.com > /root/.ssh/known_hosts \
    && echo "====Git clone和安装PM2 =====" \
    && git clone -b $JD_SHELL_BRANCH $JD_SHELL_URL $JD_DIR \
    && cd $JD_DIR/panel \
    && npm config set registry https://registry.npm.taobao.org \
    && npm install \
    && npm install -g pm2 \
    && echo "========= 创建软链接 =========" \
    && ln -sf $JD_DIR/jd.sh /usr/local/bin/jd \
    && ln -sf $JD_DIR/jd.sh /usr/local/bin/task \
    && ln -sf $JD_DIR/git_pull.sh /usr/local/bin/git_pull \
    && ln -sf $JD_DIR/git_pull.sh /usr/local/bin/update \
    && ln -sf $JD_DIR/rm_log.sh /usr/local/bin/rm_log \
    && ln -sf $JD_DIR/rm_log.sh /usr/local/bin/rmlog \
    && ln -sf $JD_DIR/export_sharecodes.sh /usr/local/bin/export_sharecodes \
    && ln -sf $JD_DIR/export_sharecodes.sh /usr/local/bin/codes \
    && ln -sf $JD_DIR/csv.sh /usr/local/bin/csv \
    && cp -f $JD_DIR/docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh \
    && chmod 777 /usr/local/bin/docker-entrypoint.sh \
    && chmod 777 $JD_DIR/*.sh \
    && echo "========= 清理 =========" \
    && rm -rf /root/.npm /var/cache/apk/*
ENTRYPOINT ["docker-entrypoint.sh"]
