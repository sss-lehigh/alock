#!/bin/bash

# #cas or write
# type=cas
# # top or rand
# mode=rand 
#tput or lat
data=tput 
# threads=16

for nodes in 45
do 
    for mode in top rand
    do
        for threads in 1
        do 
            path="results/n${nodes}/write/t${threads}/${mode}"
            python3 plot.py --save_dir "../${path}" --resfile "n${nodes}_t${threads}_${data}_result.csv" --exp ${data} --nodes ${nodes} --threads ${threads}
        done
    done
done