#!/bin/bash

#cas or write
type=write
# top or rand
mode=rand 
#tput or lat
data=tput 
threads=1

path="results/${type}/${mode}/t${threads}"

python3 plot.py --save_dir "../${path}" --resfile '_result.csv' --exp ${data}