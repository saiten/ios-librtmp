#!/bin/sh

DEVELOPER="/Applications/Xcode.app/Contents/Developer"
SDK_VERSION="6.0"

DEVICE_PLATFORM="${DEVELOPER}/Platforms/iPhoneOS.platform"
SIMULATOR_PLATFORM="${DEVELOPER}/Platforms/iPhoneSimulator.platform"
DEVICE_SDK="${DEVICE_PLATFORM}/Developer/SDKs/iPhoneOS${SDK_VERSION}.sdk"
SIMULATOR_SDK="${SIMULATOR_PLATFORM}/Developer/SDKs/iPhoneSimulator${SDK_VERSION}.sdk"
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

# build

build()
{
	ARCH=$1
	PLATFORM=$2
	SDK=$3
	
	cp -r rtmpdump "rtmpdump-$ARCH"

	pushd .

	cd "rtmpdump-$ARCH"

	patch -p0 < ../librtmp-ios.patch

    cd librtmp

	CROSS_COMPILE="${PLATFORM}/Developer/usr/bin/" \
	XCFLAGS="-O0 -isysroot ${SDK} -I${IOS_OPENSSL}/include -arch $ARCH " \
    XLDFLAGS="-isysroot ${SDK} -L${IOS_OPENSSL}/lib -arch $ARCH " \
    make SYS=darwin &> "/tmp/librtmp-$ARCH.log"
    make SYS=darwin prefix="/tmp/librtmp-$ARCH" install &> "/tmp/librtmp-$ARCH.log"

	popd
}

build "armv7" "$DEVICE_PLATFORM" "$DEVICE_SDK"
build "armv7s" "$DEVICE_PLATFORM" "$DEVICE_SDK"
build "i386" "$SIMULATOR_PLATFORM" "$SIMULATOR_SDK"

# remove temporary dir
rm -rf rtmpdump-*

# copy include files
mkdir include
cp -r /tmp/librtmp-i386/include/librtmp include/

# create universal binary
mkdir lib
lipo \
	/tmp/librtmp-armv7/lib/librtmp.a \
	/tmp/librtmp-armv7s/lib/librtmp.a \
	/tmp/librtmp-i386/lib/librtmp.a \
	-create -output lib/librtmp.a

