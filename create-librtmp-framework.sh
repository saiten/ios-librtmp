#!/bin/sh

FWNAME=librtmp

if [ ! -d lib ]; then
    echo "Please run build.sh."
    exit 1
fi

if [ -d $FWNAME.framework ]; then
    echo "Remove $FWNAME.framework"
    rm -rf $FWNAME.framework
fi

if [ "$1" == "dynamic" ]; then
    LIBTOOL_FLAGS="-dynamic -undefined dynamic_lookup -ios_version_min 8.0"
else
    LIBTOOL_FLAGS="-static"
fi


echo "Creating $FWNAME.framework"
mkdir -p $FWNAME.framework/Headers
libtool -no_warning_for_no_symbols $LIBTOOL_FLAGS -o $FWNAME.framework/$FWNAME -v lib/librtmp.a
cp -r include/$FWNAME/* $FWNAME.framework/Headers/
cp "librtmp-Info.plist" $FWNAME.framework/Info.plist
echo "Created $FWNAME.framework"

