#!/bin/bash

DEST=/volume1/backup/tvheadend
DATE=`date +%Y%m%d-%H%M`

tar -jcvf - \
    --exclude='.lock' \
    --exclude='tvheadend.pid' \
    /var/packages/tvheadend/target/bin/zap2xml.* \
    /var/packages/tvheadend/target/bin/tv_grab_file \
    /var/packages/tvheadend/target/cache \
    /var/packages/tvheadend/target/.xmltv \
    /var/packages/tvheadend/target/perl5 \
    /var/packages/tvheadend/target/.cpan \
    /var/packages/tvheadend/target/share/tvheadend/data/dvb-scan/atsc/ca-QC-* \
    /volume1/@appstore/tvheadend/var \
    > $DEST/tvheadend-backup-$DATE.tar.bz2
