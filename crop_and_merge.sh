#!/bin/bash
if [ -z "$1" -o -z "$2" -o -z "$3" ]
then
    echo Usage: $0 input_file columns rows '[margin=120]' >&2
    exit 1
fi

INPUT=${1%%.pdf}
if [ ! -f "$INPUT.pdf" ]
then
    echo Not found: "$INPUT.pdf" >&2
    exit 2
fi
COLUMNS=$2
ROWS=$3

pdfinfo=$(pdfinfo -box ${INPUT}.pdf)
PAGES=$(grep '^Pages:' <<<"$pdfinfo" | cut -d ":" -f 2 | sed 's/ //g')
i=1
tmp=$(mktemp -d)
trap "rm -r $tmp" EXIT

psize=$(awk -v m=${4:-120} '
/^CropBox:/ { print int($4-$2-2*m), int($5-$3-2*m)}' <<<"$pdfinfo")
read pwidth pheight <<<"$psize"
width=$(($pwidth/$COLUMNS))
height=$(($pheight/$ROWS))
cropped=$tmp/cropped.pdf
pdfcrop --bbox "$(awk -v m=${4:-120} '
    /^CropBox:/ { print $2+m, $3+m, $4-m, $5-m}' <<<"$pdfinfo"
)" $INPUT.pdf $cropped

for y in $(seq $ROWS)
do
    yrev=$(($ROWS-$y))
    ytop=$(($height*(${yrev}+1)))
    ybottom=$(($height*$yrev))
    for x in $(seq $COLUMNS)
    do
        xleft=$(($width*(${x}-1)))
        xright=$(($width*$x))
        pdfcrop --clip --bbox "$xleft $ybottom $xright $ytop" $cropped "$tmp/${INPUT}_${y}_${x}.pdf"
    done
done

cd $tmp
for i in ${INPUT}_*.pdf
do
    f=${i##${INPUT}_}
    pdftk $i burst output "${INPUT}_part_%04d_$f"
done
pdftk ${INPUT}_part_*.pdf cat output ${INPUT}_kindle.pdf
cd -
mv $tmp/${INPUT}_kindle.pdf ${INPUT}_tmp.pdf
pdftk ${INPUT}_tmp.pdf cat 1-endW output ${INPUT}_kindle.pdf
rm ${INPUT}_tmp.pdf
