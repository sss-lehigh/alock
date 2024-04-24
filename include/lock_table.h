#pragma once

#include <cstdint>
#include "common.h"
#include "setup.h"
#include <remus/rdma/rdma.h>

template <typename V>
struct alignas(128) Entry {
  V lock;
  uint8_t pad[CACHELINE_SIZE - sizeof(lock)];
  uint64_t value;
  uint8_t pad1[CACHELINE_SIZE - sizeof(value)];
};

// Class that determines which node a given key is on based on the range it falls into
template <typename K, typename V>
class LockTable {
 using key_type = K; // some int (uint16)
 using lock_type = V; // ALock or MCS or Spin
 using root_type = remus::rdma::rdma_ptr<lock_type>;

 public:
  LockTable(Peer self, std::shared_ptr<rdma_capability> pool)
    :   self_(self),
        node_id_(self.id),
        lock_pool_(pool) {}

  root_type AllocateLocks(const key_type& min_key, const key_type& max_key){
    auto lock = lock_pool_->Allocate<lock_type>();
    root_lock_ptr_ = lock;
    REMUS_TRACE("Allocated root lock for key {}", static_cast<key_type>(min_key));
    // Allocate one lock per key
    for (auto i = min_key + 1; i <= max_key; i++){
        auto __attribute__ ((unused)) lock = lock_pool_->Allocate<lock_type>();
        REMUS_TRACE("Allocated lock for key {}", i);
    }
    REMUS_DEBUG("Root Ptr on Node {} is {:x}", node_id_, static_cast<uint64_t>(root_lock_ptr_));
    // return pointer to first lock in table
    return root_lock_ptr_;
  }

 private:
  Peer self_;
  const uint32_t node_id_;
  std::shared_ptr<rdma_capability> lock_pool_;
  root_type root_lock_ptr_;
  key_type max_key_;
  key_type min_key_;
};
