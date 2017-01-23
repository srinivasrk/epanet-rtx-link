# dockerfile for rtx-link application
FROM ubuntu:16.04
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
	curl

# build microsoft's cpprestsdk - library for rest i/o
RUN git clone https://github.com/Microsoft/cpprestsdk.git casablanca && \
	cd casablanca/Release && \
	sed -e 's/ -Wcast-align//g' -i CMakeLists.txt  && \
	mkdir build.release && \
	cd build.release && \
	cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SAMPLES=0 -DBUILD_TESTS=0 && \
	make && make install

# install NODEJS - runtime for LINK frontend application
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
	apt-get -y install nodejs

# setup tds as odbc driver - allows connection to MSSQL hosts
COPY odbcinst.ini /etc/odbcinst.ini

# build and install RTX library with LINK-service (duplication engine without UI)
RUN git clone https://github.com/OpenWaterAnalytics/epanet-rtx epanet-rtx && \
	cd epanet-rtx && git checkout dev && \
	cd examples/LINK-service/cmake && mkdir build && cd build && \
	cmake .. && make

# install node frontend application and dependencies
RUN git clone https://github.com/OpenWaterAnalytics/RTX-LINK rtx-link && \
	cd rtx-link &&\
	npm install

# copy the LINK-service app into the nodejs bundle
RUN cp epanet-rtx/examples/LINK-service/cmake/build/bin/* rtx-link/srv/linux/

EXPOSE 8585 3131
VOLUME /root/rtx_link
CMD [ "nodejs", "rtx-link/server.js" ]
