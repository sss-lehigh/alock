#!/bin/env bash

source "exp.conf"

user=${ssh_user}
machines=("apt183" "apt192" "apt175" "apt180" "apt182" "apt178" "apt181" "apt176" "apt186" "apt184" 
          "apt187" "apt177" "apt076" "apt190" "apt118" "apt153" "apt072" "apt098" "apt162" "apt145" 
          "apt071" "apt158" "apt140" "apt185" "apt149" "apt156" "apt082" "apt073" "apt152" "apt081" 
          "apt129" "apt088" "apt106" "apt083" "apt164" "apt120" "apt070" "apt173" "apt069" "apt179" 
          "apt086" "apt066" "apt131" "apt146" "apt091" "apt191" "apt142" "apt157" "apt141" "apt154")

domain="apt.emulab.net"

 
if [[ "${topology}" -eq 1 ]]; then
    mode="top"
else
    mode="rand"
fi
path="test_results/n${num_nodes}/write/t${thread_count}/$mode"

mkdir -p ${path}
cd ${path}

# Shorten list of machines to only use the machines used for the experiment
machines=("${machines[@]:0:$num_nodes}")

for m in ${machines[@]}; do
    mkdir $m
    scp "${user}@$m.$domain":~/"n${num_nodes}_t${thread_count}_tput_result.csv" "./$m/"
    scp "${user}@$m.$domain":~/"n${num_nodes}_t${thread_count}_lat_result.csv" "./$m/"
done
