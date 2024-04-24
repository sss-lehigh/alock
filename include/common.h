#pragma once

#include <algorithm>

#include "experiment.h"

inline static void cpu_relax() { asm volatile("pause\n" : : : "memory"); }

#define CACHELINE_SIZE 64

// Used for tracking status of descriptors
#define UNLOCKED 0
#define LOCKED 1

auto calcLocalNodeRange(const BenchmarkParams &params, uint16_t id){
  int total_keys = params.max_key - params.min_key + 1;
  //! here is where the truncation happens that ruins everything
  int keys_per_node = total_keys / params.node_count;
  // map  peer id to phsyical node
  int nodeid = floor(id/params.thread_count);
  int low = ((nodeid) * keys_per_node) + 1;
  int high = low + keys_per_node - 1;
  if (nodeid == 0){
    low = params.min_key;
  }
  if (nodeid == (params.node_count-1)){
    high = params.max_key;
  }
  // return pair of node's entire local key range
  auto result = std::make_pair(low, high);
  return result;
}

auto calcThreadKeyRange(const BenchmarkParams &params, uint16_t id){
  //map  peer id to phsyical node
  int nodeid = floor(id/params.thread_count); 
  auto range = calcLocalNodeRange(params, id);

  int offset = id - (nodeid * params.thread_count);

  int total_keys = params.max_key - params.min_key + 1;
  //! TRUNCATION HERE RUINS EVERYTHING
  int keys_per_thread = total_keys / (params.node_count * params.thread_count);

  int low = (offset * keys_per_thread) + range.first;
  int high = low + keys_per_thread - 1;

  if (offset == 0) {
    low = range.first;
  }
  if (offset == params.thread_count -1) {
    high = range.second;
  }
  if (id == ((params.thread_count * params.node_count) - 1)){
    high = params.max_key;
  }

  // return pair of key range to be populated by thread
  auto result = std::make_pair(low, high);
  return result;
}

