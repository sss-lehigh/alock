#!/bin/env bash
ssh adb321@apt152.apt.emulab.net pkill -9 main
ssh adb321@apt145.apt.emulab.net pkill -9 main
ssh adb321@apt190.apt.emulab.net pkill -9 main
ssh adb321@apt179.apt.emulab.net pkill -9 main
ssh adb321@apt192.apt.emulab.net pkill -9 main
ssh adb321@apt186.apt.emulab.net pkill -9 main
ssh adb321@apt148.apt.emulab.net pkill -9 main
ssh adb321@apt181.apt.emulab.net pkill -9 main
ssh adb321@apt161.apt.emulab.net pkill -9 main
ssh adb321@apt183.apt.emulab.net pkill -9 main
ssh adb321@apt154.apt.emulab.net pkill -9 main
ssh adb321@apt139.apt.emulab.net pkill -9 main
tmux new-session \;  \
 send-keys 'ssh adb321@apt152.apt.emulab.net ./main --node_count 12 --node_id 0 --runtime 10 --op_count 10000000 --min_key 1 --max_key 9600 --region_size 20 --thread_count 8 --qp_max 8 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt145.apt.emulab.net ./main --node_count 12 --node_id 1 --runtime 10 --op_count 10000000 --min_key 1 --max_key 9600 --region_size 20 --thread_count 8 --qp_max 8 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt190.apt.emulab.net ./main --node_count 12 --node_id 2 --runtime 10 --op_count 10000000 --min_key 1 --max_key 9600 --region_size 20 --thread_count 8 --qp_max 8 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt179.apt.emulab.net ./main --node_count 12 --node_id 3 --runtime 10 --op_count 10000000 --min_key 1 --max_key 9600 --region_size 20 --thread_count 8 --qp_max 8 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt192.apt.emulab.net ./main --node_count 12 --node_id 4 --runtime 10 --op_count 10000000 --min_key 1 --max_key 9600 --region_size 20 --thread_count 8 --qp_max 8 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt186.apt.emulab.net ./main --node_count 12 --node_id 5 --runtime 10 --op_count 10000000 --min_key 1 --max_key 9600 --region_size 20 --thread_count 8 --qp_max 8 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt148.apt.emulab.net ./main --node_count 12 --node_id 6 --runtime 10 --op_count 10000000 --min_key 1 --max_key 9600 --region_size 20 --thread_count 8 --qp_max 8 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt181.apt.emulab.net ./main --node_count 12 --node_id 7 --runtime 10 --op_count 10000000 --min_key 1 --max_key 9600 --region_size 20 --thread_count 8 --qp_max 8 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt161.apt.emulab.net ./main --node_count 12 --node_id 8 --runtime 10 --op_count 10000000 --min_key 1 --max_key 9600 --region_size 20 --thread_count 8 --qp_max 8 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt183.apt.emulab.net ./main --node_count 12 --node_id 9 --runtime 10 --op_count 10000000 --min_key 1 --max_key 9600 --region_size 20 --thread_count 8 --qp_max 8 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt154.apt.emulab.net ./main --node_count 12 --node_id 10 --runtime 10 --op_count 10000000 --min_key 1 --max_key 9600 --region_size 20 --thread_count 8 --qp_max 8 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt139.apt.emulab.net ./main --node_count 12 --node_id 11 --runtime 10 --op_count 10000000 --min_key 1 --max_key 9600 --region_size 20 --thread_count 8 --qp_max 8 --p_local 0 --local_budget 5 --remote_budget 5' C-m \; 