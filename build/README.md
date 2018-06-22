# RTX-LINK Data Synchronization Utility

This build-script will build and deploy the RTX-LINK data syncronization tool on x86 or ARMx hardware, as a preflight/test or distributable build.
See `build.sh` for usage.

If you have a development setup with a common root repo directory, you can build/run the container with these options:
```
./build.sh -p x86 -b preflight -r
```

To build/run on a raspberry pi device:

```
curl -L https://github.com/OpenWaterAnalytics/RTX-LINK/archive/master.tar.gz > RTX-LINK-master.tar.gz
tar -xzf RTX-LINK-master.tar.gz
cd RTX-LINK-master
./build.sh -p arm -b dist
cd
mkdir link_vol # make local directory for link volume mount
docker run -d -v ${PWD}/link_vol:/root/rtx_link --restart=always --name rtx_link -p 8585:8585 rtx_link
```
