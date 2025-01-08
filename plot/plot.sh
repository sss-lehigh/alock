#!/bin/bash

for data in tput lat
do
    for nodes in 5 10 15 20 30 40 50
    do 
        for mode in top rand
        do
            for threads in 2 4 5 6 8 10 12
            do 
                path="test_results/n${nodes}/write/t${threads}/${mode}"
                python3 plot.py --save_dir "../${path}" --resfile "n${nodes}_t${threads}_${data}_result.csv" --exp ${data} --nodes ${nodes} --threads ${threads}
            done
        done
    done
done