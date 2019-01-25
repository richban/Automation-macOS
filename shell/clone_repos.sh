#!/bin/sh

array=( "https://github.com/richban/tachikoma"
        "https://github.com/richban/behavioral.neuroevolution"  
	  )

for element in ${array[@]}
do
    echo "clonning $element"
    git clone $element $HOME/Developer/
done
