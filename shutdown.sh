#!/bin/env bash

source "exp.conf"

user=${ssh_user}
machines=("apt081" "apt117" "apt125" "apt126" "apt128" "apt162" "apt092" "apt107" "apt122" "apt086" "apt181" "apt173" "apt153" "apt120" "apt123" "apt137" "apt147" "apt192" "apt110" "apt191" "apt111" "apt118" "apt174" "apt113" "apt082" "apt083" "apt073" "apt088" "apt142" "apt158" "apt149" "apt157" "apt096" "apt146" "apt109" "apt114" "apt076" "apt075" "apt150" "apt175" "apt141" "apt190" "apt154" "apt176" "apt156" "apt121" "apt091" "apt185" "apt119" "apt112")
domain="apt.emulab.net"


exe="main"

for m in "${machines[@]}"; do
  ssh "${user}@$m.$domain" sudo pkill -SIGTERM "${exe}"
done
