#pragma once

#include <algorithm>
#include <future>
#include <limits>
#include <random>
#include <barrier>

#include "remus/logging/logging.h"
#include "remus/rdma/rdma.h"
#include "node.h"
#include "setup.h"
#include "common.h"
#include "experiment.h"

using namespace remus::rdma;

template <class Operation> class Client {

 public:

  ~Client() = default;

  static std::unique_ptr<Client> Create(const Peer &self, BenchmarkParams params, std::barrier<> *barrier,
          std::shared_ptr<rdma_capability> pool, root_map* root_ptr_map, std::unordered_set<int> locals) {
    return std::unique_ptr<Client>(new Client(self, params, barrier, pool, root_ptr_map, locals));
  }

  static void signal_handler(int signal) { 
    // Wait for all clients to be done shutting down
    REMUS_INFO("\nSIGNAL HANDLER\n");
    std::this_thread::sleep_for(std::chrono::seconds(2));
    exit(signal);
  }

  static remus::util::StatusVal<remus::metrics::WorkloadDriverResult> Run(std::unique_ptr<Client> client, const BenchmarkParams& params) {
    //Signal Handler
    signal(SIGINT, signal_handler);

    //Sleep for a bit in case all clients aren't done with startup/connecting
    std::this_thread::sleep_for(std::chrono::seconds(2));

    auto *client_ptr = client.get();

    std::unique_ptr<remus::PrefilledStream<key_type>> stream;
    if (params.topology){
      REMUS_INFO("Using Node Topology Stream");
      stream = createNodeTopOpStream(params, client_ptr->self_);
    } else {
      REMUS_INFO("Using Random Stream");
      stream = createRandomOpStream(params, client_ptr->self_);
    }
    

    std::barrier<>* barr = client_ptr->barrier_;
    barr->arrive_and_wait();
    REMUS_INFO("Starting client {}...", client_ptr->self_.id);
    // Create and start the workload driver (also starts client).
    auto driver = remus::WorkloadDriver<Client, key_type>::Create(std::move(client), std::move(stream), std::chrono::milliseconds(10));
    OK_OR_FAIL(driver->Start());

    // Sleep while driver is running
    auto runtime = std::chrono::seconds(params.runtime);
    // REMUS_INFO("Running workload for {}s", runtime);
    std::this_thread::sleep_for(runtime);

    REMUS_INFO("Stopping client {}...", client_ptr->self_.id);
    barr->arrive_and_wait();
    OK_OR_FAIL(driver->Stop());
    REMUS_INFO("CLIENT :: Driver generated {}", driver->ToString());
    // Output results.
    // Sleep for a hot sec to let the node receive the messages sent by the
    // clients before disconnecting.
    // (see https://github.com/jacnel/project-x/issues/15)
    std::this_thread::sleep_for(std::chrono::milliseconds(1500));
    return {remus::util::Status::Ok(), driver->ToMetrics()};
  }

  rdma_ptr<LockType> calcLockAddr(const key_type &key){
    float n = float(params_.node_count * params_.thread_count);
    float a = params_.min_key;
    float b = params_.max_key;
    float c = n/(b-a);
    // determine node that the key is on with a lookup function 
    // inspired by LIT
    int x = int(std::floor(c*(key-a)));
    uint64_t nid = std::min(int(std::max(x, 0)), int(n-1));
    REMUS_TRACE("Key {} is on Node {}", key, nid);
    std::pair<key_type, key_type> range = calcThreadKeyRange(params_, nid);
    key_type min_key = range.first;
    key_type max_key = range.second; 
    // get root lock pointer of correct node
    root_type root_ptr = root_ptrs_->at(nid);
    // calculate address of desired key and return 
    auto diff = key - min_key;
    auto bytes_to_jump = lock_byte_size_ * diff;
    auto temp_ptr = remus::rdma::rdma_ptr<uint8_t>(root_ptr);
    temp_ptr -= bytes_to_jump;
    auto lock_ptr = root_type(temp_ptr);
    return lock_ptr;
  }
  
  remus::util::Status Start() {
    REMUS_DEBUG("Starting Client...");
    pool_->RegisterThread(); //Register this client thread with memory pool
    auto status = lock_handle_.Init();
    OK_OR_FAIL(status);
    if (barrier_ != nullptr)
      barrier_->arrive_and_wait(); //waits for all clients to init lock handle
    return status;
  }

  remus::util::Status Apply(const key_type &op) {
    REMUS_DEBUG("Client {} attempting to lock key {}", self_.id, op);    
    rdma_ptr<LockType> lock_addr = calcLockAddr(op);
    REMUS_TRACE("Address for lock is {:x}", static_cast<uint64_t>(lock_addr));
    lock_handle_.Lock(lock_addr);
    std::atomic_thread_fence(std::memory_order_release);
    // auto start = std::chrono::system_clocknow();
    // if (params_.workload().has_think_time_ns()) {
    //   while (std::chrono::system_clocknow() - start <
    //          std::chrono::nanoseconds(params_.workload().think_time_ns()))
    //    ;
    // }
    // REMUS_TRACE("Client {} unlocking key {}...", self_.id, op);
    // lock_handle_.Unlock(lock_addr);
    return remus::util::Status::Ok();
  }

    
  remus::util::Status Stop() {
    REMUS_INFO("Stopping...");
    barrier_->arrive_and_wait();
    return remus::util::Status::Ok();
  }

 private:
  Client(const Peer &self, BenchmarkParams params, std::barrier<> *barrier,
          std::shared_ptr<rdma_capability> pool, root_map* root_ptr_map, std::unordered_set<int> locals)
      : self_(self),
        params_(params),
        barrier_(barrier),
        pool_(pool),
        root_ptrs_(root_ptr_map),
        local_clients_(locals),
        lock_handle_(self, pool_, locals, params.local_budget, params.remote_budget) {}

  const Peer self_;
  const BenchmarkParams params_;
  std::barrier<>* barrier_;

  std::shared_ptr<rdma_capability> pool_;
  LockHandle lock_handle_; //Handle to interact with descriptors, one per worker
  root_map* root_ptrs_;
  std::unordered_set<int> local_clients_;
  
  // For generating a random key to lock if stream doesnt work
  std::random_device rd_;
  std::default_random_engine rand_;
};

