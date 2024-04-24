#pragma once

#include <infiniband/verbs.h>

#include <atomic>
#include <cstdint>
#include <memory>
#include <thread>

#include <remus/rdma/rdma.h>
#include "common.h"

using namespace remus::rdma;

// Uses MCS algorithm from page 10 of: "Algorithms for Scalable Synchronization on Shared-Memory Multiprocessor" 
// by John Mellor-Crummey and Michael L. Scott https://www.cs.rochester.edu/u/scott/papers/1991_TOCS_synch.pdf 

#define NEXT_PTR_OFFSET 32
#define UNLOCKED 0
#define LOCKED 1

struct alignas(64) RdmaMcsLock          {
  uint8_t locked{0};
  uint8_t pad1[NEXT_PTR_OFFSET - sizeof(locked)];
  rdma_ptr<RdmaMcsLock> next{nullptr};
  uint8_t pad2[CACHELINE_SIZE - NEXT_PTR_OFFSET - sizeof(uintptr_t)];
};
static_assert(alignof(RdmaMcsLock) == 64);
static_assert(sizeof(RdmaMcsLock) == 64);

class RdmaMcsLockHandle {
public: 
  RdmaMcsLockHandle(Peer self, std::shared_ptr<rdma_capability> pool, std::unordered_set<int> local_clients, int64_t local_budget, int64_t remote_budget)
      : self_(self), pool_(pool), local_clients_(local_clients), lock_count_(0) {}

  remus::util::Status Init() {    
    // Reserve remote memory for the local descriptor.
    desc_pointer_ = pool_->Allocate<RdmaMcsLock>();
    descriptor_ = reinterpret_cast<RdmaMcsLock *>(desc_pointer_.address());
    REMUS_DEBUG("RdmaMcsLock @ {:x}", static_cast<uint64_t>(desc_pointer_));
    //Used as preallocated memory for RDMA writes
    prealloc_ = pool_->Allocate<rdma_ptr<RdmaMcsLock>>();

    std::atomic_thread_fence(std::memory_order_release);
    return remus::util::Status::Ok();
  }

  uint64_t GetReaqCount(){
    return 0;
  }

  remus::metrics::MetricProto GetLocalLatSummary() { 
    remus::metrics::Summary<double> local("local_lat", "ns", 1000);
    return local.ToProto(); 
  }
  remus::metrics::MetricProto GetRemoteLatSummary() { 
    remus::metrics::Summary<double> remote("local_lat", "ns", 1000);
    return remote.ToProto(); 
  }

  bool IsLocked() {
    if (is_host_) {
      //since we are the host, get the local addr and just interpret the value
      return std::to_address(*(std::to_address(tail_pointer_))) != 0;
    } else {
      // read in value of host's lock ptr
      auto remote = pool_->Read<rdma_ptr<RdmaMcsLock>>(tail_pointer_);
      // store result of if its locked
      auto locked = static_cast<uint64_t>(*(std::to_address(remote))) != 0;
      // deallocate the ptr used as a landing spot for reading in (which is created in Read)
      auto ptr =
          rdma_ptr<rdma_ptr<RdmaMcsLock>>{self_.id, std::to_address(remote)};
      pool_->Deallocate(ptr);
      return locked;
    }
  }

  void Lock(rdma_ptr<RdmaMcsLock> lock) {
    lock_ = lock;
    REMUS_DEBUG("lock_: {:x}", static_cast<uint64_t>(lock_));
    tail_pointer_ = decltype(tail_pointer_)(lock.id(), lock.address() + NEXT_PTR_OFFSET);
    REMUS_DEBUG("tail_pointer_: {:x}", static_cast<uint64_t>(tail_pointer_));
    // Set local descriptor to initial values
    descriptor_->locked = UNLOCKED;
    descriptor_->next = nullptr;
    // swap local descriptor in at the address of the hosts lock pointer
    auto prev =
        pool_->AtomicSwap(tail_pointer_, static_cast<uint64_t>(desc_pointer_));
    if (prev != nullptr) { //someone else has the lock
      descriptor_->locked = LOCKED; //set descriptor to locked to indicate we are waiting for 
      auto temp_ptr = rdma_ptr<uint8_t>(prev);
      temp_ptr += NEXT_PTR_OFFSET; //temp_ptr = next field of the current tail's descriptor
      // make prev point to the current tail descriptor's next pointer
      prev = rdma_ptr<RdmaMcsLock>(temp_ptr);
      // set the address of the current tail's next field = to the addr of our local descriptor
      pool_->Write<rdma_ptr<RdmaMcsLock>>(
          static_cast<rdma_ptr<rdma_ptr<RdmaMcsLock>>>(prev), desc_pointer_,
          prealloc_);
      REMUS_DEBUG("[Lock] Enqueued: {} --> (id={})",
                static_cast<uint64_t>(prev.id()),
                static_cast<uint64_t>(desc_pointer_.id()));
      // spins, waits for Unlock() to unlock our desriptor and let us enter the CS
      while (descriptor_->locked == LOCKED) {
        cpu_relax();
      }
    } 
    // Once here, we can enter the critical section
    REMUS_DEBUG("[Lock] Acquired: prev={:x}, locked={:x} (id={})",
              static_cast<uint64_t>(prev), descriptor_->locked,
              static_cast<uint64_t>(desc_pointer_.id()));
    //  make sure Lock operation finished
    std::atomic_thread_fence(std::memory_order_acquire);
    // lock_count_++;
  }

  void Unlock(rdma_ptr<RdmaMcsLock> lock) {
    REMUS_ASSERT(lock.address() == lock_.address(), "Attempting to unlock lock that is not locked.");
    std::atomic_thread_fence(std::memory_order_release);
    // if tail_pointer_ == my desc (we are the tail), set it to 0 to unlock
    // otherwise, someone else is contending for lock and we want to give it to them
    // try to swap in a 0 to unlock the descriptor at the addr of lock_pointer, which we expect to currently be equal to our descriptor
    auto prev = pool_->CompareAndSwap(tail_pointer_,
                                    static_cast<uint64_t>(desc_pointer_), 0);
    if (prev != desc_pointer_) {  // if the lock at tail_pointer_ was not equal to our descriptor
      // attempt to hand the lock to prev
      // spin while 
      while (descriptor_->next == nullptr);
      std::atomic_thread_fence(std::memory_order_acquire);
      // gets a pointer to the next descriptor object
      auto next = const_cast<rdma_ptr<RdmaMcsLock> &>(descriptor_->next);
      //writes a 0 to the next descriptors locked field which lets it know it has the lock now
      pool_->Write<uint64_t>(static_cast<rdma_ptr<uint64_t>>(next),
                            UNLOCKED,
                            static_cast<rdma_ptr<uint64_t>>(prealloc_));
    } 
    REMUS_DEBUG("[Unlock] Unlocked (id={}), locked={:x}",
                static_cast<uint64_t>(desc_pointer_.id()),
                descriptor_->locked);
  }

private: 
  uint64_t lock_count_; 
  bool is_host_;
 
  Peer self_;
  std::shared_ptr<rdma_capability> pool_; //reference to pool object, so all descriptors in same pool
  std::unordered_set<int> local_clients_;

  // Pointer to the A_Lock object, store address in constructor
  // rdma_ptr<A_Lock> glock_; 

  // this is pointing to the next field of the lock on the host
  rdma_ptr<RdmaMcsLock> lock_;
  rdma_ptr<rdma_ptr<RdmaMcsLock>> tail_pointer_; //this is supposed to be the tail on the host
  
  // Used for rdma writes to the next feld
  rdma_ptr<rdma_ptr<RdmaMcsLock>> prealloc_;

  //Pointer to desc to allow it to be read/write via rdma
  rdma_ptr<RdmaMcsLock> desc_pointer_;
  volatile RdmaMcsLock *descriptor_;


};

