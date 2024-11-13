#!/bin/env bash
ssh adb321@apt183.apt.emulab.net pkill -9 main
ssh adb321@apt192.apt.emulab.net pkill -9 main
ssh adb321@apt175.apt.emulab.net pkill -9 main
ssh adb321@apt180.apt.emulab.net pkill -9 main
ssh adb321@apt182.apt.emulab.net pkill -9 main
ssh adb321@apt178.apt.emulab.net pkill -9 main
ssh adb321@apt181.apt.emulab.net pkill -9 main
ssh adb321@apt176.apt.emulab.net pkill -9 main
ssh adb321@apt186.apt.emulab.net pkill -9 main
ssh adb321@apt184.apt.emulab.net pkill -9 main
ssh adb321@apt187.apt.emulab.net pkill -9 main
ssh adb321@apt177.apt.emulab.net pkill -9 main
ssh adb321@apt076.apt.emulab.net pkill -9 main
ssh adb321@apt190.apt.emulab.net pkill -9 main
ssh adb321@apt118.apt.emulab.net pkill -9 main
ssh adb321@apt153.apt.emulab.net pkill -9 main
ssh adb321@apt072.apt.emulab.net pkill -9 main
ssh adb321@apt098.apt.emulab.net pkill -9 main
ssh adb321@apt162.apt.emulab.net pkill -9 main
ssh adb321@apt145.apt.emulab.net pkill -9 main
ssh adb321@apt071.apt.emulab.net pkill -9 main
ssh adb321@apt158.apt.emulab.net pkill -9 main
ssh adb321@apt140.apt.emulab.net pkill -9 main
ssh adb321@apt185.apt.emulab.net pkill -9 main
ssh adb321@apt149.apt.emulab.net pkill -9 main
ssh adb321@apt156.apt.emulab.net pkill -9 main
ssh adb321@apt082.apt.emulab.net pkill -9 main
ssh adb321@apt073.apt.emulab.net pkill -9 main
ssh adb321@apt152.apt.emulab.net pkill -9 main
ssh adb321@apt081.apt.emulab.net pkill -9 main
ssh adb321@apt129.apt.emulab.net pkill -9 main
ssh adb321@apt088.apt.emulab.net pkill -9 main
ssh adb321@apt106.apt.emulab.net pkill -9 main
ssh adb321@apt083.apt.emulab.net pkill -9 main
ssh adb321@apt164.apt.emulab.net pkill -9 main
ssh adb321@apt120.apt.emulab.net pkill -9 main
ssh adb321@apt070.apt.emulab.net pkill -9 main
ssh adb321@apt173.apt.emulab.net pkill -9 main
ssh adb321@apt069.apt.emulab.net pkill -9 main
ssh adb321@apt179.apt.emulab.net pkill -9 main
tmux new-session \;  \
 send-keys 'ssh adb321@apt183.apt.emulab.net ./main --topology --node_count 40 --node_id 0 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt192.apt.emulab.net ./main --topology --node_count 40 --node_id 1 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt175.apt.emulab.net ./main --topology --node_count 40 --node_id 2 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt180.apt.emulab.net ./main --topology --node_count 40 --node_id 3 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt182.apt.emulab.net ./main --topology --node_count 40 --node_id 4 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt178.apt.emulab.net ./main --topology --node_count 40 --node_id 5 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt181.apt.emulab.net ./main --topology --node_count 40 --node_id 6 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt176.apt.emulab.net ./main --topology --node_count 40 --node_id 7 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt186.apt.emulab.net ./main --topology --node_count 40 --node_id 8 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt184.apt.emulab.net ./main --topology --node_count 40 --node_id 9 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt187.apt.emulab.net ./main --topology --node_count 40 --node_id 10 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt177.apt.emulab.net ./main --topology --node_count 40 --node_id 11 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt076.apt.emulab.net ./main --topology --node_count 40 --node_id 12 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt190.apt.emulab.net ./main --topology --node_count 40 --node_id 13 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt118.apt.emulab.net ./main --topology --node_count 40 --node_id 14 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt153.apt.emulab.net ./main --topology --node_count 40 --node_id 15 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt072.apt.emulab.net ./main --topology --node_count 40 --node_id 16 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt098.apt.emulab.net ./main --topology --node_count 40 --node_id 17 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt162.apt.emulab.net ./main --topology --node_count 40 --node_id 18 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt145.apt.emulab.net ./main --topology --node_count 40 --node_id 19 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt071.apt.emulab.net ./main --topology --node_count 40 --node_id 20 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt158.apt.emulab.net ./main --topology --node_count 40 --node_id 21 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt140.apt.emulab.net ./main --topology --node_count 40 --node_id 22 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt185.apt.emulab.net ./main --topology --node_count 40 --node_id 23 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt149.apt.emulab.net ./main --topology --node_count 40 --node_id 24 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt156.apt.emulab.net ./main --topology --node_count 40 --node_id 25 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt082.apt.emulab.net ./main --topology --node_count 40 --node_id 26 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt073.apt.emulab.net ./main --topology --node_count 40 --node_id 27 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt152.apt.emulab.net ./main --topology --node_count 40 --node_id 28 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt081.apt.emulab.net ./main --topology --node_count 40 --node_id 29 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt129.apt.emulab.net ./main --topology --node_count 40 --node_id 30 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt088.apt.emulab.net ./main --topology --node_count 40 --node_id 31 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt106.apt.emulab.net ./main --topology --node_count 40 --node_id 32 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt083.apt.emulab.net ./main --topology --node_count 40 --node_id 33 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt164.apt.emulab.net ./main --topology --node_count 40 --node_id 34 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt120.apt.emulab.net ./main --topology --node_count 40 --node_id 35 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt070.apt.emulab.net ./main --topology --node_count 40 --node_id 36 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt173.apt.emulab.net ./main --topology --node_count 40 --node_id 37 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt069.apt.emulab.net ./main --topology --node_count 40 --node_id 38 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \;  \
 new-window \; \
 send-keys 'ssh adb321@apt179.apt.emulab.net ./main --topology --node_count 40 --node_id 39 --runtime 10 --op_count 10000000 --min_key 1 --max_key 1600 --region_size 20 --thread_count 4 --qp_max 4 --p_local 0 --local_budget 5 --remote_budget 5' C-m \; 