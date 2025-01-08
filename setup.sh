#!/bin/env bash

# 
# This file is used to setup a new cloudlab experiment with the needed prerequisites to run experiments. 
# 

source "exp.conf"

# Paths to remus directory and the name of the remus dependency script to run
remus_dir="../remus"
exe="cloudlab_depend.sh"

# Set internal field seperator based on machines list in exp.conf
IFS=','

for m in $machines; do
  ssh "${ssh_user}@$m.$domain" hostname &
done
wait

# Send install script 
for m in $machines; do
  scp -r "${remus_dir}/${exe}" "${ssh_user}@$m.$domain":~ &
done
wait

# run install script
for m in $machines; do
  ssh "${ssh_user}@$m.$domain" "bash ~/${exe}" &
done
wait

unset IFS

echo "Setup complete on all machines"