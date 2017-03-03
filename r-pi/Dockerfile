# dockerfile for rtx-link application on raspberry pi
FROM armv7/armhf-ubuntu:16.04
MAINTAINER Sam Hatchett <sam@citilogics.com>

RUN apt-get update && \
	apt-get -y install \
	libsqlite3-dev \
	cmake \
	libiodbc2-dev \
	tdsodbc \
	libboost-all-dev \
	libcurl4-openssl-dev \
	g++ \
	openssl \
	libssl-dev \
	git \
	curl \
	libcpprest-sdk

WORKDIR /opt

## install sqlite_modern dep
RUN git clone https://github.com/aminroosta/sqlite_modern_cpp.git \
	&& cp -R sqlite_modern_cpp/hdr/* /usr/local/include/ \
	&& cd /opt \
	&& rm -rf sqlite_modern_cpp

# install NODEJS - runtime for LINK frontend application
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
	apt-get -y install nodejs

# setup tds as odbc driver - allows connection to MSSQL hosts
COPY odbcinst.ini /etc/odbcinst.ini

COPY epanet-rtx epanet-rtx
WORKDIR /opt/epanet-rtx

## build LINK service (rtx-based tier-2 data synchronization service)
RUN cd examples/LINK/service/cmake && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make

# install node frontend application and dependencies
RUN cd examples/LINK/frontend &&\
	npm install

# copy the LINK-service app into the nodejs bundle
WORKDIR /opt/epanet-rtx/examples/LINK
RUN mkdir frontend/srv && mkdir frontend/srv/linux/ && mv service/cmake/build/bin/* frontend/srv/linux/

EXPOSE 8585
VOLUME /root/rtx_link
CMD [ "nodejs", "frontend/server.js" ]
