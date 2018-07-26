FROM citilogics/builder-base:latest as builder

WORKDIR /opt

RUN git clone https://github.com/OpenWaterAnalytics/epanet-rtx.git \
        && cd epanet-rtx \
        && git checkout dev

WORKDIR /opt/epanet-rtx

## build LINK service (rtx-based tier-2 data synchronization service)
RUN cd examples/LINK/service/cmake && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && make install

###############################
## ^^^ builder ^^^ ############
###############################
## vvv deploy vvvv ############
###############################

FROM ubuntu:bionic as deploy

#<build_start>

# this layer recycled from build:
RUN apt-get update && \
        apt-get install -y libiodbc2 tdsodbc openssl libsqlite3-dev curl gnupg

# install NODEJS - runtime for LINK frontend application
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash && \
        apt-get -y install nodejs

COPY odbcinst.ini /etc/odbcinst.ini

# copy the frontend and service binary
COPY frontend /app
COPY --from=builder /usr/local/bin/link-server /app/srv/linux/link-server

WORKDIR /app

# install node frontend application and dependencies
RUN npm install
RUN npm run build

#<build_end>

EXPOSE 3000
VOLUME /root/rtx_link
CMD [ "npm", "start" ]
