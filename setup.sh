#!/bin/env bash

# 
# This file is used to setup a new cloudlab experiment with the needed prerequisites to run experiments. 
# 

source "exp.conf"

remus_dir="../remus"
exe="cloudlab_depend.sh"

user=${ssh_user}
machines=("apt183" "apt192" "apt175" "apt180" "apt182" "apt178" "apt181" "apt176" "apt186" "apt184" 
          "apt187" "apt177" "apt076" "apt190" "apt118" "apt153" "apt072" "apt098" "apt162" "apt145" 
          "apt071" "apt158" "apt140" "apt185" "apt149" "apt156" "apt082" "apt073" "apt152" "apt081" 
          "apt129" "apt088" "apt106" "apt083" "apt164" "apt120" "apt070" "apt173" "apt069" "apt179" 
          "apt086" "apt066" "apt131" "apt146" "apt091" "apt191" "apt142" "apt157" "apt141" "apt154")
domain="apt.emulab.net"

for m in ${machines[@]}; do
  ssh "${user}@$m.$domain" hostname &
done
wait

# Send install script 
for m in ${machines[@]}; do
  scp -r "${remus_dir}/${exe}" "${user}@$m.$domain":~ &
done
wait

# run install script
for m in ${machines[@]}; do
  ssh "${user}@$m.$domain" "bash ~/${exe}" &
done
wait

echo "Setup complete on all machines"