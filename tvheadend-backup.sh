#!/bin/bash

DEST=/volume1/backup/tvheadend
DATE=`date +%Y%m%d-%H%M`

tar -C /var/packages/tvheadend/target -jcvf - \
    --exclude='.lock' \
    --exclude='tvheadend.pid' \
    cache var \
    bin/tv_grab_file bin/zap2xml.pl bin/zap2xml.sh perl5 .cpan .xmltv \
    share/tvheadend/data/dvb-scan/atsc/ca-QC-saint-jean-sur-richelieu \
    > $DEST/tvheadend-backup-$DATE.tar.bz2
