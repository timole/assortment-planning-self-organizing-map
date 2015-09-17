#!/bin/sh

NAME=$1
TITLE=$2
NUM=$3
RAND=$NUM
XDIM=$4
YDIM=$5
RLEN1=$6
R1=$7
RLEN2=$8
R2=$9

TRAINING_FILE=$NAME-sompack-training.txt
MAP_FILE=$NAME-$TITLE-$NUM-sompack-map.cod
VISUAL_FILE=$NAME-$TITLE-$NUM-sompack-visual.txt
QERROR_FILE=$NAME-$TITLE-$NUM-sompack-qerror.txt
echo "Running som_pak for training file $TRAINING_FILE with num $NUM,rand $RAND, RLEN1 $RLEN1 R1 $R1 RLEN2 $RLEN2 R2 $R2, title $TITLE"
echo "Output file: $VISUAL_FILE"
echo

randinit -din $TRAINING_FILE -cout $MAP_FILE -xdim $XDIM -ydim $YDIM -topol hexa -neigh bubble -rand $RAND
som_pak-3.1/vsom.exe -din $TRAINING_FILE -cin $MAP_FILE -cout $MAP_FILE -rlen $RLEN1 -alpha 0.05 -radius $R1
vsom.exe -din $TRAINING_FILE -cin $MAP_FILE -cout $MAP_FILE -rlen $RLEN2 -alpha 0.02 -radius $R2
qerror -din $TRAINING_FILE -cin $MAP_FILE > $QERROR_FILE
cat $QERROR_FILE
vcal -din $TRAINING_FILE -cin $MAP_FILE -cout $NAME-$NUM-sompack-map-cal.cod -numlabs 0
visual -din $TRAINING_FILE -cin $NAME-$NUM-sompack-map-cal.cod -dout $VISUAL_FILE
echo SOM visual file ready: $VISUAL_FILE
