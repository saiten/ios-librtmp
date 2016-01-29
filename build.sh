#!/bin/sh

DEVELOPER=$(xcode-select --print-path)

SDK_VERSION=$(xcrun -sdk iphoneos --show-sdk-version)
SDK_VERSION_MIN=7.0

DEVICE_PLATFORM="${DEVELOPER}/Platforms/iPhoneOS.platform"
SIMULATOR_PLATFORM="${DEVELOPER}/Platforms/iPhoneSimulator.platform"
DEVICE_SDK="${DEVICE_PLATFORM}/Developer/SDKs/iPhoneOS${SDK_VERSION}.sdk"
SIMULATOR_SDK="${SIMULATOR_PLATFORM}/Developer/SDKs/iPhoneSimulator${SDK_VERSION}.sdk"

TVSDK_VERSION=$(xcrun -sdk appletvos --show-sdk-version)

TV_PLATFORM="${DEVELOPER}/Platforms/AppleTVOS.platform"
TVSIMULATOR_PLATFORM="${DEVELOPER}/Platforms/AppleTVSimulator.platform"
TV_SDK="${TV_PLATFORM}/Developer/SDKs/AppleTVOS${TVSDK_VERSION}.sdk"
TVSIMULATOR_SDK="${TVSIMULATOR_PLATFORM}/Developer/SDKs/AppleTVSimulator${TVSDK_VERSION}.sdk"

IOS_OPENSSL=`cd ../OpenSSL-for-iPhone;pwd`

for OPT in $*
do
    case $OPT in
        '--openssl_dir' )
            IOS_OPENSSL=`cd $2; pwd`
            shift2
            ;;
    esac
    shift
done

echo "openssl_dir : ${IOS_OPENSSL}"

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
	XCFLAGS="-O0 -isysroot ${SDK} -I${IOS_OPENSSL}/include -arch $ARCH -miphoneos-version-min=${SDK_VERSION_MIN} -fembed-bitcode" \
	XLDFLAGS="-isysroot ${SDK} -L${IOS_OPENSSL}/lib -arch $ARCH -miphoneos-version-min=${SDK_VERSION_MIN} " \
	make SYS=darwin

	make SYS=darwin prefix="/tmp/librtmp-$ARCH" install &> "/tmp/librtmp-$ARCH.log"

	popd
}

## create iOS lib

build "armv7"  "$DEVICE_PLATFORM" "$DEVICE_SDK"
build "armv7s" "$DEVICE_PLATFORM" "$DEVICE_SDK"
build "arm64"  "$DEVICE_PLATFORM" "$DEVICE_SDK"
build "i386"   "$SIMULATOR_PLATFORM" "$SIMULATOR_SDK"
build "x86_64" "$SIMULATOR_PLATFORM" "$SIMULATOR_SDK"

# remove temporary dir
rm -rf rtmpdump-*

# create universal binary
mkdir lib
xcrun lipo \
	/tmp/librtmp-armv7/lib/librtmp.a \
	/tmp/librtmp-armv7s/lib/librtmp.a \
	/tmp/librtmp-arm64/lib/librtmp.a \
	/tmp/librtmp-i386/lib/librtmp.a \
	/tmp/librtmp-x86_64/lib/librtmp.a \
	-create -output lib/librtmp.a

## create tvOS lib

build "arm64"  "$TV_PLATFORM" "$TV_SDK"
build "x86_64" "$TVSIMULATOR_PLATFORM" "$TVSIMULATOR_SDK"

# remove temporary dir
rm -rf rtmpdump-*

# create universal binary
xcrun lipo \
	/tmp/librtmp-arm64/lib/librtmp.a \
	/tmp/librtmp-x86_64/lib/librtmp.a \
	-create -output lib/librtmp-tvOS.a

# copy include files
mkdir include
cp -r /tmp/librtmp-i386/include/librtmp include/

# copy license
cp rtmpdump/librtmp/COPYING .

