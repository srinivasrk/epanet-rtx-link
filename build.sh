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


while getopts rb:p: opt; do
	case "${opt}" in
		b)
			# set built type (dist,preflight)
			buildtype=$OPTARG
			;;
		p)
			# set platform (rpi,x86)
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
	echo "Usage: ${0} -b [dist,preflight] -p [rpi,x86] (-r)
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
	rpi) echo "Platform is raspberry-pi" ;;
	x86) echo "Platform is x86-64." ;;
	*) echo "Please specify platform type: [rpi,x86]" && exit 1 ;;
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
	rpi) plat_dir="r-pi" ;;
	x86) plat_dir="x86" ;;
esac
rsync -azhe ssh --progress ./${plat_dir}/* tmp/

# build the docker container
cd tmp

# build the binary using the dev environment.
docker rm rtx_link_build
docker build -t link-build-img -f build . && \
	docker create --name rtx_link_build link-build-img && \
	docker cp rtx_link_build:/usr/local/bin/link-server ./link-server

docker build -t rtx_link -f deploy .
if ! [[ -z "$runflag" ]]; then
	docker run -d --restart=always --name rtx_link -p 8585:8585 rtx_link
fi

echo "DONE"
