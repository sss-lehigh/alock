#!/bin/env bash

source "exp.conf"

# Modify these variables
BUILD=1
DEBUG=0 # 1 for debug with gdb
SET_BASHRC=1 # set to 0 to not change bashrc remember .bashrc.old still exists
USE_TMUX=1 # set 1 to use tmux, 0 to execute commands directly on machines

user=${ssh_user}
machines=("apt183" "apt192" "apt175" "apt180" "apt182" "apt178" "apt181" "apt176" "apt186" "apt184" 
          "apt187" "apt177" "apt076" "apt190" "apt118" "apt153" "apt072" "apt098" "apt162" "apt145" 
          "apt071" "apt158" "apt140" "apt185" "apt149" "apt156" "apt082" "apt073" "apt152" "apt081" 
          "apt129" "apt088" "apt106" "apt083" "apt164" "apt120" "apt070" "apt173" "apt069" "apt179" 
          "apt086" "apt066" "apt131" "apt146" "apt091" "apt191" "apt142" "apt157" "apt141" "apt154")

domain="apt.emulab.net"

exe_dir="./build"
#Modify this variable if changing the executable and make sure to modify cmd at line 59
exe="main"
# exe="port_range.sh"
#######################################################################################################################

# Shorten list of machines to only use the machines needed for the experiment
machines=("${machines[@]:0:$num_nodes}")

if [[ $BUILD -eq 1 ]]; then
  echo "BUILDING"
  cd build
  make -j "$exe"
  cd ..
  for m in "${machines[@]}"; do
    ssh "${user}@$m.$domain" sudo pkill -SIGTERM "${exe}" &
    scp "${exe_dir}/${exe}" "${user}@$m.$domain":~
  done
  # # Loops through all machines and connects to setup
  # for m in "${machines[@]}"; do
  #   ssh "${user}@$m.$domain" hostname 
  # done
fi

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
  ssh "${user}@$m.$domain" sudo pkill -SIGTERM "${exe}" &
done

if [[ "$USE_TMUX" -eq 1 ]]; then
  echo "#!/bin/env bash" > experiment_script.sh

  for m in "${machines[@]}"; do
    echo "ssh ${user}@$m.$domain pkill -9 ${exe}" >> experiment_script.sh
  done

  echo -n "tmux new-session \\; " >> experiment_script.sh
  idx=0
  for m in "${machines[@]}"; do
    max_key=$(( ${num_nodes} * 10 * ${thread_count} ))
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
    max_key=$(( ${num_nodes} * 10 * ${thread_count} ))
    
    # Construct the command to be executed
    if [[ "${topology}" -eq 1 ]]; then
      cmd="./${exe} --topology --node_count ${num_nodes} --node_id ${idx} --runtime ${runtime} --op_count ${op_count} --min_key ${min_key} --max_key ${max_key} --region_size ${region_size} --thread_count ${thread_count} --qp_max ${thread_count} --p_local ${p_local} --local_budget ${local_budget} --remote_budget ${remote_budget}"
    else
      cmd="./${exe} --node_count ${num_nodes} --node_id ${idx} --runtime ${runtime} --op_count ${op_count} --min_key ${min_key} --max_key ${max_key} --region_size ${region_size} --thread_count ${thread_count} --qp_max ${thread_count} --p_local ${p_local} --local_budget ${local_budget} --remote_budget ${remote_budget}"
    fi

    echo "Executing command on $m"
    
    if [[ "$DEBUG" -eq 0 ]]; then
      ssh "${user}@$m.$domain" "$cmd" &
    else
      ssh "${user}@$m.$domain" "gdb --args $cmd" &
    fi
  done

  wait # Wait for all background processes to complete
fi