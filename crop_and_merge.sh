#!/bin/bash
if [ -z "$1" ]
then
    echo Usage: $0 input_file >&2
    exit 1
fi

INPUT=${1%%.pdf}
if [ ! -f "$INPUT.pdf" ]
then
    echo Not found: "$INPUT.pdf" >&2
    exit 2
fi

PAGES=$(pdfinfo ${INPUT}.pdf | grep Pages | cut -d ":" -f 2 | sed 's/ //g')
i=1
params=""
tmp=$(mktemp -d)
trap "rm -r $tmp" EXIT

pdfcrop --bbox '120 465 475 730' $INPUT.pdf $tmp/${INPUT}_A.pdf
pdfcrop --bbox '120 115 475 380' $INPUT.pdf $tmp/${INPUT}_B.pdf
cd $tmp
while [ $i -lt $PAGES ]; do
    pdftk A=${INPUT}_A.pdf B=${INPUT}_B.pdf cat A$i B$i output ${INPUT}_part_${i}.pdf
    i=$[$i+1]
done
i=1
while [ $i -lt $PAGES ]; do
    params="$params ${INPUT}_part_${i}.pdf"
    i=$[$i+1]
done
pdftk $params cat output ${INPUT}_kindle.pdf
cd -
mv $tmp/${INPUT}_kindle.pdf ${INPUT}_tmp.pdf
pdftk ${INPUT}_tmp.pdf cat 1-endW output ${INPUT}_kindle.pdf
rm ${INPUT}_tmp.pdf
