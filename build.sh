#!/bin/sh

DEVELOPER=$(xcode-select --print-path)
SDK_VERSION=$(xcrun -sdk iphoneos --show-sdk-version)
SDK_VERSION_MIN=5.1

DEVICE_PLATFORM="${DEVELOPER}/Platforms/iPhoneOS.platform"
SIMULATOR_PLATFORM="${DEVELOPER}/Platforms/iPhoneSimulator.platform"
DEVICE_SDK="${DEVICE_PLATFORM}/Developer/SDKs/iPhoneOS${SDK_VERSION}.sdk"
SIMULATOR_SDK="${SIMULATOR_PLATFORM}/Developer/SDKs/iPhoneSimulator${SDK_VERSION}.sdk"
IOS_OPENSSL=`cd ../OpenSSL-for-iPhone;pwd`

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

	perl -i -pe 's|^AR=\$\(CROSS_COMPILE\)ar|AR=xcrun ar|' librtmp/Makefile
	patch -p0 < ../librtmp-ios.patch

    cd librtmp

	CROSS_COMPILE="${DEVELOPER}/usr/bin/" \
	XCFLAGS="-O0 -isysroot ${SDK} -I${IOS_OPENSSL}/include -arch $ARCH " \
	XLDFLAGS="-isysroot ${SDK} -L${IOS_OPENSSL}/lib -arch $ARCH -miphoneos-version-min=${SDK_VERSION_MIN} " \
	make SYS=darwin

	make SYS=darwin prefix="/tmp/librtmp-$ARCH" install &> "/tmp/librtmp-$ARCH.log"

	popd
}

build "armv7" "$DEVICE_PLATFORM" "$DEVICE_SDK"
build "armv7s" "$DEVICE_PLATFORM" "$DEVICE_SDK"
build "arm64" "$DEVICE_PLATFORM" "$DEVICE_SDK"
build "i386" "$SIMULATOR_PLATFORM" "$SIMULATOR_SDK"
build "x86_64" "$SIMULATOR_PLATFORM" "$SIMULATOR_SDK"

# remove temporary dir
rm -rf rtmpdump-*

# copy include files
mkdir include
cp -r /tmp/librtmp-i386/include/librtmp include/

# create universal binary
mkdir lib
xcrun lipo \
	/tmp/librtmp-armv7/lib/librtmp.a \
	/tmp/librtmp-armv7s/lib/librtmp.a \
	/tmp/librtmp-arm64/lib/librtmp.a \
	/tmp/librtmp-i386/lib/librtmp.a \
	/tmp/librtmp-x86_64/lib/librtmp.a \
	-create -output lib/librtmp.a

