import sys, getopt
import subprocess
from multiprocessing import Process
import os

# set default variables
file = "cloudlab.csv"
verbose = False
root_dir = '..' # the start of the repo
username=''
auth_key='id_ed25519'
install=False

# set colors
red = "\033[31m"
black = "\033[0m"
green = "\033[32m"
blue = "\033[34m"

def usage(missing_username):
    # Print help message
    print(f"{blue}Usage:{green} ./sync.sh{black}")
    print(f"{blue}  -f [file] {black}set the file to parse for node information (default: 'cloudlab.csv')")
    colr = red if missing_username else blue
    print(f"{colr}  -u [username] {black}your cloudlab username")
    print(f"{blue}  -k [key] {black}the ssh key used for authentication. Stored in ~/.ssh (default: 'id_rsa')")
    print(f"{blue}  -h {black}display this message")
    print(f"{blue}  -v {black}be verbose in output")
    print(f"{blue}  -i {black}install dependencies by running cloudlab_depend.sh on each node")

opts, args = getopt.getopt(sys.argv[1:], "k:u:f:vhi")
for opt, arg in opts:
    if opt == '-h':
        usage(False)
        sys.exit()
    elif opt == "-f":
        file = arg
    elif opt == "-v":
        verbose = True
    elif opt == "-u":
        username = arg
    elif opt == "-k":
        auth_key = arg
    elif opt == "-i":
        install = True

if username == "":
    usage(True)
    sys.exit()

# Create the hostname from the file
def build_hostname(node_type, node_id):
    if node_type in ["xl170", "d6515", "c6525-100g", "c6525-25g", "m510"]:
        return f"{node_id}.utah.cloudlab.us"
    elif node_type == "r6525":
        return f"{node_id}.clemson.cloudlab.us"
    elif node_type == "r320":
        return f"{node_id}.apt.emulab.net"
    elif node_type == "luigi":
        return f"{node_id}.cse.lehigh.edu"
    return None

# Make log directory
os.system("mkdir -p log")
# Getting directory
dir = os.path.abspath(root_dir)
proj_dir = dir.split("/").pop()

def __run__(cmd, outfile, node_num):
    try:
        if verbose:
            # Run the subprocess and output the first one verbosely
            ignore = (node_num != 0)
            subprocess.run(cmd, shell=True, check=True, capture_output=ignore)
            return
        with open(outfile, "w+") as f:
            # Run the subprocess and pipe to log file
            subprocess.run(cmd, shell=True, check=True, stderr=f, stdout=f)
            return
    except subprocess.CalledProcessError as e:
        print(outfile, "Invalid Startup because", e)

# iterate through the file line by line
def main_func():
    # Giving some user feedback
    print(f"{green}[INFO] {black}Syncing with file {file}")
    with open(file, "r") as f:
        # Read the file
        data = f.read().strip().split("\n")
        sync_processes = []
        install_processes = []
        for i, row in enumerate(data):
            # Split the row into tokens
            tokens = row.split(",")
            if len(tokens) != 3:
                print(f"{red}[ERR] {black}Ignoring line {i}, not enough values to unpack")
                continue
            # Unpack values and build hostname
            node_num, node_id, node_type = tokens
            hostname = build_hostname(node_type, node_id)
            # Print an error if we can't build the hostname
            if hostname is None:
                print(f"{red}[ERR] {black}Can't determine hostname")
                continue
            # If verbose, echo the hostname
            if verbose:
                print(f"{green}[INFO] {black}Starting sync with {node_num}")
            # Create the process with rsync
            cmd = f"rsync -r -e 'ssh -i ~/.ssh/{auth_key} -o StrictHostKeyChecking=no' --exclude-from=./exclude.txt --progress -uva {dir} {username}@{hostname}:/users/{username}"
            sync_processes.append(Process(target=__run__, args=(cmd, f"log/node{i}_sync.log", i)))
            sync_processes[-1].start()
            if install:
                cmd = f"ssh {username}@{hostname} 'cd {proj_dir}; sh cloudlab_depend.sh'"
                install_processes.append(Process(target=__run__, args=(cmd, f"log/node{i}_sync.log", i)))
        # Wait for all processes to finish
        for process in sync_processes:
            process.join()
        # Do the install processes if there are any
        for process in install_processes:
            process.start()
        for process in install_processes:
            process.join()
        

if __name__ == "__main__":
    main_func()