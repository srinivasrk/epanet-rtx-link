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
# arm=FROM arm64v8/ubuntu:artful
# x86=FROM ubuntu:artful


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
	echo "Usage: ${0} -b [dist,preflight] -p [arm,x86,cross] (-r)
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
	cross) echo "Cross-build for arm on x86 using QEMU." ;;
	*) echo "Please specify platform type: [arm,x86,cross]" && exit 1 ;;
esac

# make temp directory for build assets
rm -rf tmp
mkdir tmp

# determine build type
case "$buildtype" in
	preflight)
	# preflight build assumes local repositories that share a root directory
	# with this script's containing directory
	rsync -azhe ssh --cvs-exclude --exclude '.git' --exclude 'build/cmake/build' ../../epanet-rtx/ tmp/epanet-rtx
	;;
	dist)
	# dist assumes you want to download assets from the web.
	git clone https://github.com/OpenWaterAnalytics/epanet-rtx.git tmp/epanet-rtx
	;;
esac

rsync -azhe ssh --cvs-exclude --exclude 'node_modules' --exclude '.git' ../frontend/ tmp/link-frontend

# which docker file to use
case "$platform" in
	arm) base_img="arm64v8/ubuntu:artful"
		 tds_path="arm-linux-gnueabihf"
		 ;;
	x86) base_img="ubuntu:artful"
	     tds_path="x86_64-linux-gnu"
	     ;;
	cross) base_img="resin/armv7hf-debian-qemu"
	       tds_path="arm-linux-gnuabihf"
	       ;;
esac

# replace base image declaration in dockerfile
sed "s|<base_image>|${base_img}|" templates/Dockerfile.template > tmp/Dockerfile
sed "s|<tds_path>|${tds_path}|" templates/odbcinst.ini.template > tmp/odbcinst.ini

case "$platform" in
    x86)    sed -i '.bak' 's/#<non-jessie>//' tmp/Dockerfile
            ;;
    cross)  sed -i '.bak' 's/#<build_start>/RUN ["cross-build-start"]/' tmp/Dockerfile
            sed -i '.bak' 's/#<build_end>/RUN ["cross-build-end"]/' tmp/Dockerfile
						sed -i '.bak' 's/#<jessie-backports>//' tmp/Dockerfile
            ;;
esac

# build the docker container
cd tmp

# build the binary using the dev environment.
docker rm rtx-link
docker build -t rtx-link .

if ! [[ -z "$runflag" ]]; then
	docker run -d --restart=always --name rtx_link -p 3000:3000 rtx_link
fi

echo "DONE"
