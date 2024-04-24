#!/bin/bash

# Source cluster-dependent variables
source "config.conf"

delete_data() {
  tmp=$(pwd)
  cd ../../rome/scripts
  python rexec.py -n ${nodefile} --remote_user=adb321 --remote_root=/users/adb321/alock --local_root=/Users/amandabaran/Desktop/sss/async_locks/alock --cmd="$1"
  cd ${tmp}
  echo "Data Deletion Complete\n"
}

# This script gets data for all three experiments, and then deletes the data from the remote nodes. Comment out as needed. 

save_dir="budget_exp"

bazel run //alock/benchmark/one_lock:launch -- -n ${nodefile}  --ssh_user=adb321  --get_data   --lock_type=${lock} --local_save_dir=${workspace}/benchmark/one_lock/results/${save_dir}/ --remote_save_dir=/users/adb321/results/${save_dir}
echo "Budget Experiment Data Collection Complete\n"

delete_data "rm -rf /users/adb321/results/${save_dir}"

save_dir="scalability_exp"

bazel run //alock/benchmark/one_lock:launch -- -n ${nodefile}  --ssh_user=adb321  --get_data   --lock_type=${lock} --local_save_dir=${workspace}/benchmark/one_lock/results/${save_dir}/ --remote_save_dir=/users/adb321/results/${save_dir}
echo "Scalability Experiment Data Collection Complete\n"


delete_data "rm -rf /users/adb321/results/${save_dir}"

save_dir="spin_exp"

bazel run //alock/benchmark/one_lock:launch -- -n ${nodefile}  --ssh_user=adb321  --get_data   --lock_type=${lock} --local_save_dir=${workspace}/benchmark/one_lock/results/${save_dir}/ --remote_save_dir=/users/adb321/results/${save_dir}
echo "Spinlock Experiment Data Collection Complete\n"


delete_data "rm -rf /users/adb321/results/${save_dir}"

