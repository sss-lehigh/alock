#!/bin/env bash

source "exp.conf"

# Modify these variables
BUILD=1
DEBUG=0 # 1 for debug with gdb
SET_BASHRC=1 # set to 0 to not change bashrc remember .bashrc.old still exists
USE_TMUX=1 # set 1 to use tmux, 0 to execute commands directly on machines

exe_dir="./build"
#Modify this variable if changing the executable and make sure to modify cmd at line 59
exe="main"
#######################################################################################################################

# Shorten list of machines to only use the machines needed for the experiment
IFS=',' read -r -a node_array <<< "$machines"
machines=$(IFS=','; echo "${node_array[*]:0:$num_nodes}")
IFS=","

if [[ $BUILD -eq 1 ]]; then
  echo "BUILDING"
  cd build
  make -j "$exe"
  cd ..
  for m in $machines; do
    ssh "${ssh_user}@$m.$domain" sudo pkill -SIGTERM "${exe}" &
    scp "${exe_dir}/${exe}" "${ssh_user}@$m.$domain":~
  done
  # # Loops through all machines and connects to setup
  # for m in $machines; do
  #   ssh "${ssh_user}@$m.$domain" hostname 
  # done
fi

if [[ $SET_BASHRC -eq 1 ]]; then
  # sets ulimit for open files to hard limit
  # must be set in bashrc to always reset on ssh
  for m in $machines; do
    hardlimit=$(ssh "${ssh_user}@$m.$domain" ulimit -Hn)
    ssh "${ssh_user}@$m.$domain" mv .bashrc .bashrc.old
    echo "Setting to $hardlimit"
    echo "ulimit -n $hardlimit" > temp
    scp temp "${ssh_user}@$m.$domain":~/.bashrc
    ssh "${ssh_user}@$m.$domain" ulimit -n
  done
  rm temp
else
  echo "Make sure ulimits are high enough!!!!" 
fi

for m in $machines; do
  ssh "${ssh_user}@$m.$domain" sudo pkill -SIGTERM "${exe}" &
done

if [[ "$USE_TMUX" -eq 1 ]]; then
  echo "#!/bin/env bash" > experiment_script.sh

  for m in $machines; do
    echo "ssh ${ssh_user}@$m.$domain pkill -9 ${exe}" >> experiment_script.sh
  done

  echo -n "tmux new-session \\; " >> experiment_script.sh
  idx=0
  for m in $machines; do
    max_key=$(( ${num_nodes} * 10 * ${thread_count} ))
    # Modify this if changing code
    # cmd="./${exe} -p 10000 -t 32 -n $node_list -i $idx"
    cmd="./${exe} --node_count ${num_nodes} --node_id ${idx} --stream_type ${stream_type} --runtime ${runtime} --op_count ${op_count} --min_key ${min_key} --max_key ${max_key} --region_size ${region_size} --thread_count ${thread_count} --qp_max ${thread_count} --p_local ${p_local} --local_budget ${local_budget} --remote_budget ${remote_budget}"

    # cmd="bash ${exe}"

    echo " \\" >> experiment_script.sh
    if [[ $idx -ne 0 ]]; then
      echo " new-window \; \\" >> experiment_script.sh
    fi
    if [[ "$DEBUG" -eq 0 ]]; then
      echo -n " send-keys 'ssh ${ssh_user}@$m.$domain $cmd' C-m \\; " >> experiment_script.sh
    else
      echo -n " send-keys 'ssh ${ssh_user}@$m.$domain' C-m \\; " >> experiment_script.sh
      echo -n " send-keys 'gdb --args $cmd' C-m \\; " >> experiment_script.sh
    fi
    idx=$((idx + 1))
  done

  chmod +x experiment_script.sh
  ./experiment_script.sh

else
  # Execute the command directly on each machine
  for m in $machines; do
    max_key=$(( ${num_nodes} * 10 * ${thread_count} ))

    cmd="./${exe} --node_count ${num_nodes} --node_id ${idx} --stream_type ${stream_type} --runtime ${runtime} --op_count ${op_count} --min_key ${min_key} --max_key ${max_key} --region_size ${region_size} --thread_count ${thread_count} --qp_max ${thread_count} --p_local ${p_local} --local_budget ${local_budget} --remote_budget ${remote_budget}"

    echo "Executing command on $m"
    
    if [[ "$DEBUG" -eq 0 ]]; then
      ssh "${ssh_user}@$m.$domain" "$cmd" &
    else
      ssh "${ssh_user}@$m.$domain" "gdb --args $cmd" &
    fi
  done

  wait # Wait for all background processes to complete
fi