#!/bin/env bash

source "exp.conf"

user=${ssh_user}
machines=("apt177" "apt180" "apt157" "apt081" "apt129" "apt088" "apt174" "apt132" "apt086" "apt130" "apt142" "apt186" "apt068" "apt131" "apt158" "apt149" "apt083" "apt164" "apt145" "apt176" "apt076" "apt071" "apt152" "apt091" "apt138" "apt069" "apt173" "apt162" "apt156" "apt183" "apt178" "apt141" "apt175" "apt187" "apt136" "apt190" "apt179" "apt140" "apt154" "apt184" "apt163" "apt092" "apt192" "apt137" "apt072")
domain="apt.emulab.net"

 
if [[ "${topology}" -eq 1 ]]; then
    mode="top"
else
    mode="rand"
fi
path="results/n${num_nodes}/write/t${thread_count}/$mode"

mkdir -p ${path}
cd ${path}

# Shorten list of machines to only use the machines used for the experiment
machines=("${machines[@]:0:$num_nodes}")

for m in ${machines[@]}; do
    mkdir $m
    scp "${user}@$m.$domain":~/"n${num_nodes}_t${thread_count}_tput_result.csv" "./$m/"
    scp "${user}@$m.$domain":~/"n${num_nodes}_t${thread_count}_lat_result.csv" "./$m/"
done
