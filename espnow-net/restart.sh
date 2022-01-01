#!/bin/bash

for dirname in 10.42*; do
    echo $dirname
    cd $dirname
    for filename in *.bas; do
        URL="http://${dirname}/${filename}"
        echo $URL
        cd download
        wget $URL 
        cd ..
    done
    cd ..
    URL="http://${dirname}/config?restart=yes"
    curl -m 1 $URL &
done
