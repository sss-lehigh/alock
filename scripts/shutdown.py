from multiprocessing import Process
import subprocess
from typing import List
import csv
import argparse

def domain_name(nodetype):
    """Function to get domain name"""
    node_i = ['r320',           'luigi',          'r6525',               'xl170',            'c6525-100g',       'c6525-25g',        'd6515']
    node_h = ['apt.emulab.net', 'cse.lehigh.edu', 'clemson.cloudlab.us', 'utah.cloudlab.us', 'utah.cloudlab.us', 'utah.cloudlab.us', 'utah.cloudlab.us']
    return node_h[node_i.index(nodetype)]

parser = argparse.ArgumentParser(description='Process the parameters for shutting down stuck processes')
parser.add_argument('-u', '--ssh_user', type=str, required=True, help='Username for login)')
parser.add_argument('--nodefile', type=str, default="cloudlab.csv", help='Path to csv with the node names')
parser.add_argument('--dry_run', action='store_true', help='Print the commands instead of running them')

# Define ARGS to represet the flags
ARGS = parser.parse_args()

def quote(string):
    return f"'{string}'"

# Create a function that will create a file and run the given command using that file as stout
def __run__(cmd):
    if ARGS.dry_run:
        print(cmd)
    else:
        try:
            subprocess.run(cmd, shell=True, check=True, stderr=None, stdout=None)
            print("Successful Execution")
            return
        except subprocess.CalledProcessError:
            print("Invalid Execution")

def execute(commands):
    """For each command in commands, start a process"""
    processes: List[Process] = []
    for cmd, file in commands:
        # Start a thread
        processes.append(Process(target=__run__, args=(cmd,)))
        processes[-1].start()

    # Wait for all threads to finish
    for process in processes:
        process.join()

def main():
    print("Shutting Down Servers...")
    commands = []
    with open(ARGS.nodefile, "r") as f:
        for node in csv.reader(f):
            # For every node in nodefile, get the node info
            nodename, nodealias, nodetype = node
            # Construct ssh command and payload
            ssh_login = f"ssh {ARGS.ssh_user}@{nodealias}.{domain_name(nodetype)}"
            # !!! The purpose here is to shutdown running instances of the program if its gets stuck somewhere !!!
            payload = f"/usr/bin/killall -15 main"
            # Tuple: (Creating Command | Output File Name)
            commands.append((' '.join([ssh_login, quote(payload)]), nodename))
    # Execute the commands and let us know we've finished
    execute(commands)
    print("Completed Task")


if __name__ == "__main__":
    main()
