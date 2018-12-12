#!/bin/bash
## ImageJ threshold quantification processing script
## David R. Hill

## set directory containing unprocessed images
VSIDIR=$1
## set output directory
RESULTDIR=$2
## set ImageJ macro
IJM=./src/threshold_RFU_measure.ijm
DIRNAME=${VSIDIR%/}
EXPERIMENT=${DIRNAME##*/}

## make folder to deposit results
mkdir -p $RESULTDIR

echo "[START] converting VSI files in $VSIDIR to tif files for experiment $EXPERIMENT"

java -jar ./bin/ij.jar --headless -ijpath ./bin -batch ./src/vis2tif.ijm $VSIDIR

echo "[FINISHED] converting VSI files to TIF"

## warn the user this may take some time
echo '[START] Computing fluorescence intensity values...'
echo 'This may take a while. Now would be a good time for a coffee break.'

## create data file and add header line
echo 'Filename	Area	Mean	Min	Max	Median' > $RESULTDIR/$EXPERIMENT\_threshold_results.txt

## process all files in VSIDIR and output to threshold_results.txt
start_count=$(ls -d $VSIDIR/*.tif | wc -l)
for file in $VSIDIR/*.tif
do
    ## count number of tif files remaining
    count=$(ls -d $VSIDIR/*.tif | wc -l)
    echo "$count of $start_count tif files remaining in $VSIDIR"

    ## run imagej measurement script
    java -jar ./bin/ij.jar --headless -ijpath ./bin -batch $IJM $file | sed '1d' | cut -f 2-7 >> $RESULTDIR/$EXPERIMENT\_threshold_results.txt

    ## delete tif file to save disk space
    rm $file
done

## print first 10 lines and message indicating completion
echo '[FINISHED] Computing fluorescence intensity values'
echo '[IMAGE PROCESSING FINISHED]'
echo 'Printing first 10 lines of output'
echo '#################################'
head $RESULTDIR/$EXPERIMENT\_threshold_results.txt
