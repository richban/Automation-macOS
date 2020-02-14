#!/bin/sh

array=( "https://github.com/richban/tachikoma"
        "https://github.com/richban/behavioral.neuroevolution"
	  )

for element in ${array[@]}
do
    echo "clonning $element"
    # execute git from this directory
    git -C $HOME/Developer/ clone $element
done
