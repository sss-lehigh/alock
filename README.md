# ALock README


# Setup

In the directory now containing your alock repo, download our internal RDMA library, remus, which can be found at https://github.com/sss-lehigh/remus.git.

Create a cloudlab experiment, or add your own cluster information to the $user, $machines and $domain variables in setup.sh. These scripts are intended to be run from a local computer containing the repos. Make sure this local computer is properly setup with an SSH key on cloudlab. 


## Build Dependecies
<!-- rebuilds and installs remus into /opt/ -->
cd remus/tools
sh install.sh 

<!-- Installs dependencies on clouldab cluster -->
cd alock
<!-- TODO: Make sure to update with cloudlab node info  -->
bash setup.sh

## Change Experiment Configuration
Edit parameters in "alock/exp.conf". 

## Build ALock Executable

Generate build system. 
``cmake -DCMAKE_PREFIX_PATH=/opt/remus/lib/cmake -DCMAKE_MODULE_PATH=/opt/remus/lib/cmake -B build``

Build. 
``cd build``
``make -j``

### Log Level Flag:
Use below flags to update log level. 
``cmake -DLOG_LEVEL=INFO ..``

Recommended levels in increasing information order:
-DLOG_LEVEL=INFO
-DLOG_LEVEL=DEBUG
-DLOG_LEVEL=TRACE

### CMake Build Type Options
-DCMAKE_BUILD_TYPE=Release (-o3)
<!-- Use one of below for gdb -->
-DCMAKE_BUILD_TYPE=Debug (-g) 
-DCMAKE_BUILD_TYPE=RelWithDebInfo (-o3 and -g)


## Send to Clouldab and Run Exepriment

<!-- update experiment parameters first -->
Update exp.conf to desired experiment parameters. 

<!-- Builds executable, sends to nodes, and runs exp_run.sh  -->
bash run.sh  <!-- TODO: Make sure to update with cloudlab node info  -->

<!-- Reruns experiment without updating from exp.conf-->
bash exp_run.sh

<!-- Kills experiment name on nodes to take care of zombie processes -->
bash shutdown.sh

<!-- Use to collect results after running experiment. See file for download naming conventions. -->
bash get_results.sh

<!-- Use after collecting results to generate csv files and run plot script -->
bash plot.sh