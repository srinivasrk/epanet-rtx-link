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
        apt-get install -y openssl libsqlite3-dev curl gnupg gcc make automake autoconf libtool

WORKDIR /opt/dep-build

## build/install odbc connection dependencies
RUN curl -JLO https://github.com/openlink/iODBC/archive/v3.52.12.tar.gz && \
    tar -xzf iODBC-3.52.12.tar.gz && \
    cd iODBC-3.52.12 && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make && make install

RUN curl -JLO ftp://ftp.freetds.org/pub/freetds/stable/freetds-patched.tar.gz && \
    tar -xzf freetds-patched.tar.gz && \
    cd freetds-1.00.97 && \
    ./configure --with-iodbc=/usr --prefix=/usr --disable-libiconv && \
    make && make install

# install NODEJS - runtime for LINK frontend application
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash && \
        apt-get -y install nodejs

WORKDIR /app
RUN rm -rf /opt/dep-build

COPY odbcinst.ini /etc/odbcinst.ini

# copy the frontend and service binary
COPY frontend /app
COPY --from=builder /usr/local/bin/link-server /app/srv/linux/link-server

# install node frontend application and dependencies
RUN npm install
RUN npm run build

#<build_end>

EXPOSE 3000
VOLUME /root/rtx_link
CMD [ "npm", "start" ]
