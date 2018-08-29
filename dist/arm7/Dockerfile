# dockerfile for multistage build/deploy rtx-link application on arm
FROM resin/armv7hf-debian-qemu as builder

RUN ["cross-build-start"]

# this layer is shared with deploy:
RUN apt-get update && \
	apt-get install -y libiodbc2 tdsodbc openssl libsqlite3-dev curl

RUN apt-get update && \
	apt-get install -y \
	g++ \
	make \
	libiodbc2-dev \
	libcurl4-openssl-dev \
	libssl-dev \
	git \
	llvm clang \
	wget

## build / install boost
ARG boost_version=1.63.0
ARG boost_dir=boost_1_63_0
ENV boost_version ${boost_version}

RUN wget http://downloads.sourceforge.net/project/boost/boost/${boost_version}/${boost_dir}.tar.gz

RUN tar xfz ${boost_dir}.tar.gz \
    && rm ${boost_dir}.tar.gz \
    && cd ${boost_dir} \
    && ./bootstrap.sh \
    && ./b2 cxxflags=-fPIC --without-python --prefix=/usr -j 4 link=static runtime-link=shared install \
    && cd .. && rm -rf ${boost_dir} && ldconfig


RUN printf "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list && apt-get update && apt-get -t jessie-backports install "cmake"

WORKDIR /opt

RUN mkdir /opt/src

### install cpprestsdk library
RUN git clone https://github.com/Microsoft/cpprestsdk.git casablanca \
	&& cd casablanca/Release \
	&& sed -e 's/ -Wcast-align//g' -i CMakeLists.txt \
	&& mkdir build.release \
	&& cd build.release \
	&& cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=0 -DBUILD_SAMPLES=0 -DBUILD_SHARED_LIBS=0 -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
	&& make \
	&& make install

## install sqlite_modern dep
RUN cd /opt/src \
	&& git clone https://github.com/aminroosta/sqlite_modern_cpp.git \
	&& cp -R sqlite_modern_cpp/hdr/* /usr/local/include/ \
	&& cd /opt/src \
	&& rm -rf sqlite_modern_cpp

## install cpprestsdk convenience framework
RUN curl -L -o granada.tar.gz https://github.com/webappsdk/granada/archive/1.56.0.tar.gz \
	&& tar -xzf granada.tar.gz \
	&& cp -R granada-1.56.0/Release/include/granada /usr/local/include \
	&& cd /opt/src \
	&& rm -rf granada

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
