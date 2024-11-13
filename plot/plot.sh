#!/bin/bash

# #cas or write
# type=cas
# # top or rand
# mode=rand 
#tput or lat
data=tput 
# threads=16

for nodes in 5 10 15 20 30 40 50
do 
    for mode in top rand
    do
        for threads in 3 4 5 6
        do 
            path="test_results/n${nodes}/write/t${threads}/${mode}"
            python3 plot.py --save_dir "../${path}" --resfile "n${nodes}_t${threads}_${data}_result.csv" --exp ${data} --nodes ${nodes} --threads ${threads}
        done
    done
done