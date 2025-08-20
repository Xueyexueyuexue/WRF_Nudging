#!/bin/bash

OBSDIR=                    #location of upper air data
SRFDIR=                    #location of surface data
OUTDIR=                    #output directory	
obspre="$OBSDIR/OBS:"
sfcpre="$SRFDIR/SURFACE_OBS:"
outpre="$OUTDIR/C_OBS:"
rm -f $OUTDIR/C_OBS:*
for fil in `ls ${obspre}*`
do
#	echo ${fil}
	datestr=`echo ${fil} | cut -d ':' -f 2`
	echo ${datestr}
        filsfc="${sfcpre}${datestr}"
	filout="${outpre}${datestr}"
	echo "${fil} + ${filsfc} -> ${filout}"
	cat ${fil} ${filsfc} > ${filout}
done
