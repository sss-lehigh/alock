#!/bin/bash

# #cas or write
# type=cas
# # top or rand
# mode=rand 
#tput or lat
data=tput 
# threads=16

for nodes in 2 4 6 8
do 
    for mode in top
    do
        # for threads in 1 2 4 6 7 8 9 10 12 16 20 22 24 28 30
        for threads in 8
        do 
            path="results/n${nodes}/write/t${threads}/${mode}"
            python3 plot.py --save_dir "../${path}" --resfile '_result.csv' --exp ${data} --nodes ${nodes} --threads ${threads}
        done
    done
done