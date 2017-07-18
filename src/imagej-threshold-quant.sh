#! /bin/bash
## ImageJ threshold quantification processing script
## David R. Hill

## set directory containing unprocessed images
TIFDIR=../data/raw_img/
## set output directory
RESULTDIR=../results/
## set ImageJ macro
IJM=./thresholdmeasure.ijm

## make folder to deposit results
mkdir -p $RESULTDIR

## warn the user this may take some time
echo 'Computing fluorescence intensity values...'
echo 'This may take a while. Now would be a good time for a coffee break.'

## create data file and add header line
echo 'Filename	Area	Mean	Min	Max	Median' > $RESULTDIR/threshold_results.txt

## process all files in TIFDIR and output to threshold_results.txt
## note that files were downsized to reduce filesize and
## facillitate sharing of the example dataset available on github
for file in $TIFDIR/*.tif
do
    imagej -i $file -b $IJM | sed '1,4d' | cut -f 2-7 >> $RESULTDIR/threshold_results.txt
done

## print first 10 lines and message indicating completion
echo 'IMAGE PROCESSING FINISHED'
echo 'Printing first 10 lines of output'
echo '#################################'
head $RESULTDIR/threshold_results.txt
