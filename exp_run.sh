#!/bin/env bash
ssh adb321@apt073.apt.emulab.net pkill -9 main
ssh adb321@apt103.apt.emulab.net pkill -9 main
ssh adb321@apt106.apt.emulab.net pkill -9 main
tmux new-session \;  \
 send-keys 'ssh adb321@apt073.apt.emulab.net ./main --node_count 3 --node_id 0 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1000 --region_size 15 --thread_count 1 --qp_max 1 --p_local 50 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt103.apt.emulab.net ./main --node_count 3 --node_id 1 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1000 --region_size 15 --thread_count 1 --qp_max 1 --p_local 50 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt106.apt.emulab.net ./main --node_count 3 --node_id 2 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1000 --region_size 15 --thread_count 1 --qp_max 1 --p_local 50 --local_budget 5 --remote_budget 5' C-m \; 