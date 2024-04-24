#!/bin/sh
# set default variables
file='../../remus-internal/scripts/cloudlab.csv'
verbose=false
help=false
# determines what gets sent (sss/)
root_dir='..'
# root_dir='../..'
username=''
auth_key='id_ed25519'
install=false

# get command line arguments
while getopts k:u:f:vhi flag
do
    case "${flag}" in
        k) auth_key=${OPTARG};;
        u) username=${OPTARG};;
        f) file=${OPTARG};;
        v) verbose=true;;
        h) help=true;;
        i) install=true;; 
    esac
done

# Functions for output
echo_red (){
    echo "\033[31m$1\033[0m $2"
}
echo_green (){
    echo "\033[32m$1\033[0m $2"
}
echo_blue(){
    echo "\033[34m$1\033[0m $2"
}
echo_blue_green(){
    echo "\033[34m$1 \033[32m$2\033[0m"
}
# Create the hostname from the file
build_hostname(){
    case $1 in
        xl170)
            echo "$2.utah.cloudlab.us";;
        d6515)
            echo "$2.utah.cloudlab.us";;
        c6525-100g)
            echo "$2.utah.cloudlab.us";;
        c6525-25g)
            echo "$2.utah.cloudlab.us";;
        m510)
            echo "$2.utah.cloudlab.us";;
        r6525)
            echo "$2.clemson.cloudlab.us";;
        r320)
            echo "$2.apt.emulab.net";;
        luigi)
            echo "$2.cse.lehigh.edu";;
        *)
            return 1;;
    esac
    return 0
}

# Optional argument checking
if [ -z $username ]
then
    help=true
fi

# Print help message
if $help 
then
    echo_blue_green "Usage:" "./sync.sh"
    echo_blue "  -f [file]" "set the file to parse for node information (default: 'cloudlab.csv')"
    if [ -z $username ]
    then
        echo_red "  -u [username]" "your cloudlab username"
    else
        echo_blue "  -u [username]" "your cloudlab username"
    fi
    echo_blue "  -k [key]" "the ssh key used for authentication. Stored in ~/.ssh (default: 'id_rsa')"
    echo_blue "  -h" "display this message"
    echo_blue "  -v" "be verbose in output"
    echo_blue "  -i" "install dependencies by running cloudlab_depend.sh on each node"
    exit 0
fi

# Make log directory
mkdir -p log
# Giving some user feedback
echo_green "[INFO]" "Syncing with file $file"
i=0
# iterate through the file line by line
while IFS="" read -r line || [ -n "$line" ]
do
    # get the node information
    node_num="$(echo $line | cut -d',' -f1)"
    node_id="$(echo $line | cut -d',' -f2)"
    node_type="$(echo $line | cut -d',' -f3)"
    # build the hostname
    hostname=`build_hostname $node_type $node_id`
    # If the output was valid for building the hostname
    if [ $? -eq 1 ]
    then
        echo_red "[ERR]" "Can't determine hostname"
    fi
    # Launch rsync
    if $verbose
    then
        echo_green "[INFO]" "Starting sync with $node_num $hostname"
    fi
    cd $root_dir
    pwd=`pwd`
    cd - > /dev/null
    if $verbose && [ $i -eq 0 ]
    then
        i=1
        rsync -r -e 'ssh -i ~/.ssh/'$auth_key' -o StrictHostKeyChecking=no' --exclude-from=./exclude.txt --progress -uva $pwd $username@$hostname:/users/$username &
    elif $verbose
    then
        ignore=`rsync -r -e 'ssh -i ~/.ssh/'$auth_key' -o StrictHostKeyChecking=no' --exclude-from=./exclude.txt --progress -uva $pwd $username@$hostname:/users/$username &`
    else
        touch log/${node_num}_sync.log
        echo "Logging at log/${node_num}_sync.log"
        rsync -r -e 'ssh -i ~/.ssh/'$auth_key' -o StrictHostKeyChecking=no' --exclude-from=./exclude.txt --progress -uva $pwd $username@$hostname:/users/$username > log/${node_num}_sync.log &
    fi

done < $file
# Wait for everything to finish
wait

if ! $install
then
    exit 0
fi

i=0
# iterate through the file line by line
while IFS="" read -r line || [ -n "$line" ]
do
    # get the node information
    node_num="$(echo $line | cut -d',' -f1)"
    node_id="$(echo $line | cut -d',' -f2)"
    node_type="$(echo $line | cut -d',' -f3)"
    # build the hostname
    hostname=`build_hostname $node_type $node_id`
    # get the parent directory that we synced
    cd $root_dir
    dir=`echo "$pwd" | rev | cut -d '/' -f1 | rev`
    cd - > /dev/null
    # If verbose, then get output of one of the commands
    if $verbose && [ $i -eq 0 ]
    then
        i=1
        ssh $username@$hostname "cd $dir; sh cloudlab_depend.sh" &
    elif $verbose
    then
        ignore=`ssh $username@$hostname "cd $dir; sh cloudlab_depend.sh" &`
    else
        # if not verbose, create a log file and push our progress in there
        touch log/${node_num}_sync.log
        echo "Installing dependencies for ${node_id}. Progress at log/${node_num}_sync.log"
        ssh $username@$hostname "cd $dir; sh cloudlab_depend.sh" > log/${node_num}_sync.log &
    fi
    
done < $file

# wait for everything to finish
wait