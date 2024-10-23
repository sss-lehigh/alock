#!/bin/env bash

source "exp.conf"

# Modify these variables
DEBUG=0 # 1 for debug with gdb
SET_BASHRC=1 # set to 0 to not change bashrc remember .bashrc.old still exists
USE_TMUX=0 # set 1 to use tmux, 0 to execute commands directly on machines

user=${ssh_user}
machines=("apt152" "apt145" "apt190" "apt179" "apt192" "apt186" "apt148" "apt181" "apt161" "apt183" "apt154" "apt139" "apt147" "apt184" "apt178" "apt141" "apt163" "apt162" "apt164" "apt159")
domain="apt.emulab.net"
node_list="node0,node1,node2,node3,node4,node5,node6,node7,node8,node9,node10,node11,node12,node13,node14,node15,node16,node17,node18,node19"

exe_dir="./build"
#Modify this variable if changing the executable and make sure to modify cmd at line 59
exe="main"
# exe="port_range.sh"
#######################################################################################################################

cd build
make -j "$exe"
cd ..

# Shorten list of machines to only use the machines needed for the experiment
machines=("${machines[@]:0:$num_nodes}")

# Loops through all machines and connects to setup
for m in "${machines[@]}"; do
  ssh "${user}@$m.$domain" hostname 
done

if [[ $SET_BASHRC -eq 1 ]]; then
  # sets ulimit for open files to hard limit
  # must be set in bashrc to always reset on ssh
  for m in "${machines[@]}"; do
    hardlimit=$(ssh "${user}@$m.$domain" ulimit -Hn)
    ssh "${user}@$m.$domain" mv .bashrc .bashrc.old
    echo "Setting to $hardlimit"
    echo "ulimit -n $hardlimit" > temp
    scp temp "${user}@$m.$domain":~/.bashrc
    ssh "${user}@$m.$domain" ulimit -n
  done
  rm temp
else
  echo "Make sure ulimits are high enough!!!!" 
fi

for m in "${machines[@]}"; do
  ssh "${user}@$m.$domain" sudo pkill -SIGTERM "${exe}"
  scp "${exe_dir}/${exe}" "${user}@$m.$domain":~
done

if [[ "$USE_TMUX" -eq 1 ]]; then
  echo "#!/bin/env bash" > experiment_script.sh

  for m in "${machines[@]}"; do
    echo "ssh ${user}@$m.$domain pkill -9 ${exe}" >> experiment_script.sh
  done

  echo -n "tmux new-session \\; " >> experiment_script.sh
  idx=0
  for m in "${machines[@]}"; do
    max_key=$(( ${num_nodes} * 100 * ${thread_count} ))
    # Modify this if changing code
    # cmd="./${exe} -p 10000 -t 32 -n $node_list -i $idx"
    if [[ "${topology}" -eq 1 ]]; then
      cmd="./${exe} --topology --node_count ${num_nodes} --node_id ${idx} --runtime ${runtime} --op_count ${op_count} --min_key ${min_key} --max_key ${max_key} --region_size ${region_size} --thread_count ${thread_count} --qp_max ${thread_count} --p_local ${p_local} --local_budget ${local_budget} --remote_budget ${remote_budget}"
    else
      cmd="./${exe} --node_count ${num_nodes} --node_id ${idx} --runtime ${runtime} --op_count ${op_count} --min_key ${min_key} --max_key ${max_key} --region_size ${region_size} --thread_count ${thread_count} --qp_max ${thread_count} --p_local ${p_local} --local_budget ${local_budget} --remote_budget ${remote_budget}"
    fi
    # cmd="bash ${exe}"

    echo " \\" >> experiment_script.sh
    if [[ $idx -ne 0 ]]; then
      echo " new-window \; \\" >> experiment_script.sh
    fi
    if [[ "$DEBUG" -eq 0 ]]; then
      echo -n " send-keys 'ssh ${user}@$m.$domain $cmd' C-m \\; " >> experiment_script.sh
    else
      echo -n " send-keys 'ssh ${user}@$m.$domain' C-m \\; " >> experiment_script.sh
      echo -n " send-keys 'gdb --args $cmd' C-m \\; " >> experiment_script.sh
    fi
    idx=$((idx + 1))
  done

  chmod +x experiment_script.sh
  ./experiment_script.sh

else
  # Execute the command directly on each machine
  for idx in "${!machines[@]}"; do
    m="${machines[$idx]}"
    max_key=$(( ${num_nodes} * 100 * ${thread_count} ))
    
    # Construct the command to be executed
    cmd="./${exe} --topology --node_count ${num_nodes} --node_id ${idx} --runtime ${runtime} --op_count ${op_count} --min_key ${min_key} --max_key ${max_key} --region_size ${region_size} --thread_count ${thread_count} --qp_max ${thread_count} --p_local ${p_local} --local_budget ${local_budget} --remote_budget ${remote_budget}"

    echo "Executing command on $m"
    
    if [[ "$DEBUG" -eq 0 ]]; then
      ssh "${user}@$m.$domain" "$cmd" &
    else
      ssh "${user}@$m.$domain" "gdb --args $cmd" &
    fi
  done

  wait # Wait for all background processes to complete
fi