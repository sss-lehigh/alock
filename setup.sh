#!/bin/env bash

source "exp.conf"

remus_dir="../remus-internal"
exe="cloudlab_depend.sh"

user=${ssh_user}
machines=("apt152" "apt156" "apt144" "apt153" "apt138" "apt147" "apt163" "apt164" "apt157" "apt148")
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