#!/bin/env bash

source "exp.conf"

user=${ssh_user}
machines=("apt152" "apt145" "apt190" "apt179" "apt192" "apt186" "apt148" "apt181" "apt161" "apt183" "apt154" "apt139" "apt147" "apt184" "apt178" "apt141" "apt163" "apt162" "apt164" "apt159")
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
