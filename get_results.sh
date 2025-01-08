#!/bin/env bash

source "exp.conf"
 
if [[ "${stream_type}" -eq 1 ]]; then
    mode="top"
else
    mode="rand"
fi
path="test_results/n${num_nodes}/write/t${thread_count}/$mode"

mkdir -p ${path}
cd ${path}

# Shorten list of machines to only use the machines used for the experiment
IFS=',' read -r -a node_array <<< "$machines"
machines=$(IFS=','; echo "${node_array[*]:0:$num_nodes}")
IFS=","

for m in $machines; do
    mkdir $m
    scp "${ssh_user}@$m.$domain":~/"n${num_nodes}_t${thread_count}_tput_result.csv" "./$m/"
    scp "${ssh_user}@$m.$domain":~/"n${num_nodes}_t${thread_count}_lat_result.csv" "./$m/"
done
