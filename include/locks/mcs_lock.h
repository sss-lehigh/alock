#pragma once

#include <infiniband/verbs.h>

#include <assert.h>

#include <atomic>
#include <cstdint>
#include <iostream>
#include <thread>

namespace X {

class McsLock {
 public:
  struct Descriptor {
    int8_t budget{-1}; //budget == -1 indicates its locked, unlocked and passed off when it can proceed to critical section
    uint8_t pad1[CACHELINE_SIZE - sizeof(budget)];
    Descriptor* next{nullptr};
    uint8_t pad2[CACHELINE_SIZE - sizeof(next)];
  };
  static_assert(sizeof(Descriptor) == 2 * CACHELINE_SIZE, "");

  void Lock() {
    // to acquire the lock a thread atomically appends its own local node at the
    // tail of the list returning tail's previous contents
    auto prior_node = tail_.exchange(&local_desc_, std::memory_order_acquire);
    if (prior_node != nullptr) {
      local_desc_.budget = -1;
      // if the list was not previously empty, it sets the predecessor’s next
      // field to refer to its own local node
      prior_node->next = &local_desc_;
      // thread then spins on its local locked field, waiting until its
      // predecessor sets this field to false
      while (local_desc_.budget < 0) cpu_relax();

      // If budget exceeded, then reinitialize.
      if (local_desc_.budget == 0) {
        local_desc_.budget = kInitBudget;
      }
    }
    // now first in the queue, own the lock and enter the critical section...
  }
  void Unlock() {
    //...leave the critical section
    // check whether this thread's local node’s next field is null
    if (local_desc_.next == nullptr) {
      // if so, then either:
      //  1. no other thread is contending for the lock
      //  2. there is a race condition with another thread about to
      // to distinguish between these cases atomic compare exchange the tail field
      // if the call succeeds, then no other thread is trying to acquire the lock,
      // tail is set to nullptr, and unlock() returns
      Descriptor* p = &local_desc_;
      if (tail_.compare_exchange_strong(p, nullptr, std::memory_order_release,
                                        std::memory_order_relaxed)) {
        return;
      }
      // otherwise, another thread is in the process of trying to acquire the
      // lock, so spins waiting for it to finish
      while (local_desc_.next == nullptr) {
      };
    }
    // in either case, once the successor has appeared, the unlock() method sets
    // its successor’s locked field to false, indicating that the lock is now free
    local_desc_.next->budget = local_desc_.budget - 1;
    // at this point no other thread can access this node and it can be reused
    local_desc_.next = nullptr;
  }
  bool IsLocked() { return tail_ != nullptr; }

 private:
  static constexpr uint32_t kInitBudget = 5;
  std::atomic<Descriptor*> tail_{nullptr};
  static thread_local Descriptor local_desc_ = Descriptor{};
};

}  // namespace X
