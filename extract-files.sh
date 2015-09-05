#!/bin/sh

VENDOR=asus
DEVICE=a500kl

BASE=../../../vendor/$VENDOR/$DEVICE/proprietary
rm -rf $BASE/*

for FILE in `cat proprietary-blobs.txt | grep -v ^# | grep -v ^$ `; do
    DIR=`dirname $FILE`
    if [ ! -d $BASE/$DIR ]; then
        mkdir -p $BASE/$DIR
    fi
    cp ~/UL-ASUS_T00P-CN-11.4.6.94-user/system/$FILE $BASE/$FILE
done

./setup-makefiles.sh
