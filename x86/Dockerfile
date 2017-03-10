# dockerfile for rtx-link application
FROM citilogics/dev-base:latest
MAINTAINER Sam Hatchett <sam@citilogics.com>

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
