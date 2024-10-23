#!/bin/env bash

source "exp.conf"

user=${ssh_user}
machines=("apt152" "apt145" "apt190" "apt179" "apt192" "apt186" "apt148" "apt181" "apt161" "apt183" "apt154" "apt139" "apt147" "apt184" "apt178" "apt141" "apt163" "apt162" "apt164" "apt159")
domain="apt.emulab.net"

exe="main"

for m in "${machines[@]}"; do
  ssh "${user}@$m.$domain" sudo pkill -SIGTERM "${exe}"
done
