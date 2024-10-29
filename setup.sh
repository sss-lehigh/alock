#!/bin/env bash

# 
# This file is used to setup a new cloudlab experiment with the needed prerequisites to run experiments. 
# 

source "exp.conf"

remus_dir="../remus"
exe="cloudlab_depend.sh"

user=${ssh_user}
machines=("apt177" "apt180" "apt157" "apt081" "apt129" "apt088" "apt174" "apt132" "apt086" "apt130" "apt142" "apt186" "apt068" "apt131" "apt158" "apt149" "apt083" "apt164" "apt145" "apt176" "apt076" "apt071" "apt152" "apt091" "apt138" "apt069" "apt173" "apt162" "apt156" "apt183" "apt178" "apt141" "apt175" "apt187" "apt136" "apt190" "apt179" "apt140" "apt154" "apt184" "apt163" "apt092" "apt192" "apt137" "apt072")
domain="apt.emulab.net"

for m in ${machines[@]}; do
  ssh "${user}@$m.$domain" hostname
done

# Send install script 
for m in ${machines[@]}; do
  scp -r "${remus_dir}/${exe}" "${user}@$m.$domain":~
done

# run install script
for m in ${machines[@]}; do
  ssh "${user}@$m.$domain" bash ${exe}
done