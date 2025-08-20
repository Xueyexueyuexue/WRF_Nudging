#!/bin/bash

COBSDIR=                     #location of c_obs
OUTDIR=                      #output directory
obspre="$COBSDIR/C_OBS:"
filout="$OUTDIR/rda_obs"

rm -rf ${filout}
touch ${filout}

for fil in `ls ${obspre}*`
do
	echo "${fil} +> ${filout}"
	cat ${fil} >> ${filout}
done
