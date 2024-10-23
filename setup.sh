#!/bin/env bash

# 
# This file is used to setup a new cloudlab experiment with the needed prerequisites to run experiments. 
# 

source "exp.conf"

remus_dir="../remus"
exe="cloudlab_depend.sh"

user=${ssh_user}
machines=("apt152" "apt145" "apt190" "apt179" "apt192" "apt186" "apt148" "apt181" "apt161" "apt183" "apt154" "apt139" "apt147" "apt184" "apt178" "apt141" "apt163" "apt162" "apt164" "apt159")
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