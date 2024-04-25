#!/bin/env bash

source "exp.conf"

user=${ssh_user}
machines=("apt152" "apt156" "apt144" "apt153" "apt138" "apt147" "apt163" "apt164" "apt157" "apt148")
domain="apt.emulab.net"

exe_dir="./build"
exe="main"

if [ $num_nodes != ${#machines[@]} ]; then
    echo "Machines list size does not match exp.conf"
    echo "Machines list size: ${#machines[@]}" 
    echo "Experiment param num_nodes: ${num_nodes}"
    exit 1
fi

usage() {
    echo "Usage: $0 [-h] [-s] [-g]"
    echo "  -h: Display this help message"
    echo "  -s: Update arguments of experiment only"
    echo "  -g: Run in gdb"
    exit 1
}

GDB=false

while getopts ":hsg" option; do
    case "$option" in
        h)  # Display usage information
            usage
            ;;
        s)  # Update the specified package
            UPDATE=true
            ;;
        g)
            GDB=true
            ;;
        \?) # Invalid option
            echo "Error: Invalid option -$OPTARG"
            usage
            ;;
    esac
done
shift $((OPTIND - 1))

if [ "$UPDATE" != true ]; then

    cd build
    make -j ${exe}
    cd ..

    for m in ${machines[@]}; do
      ssh "${user}@$m.$domain" hostname
    done

    for m in ${machines[@]}; do
      ssh "${user}@$m.$domain" pkill -9 "${exe}"
      scp "${exe_dir}/${exe}" "${user}@$m.$domain":~
    done
fi 

echo "#!/bin/env bash" > exp_run.sh

for m in ${machines[@]}; do
  echo "ssh ${user}@$m.$domain pkill -9 ${exe}" >> exp_run.sh
done

echo -n "tmux new-session \\; " >> exp_run.sh


if [ "$GDB" == true ]; then
    echo "Running in gdb mode"
    idx=0
    for m in ${machines[@]}; do
      echo " \\" >> exp_run.sh
      if [[ $idx -ne 0 ]]; then
        echo " new-window \; \\" >> exp_run.sh
      fi
      echo -n " send-keys 'ssh ${user}@$m.$domain gdb --args ${exe} --node_count ${num_nodes} --node_id ${idx} --runtime ${runtime} --op_count ${op_count} --min_key ${min_key} --max_key ${max_key} --region_size ${region_size} --thread_count ${thread_count} --qp_max ${thread_count} --p_local ${p_local} --local_budget ${local_budget} --remote_budget ${remote_budget}' C-m \\; " >> exp_run.sh
      # echo " run \\" >> exp_run.sh
      idx=$((idx + 1))
    done
fi

if [ "$GDB" == false ]; then
    idx=0
    for m in ${machines[@]}; do
      echo " \\" >> exp_run.sh
      if [[ $idx -ne 0 ]]; then
        echo " new-window \; \\" >> exp_run.sh
      fi
      echo -n " send-keys 'ssh ${user}@$m.$domain ./${exe} --node_count ${num_nodes} --node_id ${idx} --runtime ${runtime} --op_count ${op_count} --min_key ${min_key} --max_key ${max_key} --region_size ${region_size} --thread_count ${thread_count} --qp_max ${thread_count} --p_local ${p_local} --local_budget ${local_budget} --remote_budget ${remote_budget}' C-m \\; " >> exp_run.sh
      idx=$((idx + 1))
    done
fi

chmod +x exp_run.sh

./exp_run.sh
