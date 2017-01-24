# RTX-LINK Data Synchronization Utility

This docker build-script will build and deploy the RTX-LINK data syncronization tool on x86 or ARMx hardware, as a preflight/test or distributable build. 
See `build.sh` for usage.

To build/deploy on a raspberry pi device:

```
curl https://github.com/OpenWaterAnalytics/RTX-LINK/archive/master.zip > RTX-LINK-master.zip
unzip link.zip
cd RTX-LINK-master
./build.sh -p rpi -b dist -r
```
