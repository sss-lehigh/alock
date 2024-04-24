#!/bin/env bash

source "exp.conf"

user=${ssh_user}
machines=("apt152" "apt156" "apt144" "apt153" "apt138" "apt147" "apt163" "apt164" "apt157" "apt148")
domain="apt.emulab.net"

exe_dir="./build"
exe="main"

usage() {
    echo "Usage: $0 [-h] [-s]"
    echo "  -h: Display this help message"
    echo "  -s: Update arguments of experiment only"
    exit 1
}

while getopts ":hs" option; do
    case "$option" in
        h)  # Display usage information
            usage
            ;;
        s)  # Update the specified package
            UPDATE=true
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
idx=0
for m in ${machines[@]}; do
  echo " \\" >> exp_run.sh
  if [[ $idx -ne 0 ]]; then
    echo " new-window \; \\" >> exp_run.sh
  fi
  echo -n " send-keys 'ssh ${user}@$m.$domain ./${exe} --node_count ${num_nodes} --node_id ${idx} --runtime ${runtime} --op_count ${op_count} --min_key ${min_key} --max_key ${max_key} --region_size ${region_size} --thread_count ${thread_count} --qp_max ${thread_count} --p_local ${p_local} --local_budget ${local_budget} --remote_budget ${remote_budget}' C-m \\; " >> exp_run.sh
  idx=$((idx + 1))
done

chmod +x exp_run.sh

./exp_run.sh
