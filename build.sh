#!/bin/bash

echo "
██████╗ ████████╗██╗  ██╗    
██╔══██╗╚══██╔══╝╚██╗██╔╝    
██████╔╝   ██║    ╚███╔╝     
██╔══██╗   ██║    ██╔██╗     
██║  ██║   ██║   ██╔╝ ██╗    
╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝    
                             
██╗     ██╗███╗   ██╗██╗  ██╗
██║     ██║████╗  ██║██║ ██╔╝
██║     ██║██╔██╗ ██║█████╔╝ 
██║     ██║██║╚██╗██║██╔═██╗ 
███████╗██║██║ ╚████║██║  ██╗
╚══════╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
"


# 
# specify the base image with "-p" platform switch
# default is 
# arm=FROM armv7/armhf-ubuntu:yakkety
# x86=FROM ubuntu:yakkety


while getopts rb:p: opt; do
	case "${opt}" in
		b)
			# set built type (dist,preflight)
			buildtype=$OPTARG
			;;
		p)
			# set platform (arm,x86)
			platform=$OPTARG
			;;
		r)
			# run flag
			runflag="TRUE"
			;;
		\?)
      		echo "Invalid option: -$OPTARG" >&2
      		exit 1
      		;;
      	:)
      		echo "Option -$OPTARG requires an argument." >&2
      		exit 1
      		;;
	esac
done

if [[ -z "$buildtype" ]] || [[ -z "$platform" ]]; then
	echo "Usage: ${0} -b [dist,preflight] -p [arm,x86] (-r)
	-b build-type
	-p platform-type
	-r run-after-build
	"
	exit 1
fi


shift $(($OPTIND-1))

# check build type argument validity
case "$buildtype" in 
	dist) echo "Build type is dist" ;;
	preflight) echo "Build type is preflight. Using local assets." ;;
	*) echo "Please specify build type: [dist,preflight]" && exit 1 ;;
esac

# check platform argument validity
case "$platform" in 
	arm) echo "Platform is arm" ;;
	x86) echo "Platform is x86-64." ;;
	*) echo "Please specify platform type: [arm,x86]" && exit 1 ;;
esac

# make temp directory for build assets
rm -rf tmp
mkdir tmp

# determine build type
case "$buildtype" in
	preflight) 
	# preflight build assumes local repositories that share a root directory
	# with this script's containing directory
	rsync -azhe ssh --exclude '.git' --exclude 'build/cmake/build' --cvs-exclude "../epanet-rtx/" tmp/epanet-rtx
	;;
	dist)
	# dist assumes you want to download assets from the web.
	git clone https://github.com/OpenWaterAnalytics/epanet-rtx.git tmp/epanet-rtx
	;;
esac

# which docker file to use
case "$platform" in
	arm) base_img="armv7/armhf-ubuntu:yakkety"
		 tds_path="arm-linux-gnueabihf" 
		 ;;
	x86) base_img="ubuntu:yakkety" 
	     tds_path="x86_64-linux-gnu"
	     ;;
esac

# replace base image declaration in dockerfile
sed "s|<base_image>|${base_img}|" templates/Dockerfile.template > tmp/Dockerfile
sed "s|<tds_path>|${tds_path}|" templates/odbcinst.ini.template > tmp/odbcinst.ini

# build the docker container
cd tmp

# build the binary using the dev environment.
docker rm rtx_link
docker build -t rtx_link .

if ! [[ -z "$runflag" ]]; then
	docker run -d --restart=always --name rtx_link -p 8585:8585 rtx_link
fi

echo "DONE"
