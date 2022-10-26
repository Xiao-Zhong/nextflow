#!/bin/bash

BBDUK=/SOFTWARE/bbmap-38.96/bbduk.sh
ADAPTERS=/SOFTWARE/bbmap-38.96/resources/adapters.fa
INPUT="fastqs"
OUTPUT="fastqs-trimmed"
#BBDUKOPTS="ref=$ADAPTERS ktrim=r k=23 mink=11 hdist=1 tpe tbo"
BBDUKOPTS="ref=$ADAPTERS ktrim=r k=23 mink=11 hdist=1 forcetrimleft=$1 tpe tbo"

MERGED=`ls $INPUT/*_R1_*.gz`

mkdir -p $OUTPUT

echo "Running bbduk on all samples sequentially.."

for i in $MERGED; do
  R1=`basename $i`
  R2=${R1%R1_001.fastq.gz}R2_001.fastq.gz
  SN=${R1%_L000_R1_001.fastq.gz}
  $BBDUK in1=$INPUT/$R1 in2=$INPUT/$R2 \
    out1=$OUTPUT/$R1 out2=$OUTPUT/$R2 $BBDUKOPTS \
    stats=$OUTPUT/$SN.trimmed.log
done

echo "Done!"
