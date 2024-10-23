#pragma once

#include <remus/util/cli.h>

/// An object to hold the experimental params
/// @param node_id The node's id. (nodeX in cloudlab should have X in this option)
/// @param runtime How long to run the experiment for
/// @param unlimited_stream If the stream should be endless, stopping after runtime
/// @param topology If the experiment should use the topology stream, or random stream by default
/// @param op_count How many operations to run. Only valid if not unlimited_stream
/// @param region_size How big the memory region should be in 2^x bytes
/// @param thread_count How many threads to spawn with the operations
/// @param node_count How many nodes are in the experiment
/// @param qp_max The max number of queue pairs to allocate for the experiment.
/// @param p_local; Percentage of operations thare are local
/// @param min_key The lower limit of the key range for operations
/// @param max_key The upper limit of the key range for operations
/// @param local_budget //Inital budget for local cohort in ALock
/// @param remote_budget //Inital budget for remote cohort in ALock
class BenchmarkParams {
public:
    /// The node's id. (nodeX in cloudlab should have X in this option)
    int node_id;
    /// How long to run the experiment for. Only valid if unlimited_stream
    int runtime;
    /// If the stream should be endless, stopping after runtime
    bool unlimited_stream;
    //If the experiment should use the topology stream, or random stream by default
    bool topology;
    /// How many operations to run. Only valid if not unlimited_stream
    int op_count;
    /// How big the memory region should be in 2^x bytes
    int region_size;
    /// How many threads to spawn with the operations
    int thread_count;
    /// How many nodes are in the experiment
    int node_count;
    /// The max number of queue pairs to allocate for the experiment.
    int qp_max;
    // Percentage of operations that are local
    int p_local;
    /// The lower limit of the key range for operations
    int min_key;
    /// The upper limit of the key range for operations
    int max_key; 
    //Inital budget for local cohort in ALock
    int local_budget;
    //Inital budget for remote cohort in ALock
    int remote_budget;

    BenchmarkParams(){}

    BenchmarkParams(remus::util::ArgMap args){
        node_id = args.iget("--node_id");
        runtime = args.iget("--runtime");
        unlimited_stream = args.bget("--unlimited_stream");
        topology = args.bget("--topology");
        op_count = args.iget("--op_count");
        region_size = args.iget("--region_size");
        thread_count = args.iget("--thread_count");
        node_count = args.iget("--node_count");
        qp_max = args.iget("--qp_max");
        p_local = args.iget("--p_local");
        min_key = args.iget("--min_key");
        max_key = args.iget("--max_key");
        local_budget = args.iget("--local_budget");
        remote_budget = args.iget("--remote_budget");
    }
};

class Result {
public:
    BenchmarkParams params;
    int count = 0;
    int runtime_ns = 0;
    std::string units = "";
    double mean = 0;
    double stdev = 0;
    double min = 0;
    double p50 = 0;
    double p90 = 0;
    double p95 = 0;
    double p99 = 0;
    double p999 = 0;
    double max = 0;
   
    Result() {}
    Result(BenchmarkParams params_) : params(params_) {}

    static const std::string result_as_string_header() {
        return "node_id,runtime,unlimited_stream,topology,op_count,region_size,thread_count,node_count,qp_max,p_local,min_key,max_key,localb,remoteb,count,runtime_ns,units,mean,stdev,min,p50,p90,p95,p99,p999,max\n";
    }

    std::string result_as_string(){
        std::string builder = "";
        builder += std::to_string(params.node_id) + ",";
        builder += std::to_string(params.runtime) + ",";
        builder += std::to_string(params.unlimited_stream) + ",";
        builder += std::to_string(params.topology) + ",";
        builder += std::to_string(params.op_count) + ",";
        builder += std::to_string(params.region_size) + ",";
        builder += std::to_string(params.thread_count) + ",";
        builder += std::to_string(params.node_count) + ",";
        builder += std::to_string(params.qp_max) + ",";
        builder += std::to_string(params.p_local) + ",";
        builder += std::to_string(params.min_key) + ",";
        builder += std::to_string(params.max_key) + ",";
        builder += std::to_string(params.local_budget) + ",";
        builder += std::to_string(params.remote_budget) + ",";
        builder += std::to_string(count) + ",";
        builder += std::to_string(runtime_ns) + ",";
        builder += units + ",";
        builder += std::to_string(mean) + ",";
        builder += std::to_string(stdev) + ",";
        builder += std::to_string(min) + ",";
        builder += std::to_string(p50) + ",";
        builder += std::to_string(p90) + ",";
        builder += std::to_string(p95) + ",";
        builder += std::to_string(p99) + ",";
        builder += std::to_string(p999) + ",";
        builder += std::to_string(max);
        return builder + "\n";
    }

    std::string result_as_debug_string(){
        std::string builder = "Experimental Result {\n";
        builder += "\tParams {\n";
        builder += "\t\tnode_id: " + std::to_string(params.node_id) + "\n";
        builder += "\t\truntime: " + std::to_string(params.runtime) + "\n";
        builder += "\t\tunlimited_stream: " + std::to_string(params.unlimited_stream) + "\n";
        builder += "\t\ttopology: " + std::to_string(params.topology) + "\n";
        builder += "\t\top_count: " + std::to_string(params.op_count) + "\n";
        builder += "\t\tregion_size: " + std::to_string(params.region_size) + "\n";
        builder += "\t\tthread_count: " + std::to_string(params.thread_count) + "\n";
        builder += "\t\tnode_count: " + std::to_string(params.node_count) + "\n";
        builder += "\t\tqp_max: " + std::to_string(params.qp_max) + "\n";
        builder += "\t\tp_local: " + std::to_string(params.p_local) + "\n";
        builder += "\t\tmin_key: " + std::to_string(params.min_key) + "\n";
        builder += "\t\tmax_key: " + std::to_string(params.max_key) + "\n";
        builder += "\t\tlocal_budget: " + std::to_string(params.local_budget) + "\n";
        builder += "\t\tremote_budget: " + std::to_string(params.remote_budget) + "\n";
        builder += "\t}\n\tResult {\n";
        builder += "\t\tcount:" + std::to_string(count) + "\n";
        builder += "\t\truntime_ns:" + std::to_string(runtime_ns) + "\n";
        builder += "\t\tunits:" + units + "\n";
        builder += "\t\tmean:" + std::to_string(mean) + "\n";
        builder += "\t\tstdev:" + std::to_string(stdev) + "\n";
        builder += "\t\tmin:" + std::to_string(min) + "\n";
        builder += "\t\tp50:" + std::to_string(p50) + "\n";
        builder += "\t\tp90:" + std::to_string(p90) + "\n";
        builder += "\t\tp95:" + std::to_string(p95) + "\n";
        builder += "\t\tp99:" + std::to_string(p99) + "\n";
        builder += "\t\tp999:" + std::to_string(p999) + "\n";
        builder += "\t\tmax:" + std::to_string(max) + "\n";
        builder += "\t}\n";
        return builder + "}";
    }
};
