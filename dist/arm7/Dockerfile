# dockerfile for multistage build/deploy rtx-link application on arm
FROM citilogics/arm7-builder as builder

RUN ["cross-build-start"]

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

RUN ["cross-build-end"]


###############################
## ^^^ builder ^^^ ############
###############################
## vvv deploy vvvv ############
###############################


FROM resin/armv7hf-debian-qemu as deploy

RUN ["cross-build-start"]
WORKDIR /app
# this layer recycled from build:
RUN apt-get update && \
	apt-get install -y libiodbc2 tdsodbc openssl libsqlite3-dev curl

# install NODEJS - runtime for LINK frontend application
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash && \
	apt-get -y install nodejs

COPY odbcinst.ini /etc/odbcinst.ini

# copy the frontend and service binary
WORKDIR /opt/src
RUN curl -JLO https://github.com/OpenWaterAnalytics/epanet-rtx-link/archive/master.tar.gz \
		&& tar -xzf epanet-rtx-link-master.tar.gz \
		&& cd epanet-rtx-link-master \
		&&  cp -r frontend/* /app/

WORKDIR /app
RUN rm -rf /opt/src/*
COPY --from=builder /usr/local/bin/link-server /app/srv/linux/link-server

# install node frontend application and dependencies
RUN npm install
RUN npm run build

RUN ["cross-build-end"]

EXPOSE 3000
VOLUME /root/rtx_link
CMD [ "npm", "start" ]
