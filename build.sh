#!/bin/sh

IOS_VERSION=5.0
DEVICE_PLATFORM="/Developer/Platforms/iPhoneOS.platform"
SIMULATOR_PLATFORM="/Developer/Platforms/iPhoneSimulator.platform"
DEVICE_SDK="${DEVICE_PLATFORM}/Developer/SDKs/iPhoneOS${IOS_VERSION}.sdk"
SIMULATOR_SDK="${SIMULATOR_PLATFORM}/Developer/SDKs/iPhoneSimulator${IOS_VERSION}.sdk"

IOS_OPENSSL=`cd ../ios-openssl;pwd`

rm -rf include lib

rm -rf /tmp/librtmp-*
rm -f /tmp/librtmp-*.log

if [ ! -d rtmpdump ]; then
	git clone git://git.ffmpeg.org/rtmpdump rtmpdump
else
	pushd .
	cd rtmpdump
	git pull
	popd
fi

# armv6
cp -r rtmpdump rtmpdump-armv6

pushd .
cd rtmpdump-armv6/librtmp

patch -u hashswf.c < ../../hashswf-ios.patch

CROSS_COMPILE="${DEVICE_PLATFORM}/Developer/usr/bin/" \
XCFLAGS="-isysroot ${DEVICE_SDK} -I${IOS_OPENSSL}/include -arch armv6" \
XLDFLAGS="-isysroot ${DEVICE_SDK} -L${IOS_OPENSSL}/lib -arch armv6 " \
make SYS=darwin &> /tmp/librtmp-armv6.log
make SYS=darwin prefix=/tmp/librtmp-armv6 install &> /tmp/librtmp-armv6.log

popd

# armv7
cp -r rtmpdump rtmpdump-armv7

pushd .
cd rtmpdump-armv7/librtmp

patch -u hashswf.c < ../../hashswf-ios.patch

CROSS_COMPILE="${DEVICE_PLATFORM}/Developer/usr/bin/" \
XCFLAGS="-isysroot ${DEVICE_SDK} -I${IOS_OPENSSL}/include -arch armv7" \
XLDFLAGS="-isysroot ${DEVICE_SDK} -L${IOS_OPENSSL}/lib -arch armv7" \
make SYS=darwin &> /tmp/librtmp-armv7.log
make SYS=darwin prefix=/tmp/librtmp-armv7 install &> /tmp/librtmp-armv7.log

popd

# i386
cp -r rtmpdump rtmpdump-i386

pushd .
cd rtmpdump-i386/librtmp

patch -u hashswf.c < ../../hashswf-ios.patch

CROSS_COMPILE="${SIMULATOR_PLATFORM}/Developer/usr/bin/" \
XCFLAGS="-isysroot ${SIMULATOR_SDK} -I${IOS_OPENSSL}/include -arch i386" \
XLDFLAGS="-isysroot ${SIMULATOR_SDK} -L${IOS_OPENSSL}/lib -arch i386" \
make SYS=darwin &> /tmp/librtmp-i386.log
make SYS=darwin prefix=/tmp/librtmp-i386 install &> /tmp/librtmp-i386.log

popd

# remove temporary dir
rm -rf rtmpdump-*

#

mkdir include
cp -r /tmp/librtmp-i386/include/librtmp include/

# create universal binary
mkdir lib
lipo \
	/tmp/librtmp-armv6/lib/librtmp.a \
	/tmp/librtmp-armv7/lib/librtmp.a \
	/tmp/librtmp-i386/lib/librtmp.a \
	-create -output lib/librtmp.a	
	

