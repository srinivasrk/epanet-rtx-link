# RTX-LINK Data Synchronization Utility

This docker build-script will build and deploy the RTX-LINK data syncronization tool on x86 or ARMx hardware, as a preflight/test or distributable build. 
See `build.sh` for usage.

To build/run on a raspberry pi device:

```
curl -L https://github.com/OpenWaterAnalytics/RTX-LINK/archive/master.zip > RTX-LINK-master.zip
unzip RTX-LINK-master.zip
cd RTX-LINK-master
./build.sh -p rpi -b dist -r
```

To ensure that LINK runs when the PI boots:

```
## write a new service for the LINK docker container:
sudo bash -c 'cat << EOF > /etc/systemd/system/docker-rtx_link_server.service
[Unit]
Description=RTX-LINK container
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker start -a rtx_link
ExecStop=/usr/bin/docker stop -t 2 rtx_link

[Install]
WantedBy=default.target
EOF'

sudo systemctl daemon-reload
sudo systemctl start docker-rtx_link_server.service
sudo systemctl enable docker-rtx_link_server.service


```
