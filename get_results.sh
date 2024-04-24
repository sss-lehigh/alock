#!/bin/env bash

source "exp.conf"

user=${ssh_user}
machines=("apt070" "apt071" "apt112" "apt073" "apt103" "apt106" "apt120" "apt113" "apt081" "apt102")
domain="apt.emulab.net"

path="results/rand/t${thread_count}/"

mkdir -p ${path}
cd ${path}

for m in ${machines[@]}; do
    mkdir $m
    scp "${user}@$m.$domain":~/tput_result.csv "./$m/"
    scp "${user}@$m.$domain":~/lat_result.csv "./$m/"
done
