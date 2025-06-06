from multiprocessing import Process
import subprocess
import os
from typing import List
import csv
import json
import argparse
import pandas
import matplotlib.pyplot as plt
import seaborn

pandas.options.mode.chained_assignment = None  # default='warn'

parser = argparse.ArgumentParser(description='Process the parameters for running an experiment or a test-suite')
# Experiment configuration
# parser.add_argument("figdir", type=str, default='/Users/amandabaran/Desktop/sss/async_locks/alock/alock/alock/benchmark/one_lock/plots/',
#                     help="Directory name to save figures under")
# parser.add_argument(
#     'datafile', type=str,
#     help='Name of datafile for plotting (if none exists then one is generated by processing results in `save_dir`)')

# parser.add_argument('exp', type=str, default='exp1', help='Experiment to plot')
parser.add_argument('--nodes', type=int, default=0, help='number of nodes in experiment')
parser.add_argument('--threads', type=int, default=0, help='number of threads in experiment')
parser.add_argument('--exp', type=str, default='tput', help='tput or lat')

parser.add_argument('--save_dir', type=str, default='results', help='Directory containing results to plot')

parser.add_argument('--resfile', type=str, default='_result.csv', help='Name of file with results')

FLAGS = parser.parse_args()

def average_results(df):
    # Aggregate columns (e.g., sum)
    aggregates = df.mean(axis=0)  # Sum along the columns
    
    # Create a new DataFrame with the aggregate values
    aggregate_df = pandas.DataFrame(aggregates).T  # Transpose to have a single row
    
    # Append the new row to the original DataFrame
    df = pandas.concat([df, aggregate_df], ignore_index=True)
    
    # Save the merged DataFrame to a new CSV file in the root directory
    filename = FLAGS.exp + '_results.csv'
    merged_csv_path = os.path.join('./', FLAGS.save_dir, filename)
    df.to_csv(merged_csv_path, index=False)
    print(f"Merged results saved to '{merged_csv_path}'.")

def aggregate_results(df):
    # Aggregate columns (e.g., sum)
    aggregates = df.sum(axis=0)  # Sum along the columns
    
    # Create a new DataFrame with the aggregate values
    aggregate_df = pandas.DataFrame(aggregates).T  # Transpose to have a single row
    
    # Append the new row to the original DataFrame
    df = pandas.concat([df, aggregate_df], ignore_index=True)
    
    # Save the merged DataFrame to a new CSV file in the root directory
    filename = FLAGS.exp + '_results.csv'
    merged_csv_path = os.path.join('./', FLAGS.save_dir, filename)
    df.to_csv(merged_csv_path, index=False)
    print(f"Merged results saved to '{merged_csv_path}'.")

def trim_columns(df):
    print(df)
    columns = ['count', 'mean', 'stdev', 'min' ,'p50', 'p90' ,'p95' ,'p99' ,'p999', 'max']
    # columns = ['thread_count', 'node_count', 'p_local', 'min_key', 'max_key', 'count', 'mean', 'stdev', 'min' ,'p50', 'p90' ,'p95' ,'p99' ,'p999', 'max']
    newdf = df[columns]
    print(newdf)
    return newdf

def merge_csv_results(root_dir):
    # Initialize an empty DataFrame to store merged results
    merged_df = pandas.DataFrame()
    file = 'n' + str(FLAGS.nodes) + '_t' + str(FLAGS.threads) + '_' + FLAGS.exp + FLAGS.resfile
    # Walk through the directory tree
    print("ROOT" , root_dir)
    for dirpath, dirnames, filenames in os.walk(root_dir):
        print(dirpath)
        print(dirnames)
        print(filenames)
        if file in filenames:
            csv_file_path = os.path.join(dirpath, file)
            # Read the CSV file into a DataFrame
            df = pandas.read_csv(csv_file_path)
            # Append the DataFrame to the merged DataFrame
            merged_df = pandas.concat([merged_df, df], ignore_index=True)

    df = trim_columns(merged_df)
    if FLAGS.exp == "lat":
        average_results(df)
    else:
        aggregate_results(df)

merge_csv_results(FLAGS.save_dir)

def plot_tput(file):
    df = pandas.read_csv(file)
    # header_row = df.head(1)
    # averaged_results = df.tail(1)
    # df = pandas.concat([header_row,averaged_results])
    # filtered= df[df['thread_count'] <= 8]
    filtered=df
    plt.figure(figsize=(10,6))
    seaborn.barplot(
        data=filtered,
        x='thread_count',
        y="Throughput",
        hue="mode"
    )
    plt.xticks(fontsize=14)
    plt.yticks(fontsize=16)
    plt.xlabel("Threads per Node / QPs per Node / Total QPs in System", fontsize=14)
    plt.ylabel("Throughput (ops/s)", fontsize=18)
    plt.legend(fontsize=18, loc='upper left')
    filename= "plot.jpg"
    plt.savefig(filename, format='jpg')
    

# plot_tput('writes.csv')
    
# # Globals
# x1_ = 'lock_type'
# x2_ = 'experiment_params.workload.max_key'
# x3_ = 'experiment_params.num_clients'
# x4_ = 'experiment_params.num_nodes'
# x5_ = 'experiment_params.workload.p_local'
# x6_ = 'experiment_params.local_budget'
# x7_ = 'experiment_params.remote_budget'
# x8_ = 'experiment_params.num_threads'
# x_ = [x1_, x2_, x3_, x4_, x5_, x6_, x7_, x8_]
# y_ = 'results.driver.qps.summary.mean'
# y_2 = 'results.driver.latency.summary.mean'
# cols_ = [x1_, x2_, x3_, x4_, x5_, x6_, x7_, x8_, y_]

# def get_lat_summary(data):
#     # Calculate totals grouped by the cluster size
#     grouped = data.groupby(x_, as_index=True)[y_2]
#     _avg = grouped.mean()
#     _stddev = grouped.std()
#     _max = grouped.max()
#     _min = grouped.min()
#     _total = grouped.sum()
#     summary = pandas.DataFrame(index=grouped.groups.keys())
#     summary.index.names = x_
#     summary['average'] = _avg
#     summary['stddev'] = _stddev
#     summary['min'] = _min
#     summary['max'] = _max
#     summary['total'] = _total
#     print("\n\n----------------SUMMARY------------------\n")
#     print(summary)
#     return summary

# def get_summary(data):
#     # Calculate totals grouped by the cluster size
#     grouped = data.groupby(x_, as_index=True)[y_]
#     _avg = grouped.mean()
#     _stddev = grouped.std()
#     _max = grouped.max()
#     _min = grouped.min()
#     _total = grouped.sum()
#     summary = pandas.DataFrame(index=grouped.groups.keys())
#     summary.index.names = x_
#     summary['average'] = _avg
#     summary['stddev'] = _stddev
#     summary['min'] = _min
#     summary['max'] = _max
#     summary['total'] = _total
#     print("\n\n----------------SUMMARY------------------\n")
#     print(summary)
#     return summary

# def print_data_table_wBudget(data):
#     data = data.reset_index()
    
#     to_remove = data[x5_] == 1.0
#     data = data[~to_remove]
    
#     to_remove = data[x2_] != 100
#     data = data[~to_remove]

#     y_data = data['average']
#     nodes_data = data[x4_]
#     p_local_data = data[x5_]
#     lock_data = data[x1_]
#     threads_data = data[x8_]
#     keys_data = data[x2_]
#     rb_data = data[x7_]
#     lb_data = data[x6_]
    
#     print("CSV")
#     print("Lock,Nodes,Keys,P_Local,Threads,R Budget,L Budget,TPut")
#     for nodes, keys, p_local, lock, threads, rb, lb, y in zip(nodes_data, keys_data, p_local_data, lock_data, threads_data, rb_data, lb_data, y_data):
#         print(lock,",",nodes,",",keys,",",p_local,",",threads,",",rb,",",lb,",",y)
    


# def print_data_table(data):
#     data = data.reset_index()
    
#     to_remove = data[x5_] == 1.0
#     data = data[~to_remove]
    
#     to_remove = data[x2_] != 1000
#     data = data[~to_remove]

#     y_data = data['average']
#     nodes_data = data[x4_]
#     p_local_data = data[x5_]
#     lock_data = data[x1_]
#     threads_data = data[x8_]
#     keys_data = data[x2_]
    
#     print("CSV")
#     print("Lock,Nodes,Keys,P_Local,Threads,TPut")
#     for nodes, keys, p_local, lock, threads, y in zip(nodes_data, keys_data, p_local_data, lock_data, threads_data, y_data):
#         print(lock,",",nodes,",",keys,",",p_local,",",threads,",",y)


# def plot_latency(data):
#     print("Plotting latency...")
    
#     columns = ['lock_type', 'experiment_params.num_clients', 'experiment_params.num_threads', 'experiment_params.num_nodes', 
#                'experiment_params.workload.max_key', 'experiment_params.workload.p_local',
#                'experiment_params.remote_budget', 'experiment_params.local_budget', 
#                'results.driver.latency.summary.mean']
#     data = data[columns]
    
#     data['results.driver.latency.summary.mean'] = data['results.driver.latency.summary.mean'].apply(
#         lambda s: [float(x.strip()) for x in s.strip(' []').split(',')])
#     data = data.explode('results.driver.latency.summary.mean')
#     data = data.reset_index(drop=True)

#     # summary = get_lat_summary(data)
#     # summary = summary.reset_index()
#     summary = data
    
#     plocal=[1, .95, .9, .85]
    
#     nodes = [20]
#     threads = [8]
#     keys = [20, 100, 1000]
    
#     # make a grid of subplots with a row for each node number and a column for each key setup
#     fig, axes = plt.subplots(len(plocal), len(keys), figsize=(10, 8))
#     seaborn.set_theme(style='ticks')

#     plt.subplots_adjust(hspace = .75, wspace = 0.4)
    
#     for i, pl in enumerate(plocal):
#         for j, key in enumerate(keys):
#             data = summary[summary['experiment_params.workload.max_key'] == key]
#             data = data[data['experiment_params.num_nodes'] == nodes[0]]
#             data = data[data['experiment_params.workload.p_local'] == pl]
#             data = data[data['experiment_params.num_threads'] == threads[0]]
#             seaborn.ecdfplot(
#                     data=data,
#                     x='results.driver.latency.summary.mean',
#                     stat='proportion',
#                     ax=axes[i][j],
#                     hue='lock_type',
#                     palette="colorblind",
#                     legend=False,
#             )
#             # axes[i][j].set_xlabel('Latency (ns)')
#             axes[i][j].set_title(str(key) + " Keys, " + str(int(pl*100)) + " % Local", fontsize=10)
#              # set 3 ticks on y axis with values auto-chosen
#             axes[i][j].set_yticks((0, .25, .5, .75, 1))
#         # axes[i][0].set_ylabel('Aggregated Throughput (ops/s)', labelpad=20)
        
#     subplot = 'a'
#     for ax in axes.flatten():
#         # ax.legend().remove()    
#         s = '(' + subplot + ')'
#         ax.set_xlabel(s, weight='bold', fontfamily='monospace')
#         subplot = chr(ord(subplot) + 1)
    
#     legend1 = fig.legend(title='Legend', bbox_to_anchor=(.5, 1.04), labels=['Spin', 'MCS', 'ALock'],
#                          loc='upper center', fontsize=9, title_fontsize=11,  markerscale=.3,
#                         ncol=1, columnspacing=1, edgecolor='white', borderpad=0)
#     plt.show()
#     name = os.path.join(FLAGS.figdir, FLAGS.exp, 'latency_plots_n20_t8')
#     filename = name + ".png"
#     dirname = os.path.dirname(filename)
#     os.makedirs(dirname, exist_ok=True)
#     fig.savefig(filename, dpi=300, bbox_extra_artists=(legend1,)
#                 if legend1 is not None else None, bbox_inches='tight')
    
# def plot_spin(summary):
#     global x8_, y_
    
#     # reset index in order to access all fields for hue
#     summary = summary.reset_index()
    
#     # save original data
#     original = summary
    
#     line_color = seaborn.color_palette('colorblind')[2]
    
#     to_remove = summary[x8_] == 98
#     summary = summary[~to_remove]
#     to_remove = summary[x8_] == 102
#     summary = summary[~to_remove]
    
#     data = summary[summary['experiment_params.workload.max_key'] == 1000]
#     data = data[data['experiment_params.num_nodes'] == 1]
#     data = data.reset_index(drop=True)
#     seaborn.lineplot(
#         data=data,
#         x=x8_,
#         y='total',
#         # hue=line_color,
#         style='lock_type',
#         markers=True,
#         markersize=10,
#         color=line_color,
#     )
    
#     plt.ylabel('Total Throughput (ops/s)')
#     plt.xlabel('Threads')
#     plt.title('RDMA Loopback Scalability')
#     plt.legend().remove()
#     plt.show()

    

# def plot_locality_lines(nodes, keys, summary, name):
#     global x8_, y_
            
#     # make a grid of subplots with a row for each node number and a column for each key setup
#     # add 1 to len(keys) for final column of 100p% local for each node config
#     fig, axes = plt.subplots(len(nodes), len(keys)+1, figsize=(12, 8))
#     seaborn.set_theme(style='ticks')
#     markersize = 10
    
#     # make space for a big legend
#     fig.subplots_adjust(top=.8, bottom=.2)


#     # reset index in order to access all fields for hue
#     summary = summary.reset_index()
    
#     # save original data
#     original = summary

#     #filter data to only include desire p_local lines
#     plocal = [.95, .9, .85]
#     summary = summary[summary['experiment_params.workload.p_local'].isin(plocal)]
#     summary = summary.reset_index(drop=True)

#     plt.subplots_adjust(hspace = .6, wspace = 0.25)

#     for i, node in enumerate(nodes):
#         for j, key in enumerate(keys):
#             data = summary[summary['experiment_params.workload.max_key'] == key]
#             data = data[data['experiment_params.num_nodes'] == node]
#             data = data.reset_index(drop=True)
#             seaborn.lineplot(
#                     data=data,
#                     x=x8_,
#                     y='total',
#                     ax=axes[i][j],
#                     hue='lock_type',
#                     style='experiment_params.workload.p_local',
#                     markers=True,
#                     markersize=markersize,
#                     palette="colorblind",
#             )
#             # set y axis to start at 0
#             axes[i][j].set_ylim(0, axes[i][j].get_ylim()[1])
#             # set 3 ticks on y axis with values auto-chosen
#             axes[i][j].set_xticks([4,8,12])
#             # axes[i][j].set_yticks(axes[i][j].get_yticks()[::len(axes[i][j].get_yticks()) // 3])
#             h2, l2 = axes[i][j].get_legend_handles_labels()
#             axes[i][j].set_ylabel('') 
#             axes[i][j].set_xlabel('') 
#             # axes[i][j].set_xlabel('Threads per Node')
#             axes[i][j].set_title(str(key) + " Keys, " + str(node) + " Nodes", fontsize=10)
#         axes[i][0].set_ylabel('Throughput (ops/s)', labelpad=20)

#     # Add final column with 100p local by filtering original data again
#     p100 = original[original['experiment_params.workload.p_local'] == 1.0]
#     p100 = p100.reset_index(drop=True)
    
#     # plot final column with 100p local
#     for i, node in enumerate(nodes):
#         data = p100
#         data = data[data['experiment_params.num_nodes'] == node]
#         data = data.reset_index(drop=True)
#         seaborn.lineplot(
#                 data=data,
#                 x=x8_,
#                 y='total',
#                 ax=axes[i][len(keys)],
#                 hue='lock_type',
#                 style='experiment_params.workload.max_key',
#                 markers=True,
#                 markersize=markersize,
#                 palette="magma",
#         )
#         # set y axis to start at 0
#         axes[i][len(keys)].set_ylim(0, axes[i][len(keys)].get_ylim()[1])
#         # set 3 ticks on y axis with values auto-chosen
#         # axes[i][j].set_yticks(axes[i][j].get_yticks()[::len(axes[i][j].get_yticks()) // 3])
#         axes[i][len(keys)].set_xticks([4,8,12])
#         h3, l3 = axes[i][len(keys)].get_legend_handles_labels()
#         axes[i][len(keys)].set_ylabel('') 
#         axes[i][len(keys)].set_xlabel('') 
#         # axes[i][len(keys)].set_xlabel('Threads per Node')
#         axes[i][len(keys)].set_title("100% Local, " + str(node) + " Nodes", fontsize=10)
       
#     # Legend creation
#     # This is a hacky way to change the labels in the legend
#     l2[0] = 'Lock Type'
#     l2[4] = 'Percent Local'
#     for h in h2:
#         h.set_markersize(24)
#         h.set_linewidth(3)
#     labels_handles = {}
#     labels_handles.update(dict(zip(l2, h2)))
    
#     subplot = 'a'
#     for ax in axes.flatten():
#         ax.legend().remove()    
#         s = '(' + subplot + ')'
#         ax.set_xlabel(s, weight='bold', fontfamily='monospace')
#         subplot = chr(ord(subplot) + 1)
        
    
#     # legend1 = fig.legend(h2, l2, bbox_to_anchor=(0, 1.02, 1, .2),
#     #     loc='lower left', fontsize=9, title_fontsize=11, title='Legend', markerscale=.3,
#     #     ncol=2, columnspacing=1, edgecolor='white', borderpad=0)
    
#     # Legend for 100p plot
#     # This is a hacky way to change the labels in the legend
#     l3[0] = 'Lock Type'
#     l3[4] = 'Keys'
#     for h in h3:
#         h.set_markersize(24)
#         h.set_linewidth(3)
#     labels_handles = {}
#     labels_handles.update(dict(zip(l3, h3)))
   
        
#     fig.suptitle('', fontsize=12)
    
    
#     # legend2 = fig.legend(h3, l3, bbox_to_anchor=(.9, 1.12),
#     #     loc='upper right', fontsize=9, title_fontsize=11, title='100% Local Legend', markerscale=.3,
#     #     ncol=2, columnspacing=1, edgecolor='white', borderpad=1)

#     filename = name + ".png"
#     dirname = os.path.dirname(filename)
#     os.makedirs(dirname, exist_ok=True)
#     # fig.savefig(filename, dpi=300, bbox_extra_artists=(legend1,)
#     #             if legend1 is not None else None, bbox_inches='tight')
#     fig.savefig(filename, dpi=300, bbox_inches='tight')
    
#     # plt.tight_layout()
    
#     # Adjust layout to prevent clipping of the legend
#     # plt.tight_layout(rect=[0, 0, 1, 0.96])
#     plt.show()

    
# def plot(datafile, lock_type):
#     data = pandas.read_csv(datafile)
 
#     alock = data[data['experiment_params.name'].str.count("alock.*") == 1]
#     alock['lock_type'] = 'ALock'
#     mcs = data[data['experiment_params.name'].str.count("mcs.*") == 1]
#     mcs['lock_type'] = 'MCS'
#     spin = data[data['experiment_params.name'].str.count("spin.*") == 1]
#     spin['lock_type'] = 'Spin'
 
#     data = pandas.concat([alock, mcs, spin])
    
#     plot_latency(data)
    
#     columns = ['lock_type', 'experiment_params.num_threads', 'experiment_params.num_clients', 'experiment_params.num_nodes', 
#                'experiment_params.workload.max_key', 'experiment_params.workload.p_local', 
#                'experiment_params.remote_budget', 'experiment_params.local_budget', 'results.driver.qps.summary.mean']
#     data = data[columns]
#     print(data)
#     data['results.driver.qps.summary.mean'] = data['results.driver.qps.summary.mean'].apply(
#         lambda s: [float(x.strip()) for x in s.strip(' []').split(',')])
#     data = data.explode('results.driver.qps.summary.mean')
#     data = data.reset_index(drop=True)

#     summary = get_summary(data)
 
#     nodes = [5, 10, 20]
#     keys = [20, 100, 1000]
    
    
#     # plot_spin(summary)
    
#     # print_data_table(summary)
#     # print_data_table_wBudget(summary)
#     # plot_budget2(nodes, keys, summary, 'test')s
    
#     # plot_locality_lines(nodes, keys, summary, os.path.join(FLAGS.figdir, FLAGS.exp, 'paper_plots'))
    
#     # plocal = [.95, .9, .85]
#     # plot_budget(nodes, plocal, summary, os.path.join(FLAGS.figdir, FLAGS.exp, 'local_v_remote_test'))
 