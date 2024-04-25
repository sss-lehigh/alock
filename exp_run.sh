#!/bin/env bash
ssh adb321@apt152.apt.emulab.net pkill -9 main
ssh adb321@apt156.apt.emulab.net pkill -9 main
ssh adb321@apt144.apt.emulab.net pkill -9 main
ssh adb321@apt153.apt.emulab.net pkill -9 main
ssh adb321@apt138.apt.emulab.net pkill -9 main
ssh adb321@apt147.apt.emulab.net pkill -9 main
ssh adb321@apt163.apt.emulab.net pkill -9 main
ssh adb321@apt164.apt.emulab.net pkill -9 main
ssh adb321@apt157.apt.emulab.net pkill -9 main
ssh adb321@apt148.apt.emulab.net pkill -9 main
tmux new-session \;  \
 send-keys 'ssh adb321@apt152.apt.emulab.net ./main --node_count 10 --node_id 0 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1000 --region_size 20 --thread_count 3 --qp_max 3 --p_local 50 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt156.apt.emulab.net ./main --node_count 10 --node_id 1 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1000 --region_size 20 --thread_count 3 --qp_max 3 --p_local 50 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt144.apt.emulab.net ./main --node_count 10 --node_id 2 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1000 --region_size 20 --thread_count 3 --qp_max 3 --p_local 50 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt153.apt.emulab.net ./main --node_count 10 --node_id 3 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1000 --region_size 20 --thread_count 3 --qp_max 3 --p_local 50 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt138.apt.emulab.net ./main --node_count 10 --node_id 4 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1000 --region_size 20 --thread_count 3 --qp_max 3 --p_local 50 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt147.apt.emulab.net ./main --node_count 10 --node_id 5 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1000 --region_size 20 --thread_count 3 --qp_max 3 --p_local 50 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt163.apt.emulab.net ./main --node_count 10 --node_id 6 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1000 --region_size 20 --thread_count 3 --qp_max 3 --p_local 50 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt164.apt.emulab.net ./main --node_count 10 --node_id 7 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1000 --region_size 20 --thread_count 3 --qp_max 3 --p_local 50 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt157.apt.emulab.net ./main --node_count 10 --node_id 8 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1000 --region_size 20 --thread_count 3 --qp_max 3 --p_local 50 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt148.apt.emulab.net ./main --node_count 10 --node_id 9 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1000 --region_size 20 --thread_count 3 --qp_max 3 --p_local 50 --local_budget 5 --remote_budget 5' C-m \; 