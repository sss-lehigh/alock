#pragma once

#include <infiniband/verbs.h>

#include <atomic>
#include <bitset>
#include <cstdint>
#include <memory>
#include <thread>
#include <vector>

#include <remus/rdma/rdma.h>

#include "common.h"

using namespace remus::rdma;

//? Note: Uncomment this line to use override local keys to use RDMA ops
// #define REMOTE_ONLY

#define LOCAL_VICTIM  1
#define REMOTE_VICTIM 2

#define NEXT_PTR_OFFSET 32
#define TAIL_PTR_OFFSET 16
#define VICTIM_OFFSET 32

struct alignas(64) RemoteDescriptor {
    int64_t budget = -1;
    uint8_t pad1[NEXT_PTR_OFFSET - sizeof(budget)];
    rdma_ptr<RemoteDescriptor> next = nullptr;
    uint8_t pad2[CACHELINE_SIZE - NEXT_PTR_OFFSET - sizeof(next)];
};
static_assert(alignof(RemoteDescriptor) == CACHELINE_SIZE);
static_assert(sizeof(RemoteDescriptor) == CACHELINE_SIZE);

struct alignas(64) LocalDescriptor {
    int64_t budget = -1;//budget == -1 indicates its locked, unlocked and passed off when it can proceed to critical section
    uint8_t pad1[NEXT_PTR_OFFSET - sizeof(budget)];
    LocalDescriptor* next = nullptr;
    uint8_t pad2[CACHELINE_SIZE - NEXT_PTR_OFFSET - sizeof(next)];
};
static_assert(alignof(LocalDescriptor) == CACHELINE_SIZE);
static_assert(sizeof(LocalDescriptor) == CACHELINE_SIZE);

struct alignas(64) ALock {
    // pointer to the pointer of the remote tail
    rdma_ptr<RemoteDescriptor> r_tail = nullptr;
    // pad so local tail starts at addr+16
    uint8_t pad1[TAIL_PTR_OFFSET - sizeof(r_tail)]; 
    // pointer to the local tail
    rdma_ptr<LocalDescriptor> l_tail = nullptr;
    // pad so victim starts at addr+32
    uint8_t pad2[VICTIM_OFFSET - TAIL_PTR_OFFSET - sizeof(l_tail)]; 
    // cohort id of the victim
    uint64_t victim = 0; 
    uint8_t pad3[CACHELINE_SIZE - VICTIM_OFFSET - sizeof(victim)]; 
};

static_assert(alignof(ALock) == CACHELINE_SIZE);
static_assert(sizeof(ALock) == CACHELINE_SIZE);

class ALockHandle {

public: 

  ALockHandle(Peer self, std::shared_ptr<rdma_capability> pool, std::unordered_set<int> local_clients, int64_t local_budget, int64_t remote_budget) 
  : self_(self), pool_(pool), local_clients_(local_clients), local_budget_(local_budget), remote_budget_(remote_budget) {}
   
  remus::util::Status Init() {
    r_desc_pointer_ = pool_->Allocate<RemoteDescriptor>();
    r_desc_ = reinterpret_cast<RemoteDescriptor *>(r_desc_pointer_.address());
    REMUS_DEBUG("Node {}: RemoteDescriptor @ {:x}", self_.id, static_cast<uint64_t>(r_desc_pointer_));

    l_desc_pointer_ = pool_->Allocate<LocalDescriptor>();
    l_desc_ = *l_desc_pointer_;
    REMUS_DEBUG("Node {}: LocalDescriptor @ {:x}", self_.id, static_cast<uint64_t>(l_desc_pointer_));

    // Make sure remote and local descriptors are done allocating
    std::atomic_thread_fence(std::memory_order_release);

    //Used as preallocated memory for RDMA reads/writes
    prealloc_ = pool_->Allocate<ALock>();
    r_prealloc_ = pool_->Allocate<rdma_ptr<RemoteDescriptor>>();

    return remus::util::Status::Ok();
  }

  uint64_t GetReaqCount(){
    return reaq_count_;
  }
 
  void Lock(rdma_ptr<ALock> alock){
    REMUS_ASSERT(a_lock_pointer_ == nullptr, "Attempting to lock handle that is already locked.");
    a_lock_pointer_ = alock;
    r_tail_ = decltype(r_tail_)(alock.id(), alock.address());
    r_l_tail_ = decltype(r_l_tail_)(alock.id(), alock.address() + TAIL_PTR_OFFSET);
    r_victim_ = decltype(r_victim_)(alock.id(), alock.address() + VICTIM_OFFSET);  
    REMUS_TRACE("r_tail_ addr: {:x}, val: {:x}", static_cast<uint64_t>(r_tail_), static_cast<uint64_t>(*r_tail_));
    REMUS_TRACE("r_l_tail_ addr: {:x} val: {:x}", static_cast<uint64_t>(r_l_tail_),  static_cast<uint64_t>(*r_l_tail_));
    REMUS_TRACE("r_victim_ addr: {:x} val: {}", static_cast<uint64_t>(r_victim_),  static_cast<uint64_t>(*r_victim_));
    
    #ifdef REMOTE_ONLY 
      is_local_ = false;
      RemoteLock();
    #else
      if (local_clients_.contains(a_lock_pointer_.id())){
        is_local_ = true;
        REMUS_DEBUG("Client {} is_local_ : {}", self_.id, is_local_);
        auto lock = (ALock*)alock.address();
        l_r_tail_ = reinterpret_cast<uint64_t*>(&lock->r_tail);
        l_l_tail_ = reinterpret_cast<uint64_t*>(&lock->l_tail);
        l_victim_ = reinterpret_cast<uint64_t*>(&lock->victim);
        REMUS_DEBUG("l_r_tail_ is {:x}", *l_r_tail_);
        REMUS_DEBUG("l_l_tail_ is {:x}", *l_l_tail_);
        REMUS_DEBUG("l_victim_ is {}", *l_victim_);
        LocalLock();
      } else {
        is_local_ = false;
        RemoteLock();
      }
    #endif
    // lock_count_++;
  }

  void Unlock(rdma_ptr<ALock> alock){
    // REMUS_ASSERT(alock.address() == a_lock_pointer_.address(), "Attempting to unlock alock that is not locked.");
    if (is_local_){
      LocalUnlock();
    } else {
      RemoteUnlock();
    }
    std::atomic_thread_fence(std::memory_order_release);
    a_lock_pointer_ = nullptr;
  }

  void Reacquire(){
    if (is_local_) {
      REMUS_DEBUG("REACQUIRE1 on {}", self_.id);
      LocalPetersons();
    } else {
      REMUS_DEBUG("REACQUIRE2 on {}", self_.id);
      RemotePetersons();
    }
    std::atomic_thread_fence(std::memory_order_release);
    // reaq_count_++;
  }

private: 

  bool inline IsLocked() {
    return a_lock_pointer_ != nullptr;
  }

  inline void LocalPetersons(){
    REMUS_DEBUG("Client {} setting local to victim", self_.id);
    //set local to victim
    REMUS_DEBUG("l_victim {:x}", *l_victim_);
    auto prev = __atomic_exchange_n(l_victim_, LOCAL_VICTIM, __ATOMIC_SEQ_CST);
    while (true){
      //break if remote tail isn't locked
      REMUS_DEBUG("l_r_tail_ {:x}", *l_r_tail_);
      if (__atomic_load_n(l_r_tail_, __ATOMIC_SEQ_CST) == UNLOCKED){
        REMUS_DEBUG("remote tail is no longer locked, break");
        break;
      }
      //break if local is no longer victim
      if (__atomic_load_n(l_victim_, __ATOMIC_SEQ_CST) != LOCAL_VICTIM){
        REMUS_DEBUG("local is no longer victim, break");
        break;
      } 
      cpu_relax();
    }
    // returns once local is no longer victim or remote is unlocked
    return;
  }

  inline void RemotePetersons(){
    REMUS_DEBUG("Client {} setting remote to victim", self_.id);
    // set remote to victim
    auto prev = pool_->AtomicSwap(r_victim_, static_cast<uint64_t>(REMOTE_VICTIM));
    while (true){
      auto remote = pool_->Read<ALock>(a_lock_pointer_, prealloc_);
      auto temp_ptr = rdma_ptr<uint8_t>(remote);
      temp_ptr += TAIL_PTR_OFFSET;
      auto local_tail = rdma_ptr<rdma_ptr<LocalDescriptor>>(temp_ptr);
      //break if local tail isn't locked
      if (static_cast<uint64_t>(*(std::to_address(local_tail))) == 0){
        REMUS_DEBUG("local tail is no longer locked, break");
        break;
      }
      temp_ptr = rdma_ptr<uint8_t>(remote);
      temp_ptr += VICTIM_OFFSET;
      auto victim = rdma_ptr<rdma_ptr<LocalDescriptor>>(temp_ptr);
      // break if remote is no longer victim
      if (static_cast<uint64_t>(*(std::to_address(victim))) != REMOTE_VICTIM){
        REMUS_DEBUG("remote is no longer victim, break");
        break;
      } 
      cpu_relax();
    }
    // reaches here when local is no longer locked, or remote is no longer victim
    return;
  }

  inline bool LockRemoteMcsQueue(){
      REMUS_DEBUG("Locking remote MCS queue...");
      r_desc_->budget = -1;
      r_desc_->next = nullptr;
      // swap RemoteDescriptor onto the remote tail of the alock 
      auto prev =
        pool_->AtomicSwap(r_tail_, static_cast<uint64_t>(r_desc_pointer_));
      if (prev != nullptr) { //someone else has the lock
          auto temp_ptr = rdma_ptr<uint8_t>(prev);
          temp_ptr += NEXT_PTR_OFFSET; //temp_ptr = next field of the current tail's RemoteDescriptor
          // make prev point to the current tail RemoteDescriptor's next pointer
          prev = rdma_ptr<RemoteDescriptor>(temp_ptr);
          // set the address of the current tail's next field = to the addr of our local RemoteDescriptor
          pool_->Write<rdma_ptr<RemoteDescriptor>>(
              static_cast<rdma_ptr<rdma_ptr<RemoteDescriptor>>>(prev), r_desc_pointer_,
              r_prealloc_);
          REMUS_DEBUG("[Lock] Enqueued: {} --> (id={})",
                  static_cast<uint64_t>(prev.id()),
                  static_cast<uint64_t>(r_desc_pointer_.id()));
          // spins locally, waits for current tail/lockholder to write to budget when it unlocks
          while (r_desc_->budget < 0) {
            cpu_relax();
            REMUS_TRACE("Client {} waiting for remote lock", self_.id);
          }
          if (r_desc_->budget == 0) {
              REMUS_DEBUG("Remote Budget exhausted (id={})",
                          static_cast<uint64_t>(r_desc_pointer_.id()));
              // Release the lock before trying to continue
              Reacquire();
              r_desc_->budget = remote_budget_;
          }
           // budget was set to greater than 0, CS can be entered
          REMUS_DEBUG("[Lock] Acquired: prev={:x}, budget={:x} (id={})",
                  static_cast<uint64_t>(prev), r_desc_->budget,
                  static_cast<uint64_t>(r_desc_pointer_.id()));
          return true; //lock was passed to us
      } else { //no one had the lock, we were swapped in
          // set lock holders RemoteDescriptor budget to initBudget since we are the first lockholder
          r_desc_->budget = remote_budget_;
          // budget was set to greater than 0, CS can be entered
          REMUS_DEBUG("[Lock] Acquired: (NULL) prev={:x}, budget={:x} (id={})",
                    static_cast<uint64_t>(prev), r_desc_->budget,
                    static_cast<uint64_t>(r_desc_pointer_.id()));
          return false; //lock was not passed to us
      }
  }

  inline void RemoteLock(){
    REMUS_DEBUG("Client {} RemoteLock()", self_.id);
     // Set local descriptors to initial values
    bool passed = LockRemoteMcsQueue();
    if (passed == false){
      // returns when remote wins petersons alg
      RemotePetersons();
    }
    std::atomic_thread_fence(std::memory_order_release);
    REMUS_DEBUG("Remote wins");
    // remote_count_++;
  }

  inline bool LockLocalMcsQueue(){
    // Set local descriptor to inital values
    l_desc_.budget = -1;
    l_desc_.next = UNLOCKED;
    // to acquire the lock a thread atomically appends its own local node at the
    // tail of the list returning tail's previous contents
    uint64_t addr = reinterpret_cast<uint64_t>(&l_desc_); //pointer to LocalDescriptor
    REMUS_DEBUG("LocalLock() my ldesc addr is {:x}", addr);
    REMUS_DEBUG("l_l_tail {:x}", *l_l_tail_);
    auto prior_node = __atomic_exchange_n(l_l_tail_, addr, __ATOMIC_SEQ_CST);
    if (prior_node != UNLOCKED) {
      REMUS_DEBUG("Someone has the local lock. Enqueing {}", self_.id);
      // if the list was not previously empty, it sets the predecessor’s next
      // field to refer to its own local node
      LocalDescriptor* prev = reinterpret_cast<LocalDescriptor*>(prior_node);
      prev->next = &l_desc_;
      REMUS_DEBUG("[Lock] Local Enqueued: (id={})",
              static_cast<uint64_t>(self_.id));
      // thread then spins on its local locked field, waiting until its
      // predecessor sets this field to false
      while (l_desc_.budget < 0){
          cpu_relax(); 
          REMUS_TRACE("Client {} waiting for local lock", self_.id);
      }
      // If budget exceeded, then reinitialize.
      if (l_desc_.budget == 0) {
          REMUS_DEBUG("Local Budget exhausted (id={})",
                      static_cast<uint64_t>(self_.id));
          // Release the lock before trying to continue
          Reacquire();
          l_desc_.budget = local_budget_;
      }
      return true;
    } else {
      REMUS_DEBUG("First on local lock (id={})", self_.id);
      l_desc_.budget = local_budget_;
      return false; 
    }
  }

  inline void LocalLock(){
      REMUS_DEBUG("Client {} LocalLock()", self_.id);
      bool passed = LockLocalMcsQueue();
      if (passed == false){
        LocalPetersons();
      }
      REMUS_DEBUG("Local wins, passed is {}", passed);
      std::atomic_thread_fence(std::memory_order_release);
      // local_count_++;
  }

  inline void RemoteUnlock(){
      // Make sure everything finished before unlocking
      std::atomic_thread_fence(std::memory_order_release);
      // if r_tail_ == my desc (we are the tail), set it to 0 to unlock
      // otherwise, someone else is contending for lock and we want to give it to them
      // try to swap in a 0 to unlock the RemoteDescriptor at the addr of the remote tail, which we expect to currently be equal to our RemoteDescriptor
      auto prev = pool_->CompareAndSwap(r_tail_,
                                      static_cast<uint64_t>(r_desc_pointer_), 0);
    
      // if the descriptor at r_tail_ was not our RemoteDescriptor (other clients have attempted to lock & enqueued since)
      if (prev != r_desc_pointer_) {  
        // attempt to hand the lock to prev

        // make sure next pointer gets set before continuing
        while (r_desc_->next == nullptr)
        ;
        std::atomic_thread_fence(std::memory_order_acquire);
        // gets a pointer to the next RemoteDescriptor object
        auto next = const_cast<rdma_ptr<RemoteDescriptor> &>(r_desc_->next);
        //writes to the the next descriptors budget which lets it know it has the lock now
        pool_->Write<uint64_t>(static_cast<rdma_ptr<uint64_t>>(next),
                            r_desc_->budget - 1,
                            static_cast<rdma_ptr<uint64_t>>(r_prealloc_));
      } 
      
      //else: successful CAS, we unlocked our RemoteDescriptor and no one is queued after us
      REMUS_DEBUG("[Unlock] Unlocked (id={}), budget={:x}",
                  static_cast<uint64_t>(r_desc_pointer_.id()),
                  r_desc_->budget);
      return;
  }

  inline void LocalUnlock(){
      std::atomic_thread_fence(std::memory_order_release);
      REMUS_DEBUG("LocalUnLock()");
      //...leave the critical section
      // check whether this thread's local node’s next field is null

      if (l_desc_.next == nullptr) {
        REMUS_DEBUG("LocalUnlock: next pointer is null");
        // if so, then either:
        //  1. no other thread is contending for the lock
        //  2. there is a race condition with another thread about to
        // in order to distinguish between these cases atomic compare exchange the tail field
        // if the call succeeds, then no other thread is trying to acquire the lock,
        // tail is set to nullptr, and unlock() returns
        uint64_t addr = reinterpret_cast<uint64_t>(&l_desc_); // pointer to my local descriptor
        REMUS_DEBUG("LocalUnlock() my ldesc addr is {:x}", static_cast<uint64_t>(addr));
        REMUS_DEBUG("l_l_tail_ is {:x}", __atomic_load_n(l_l_tail_, __ATOMIC_SEQ_CST));
        // REMUS_DEBUG("local tail is {:x}", static_cast<uint64_t>(tail));
        bool ret = __atomic_compare_exchange_n(l_l_tail_, &addr, UNLOCKED, false,
                                            __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST); 
        REMUS_DEBUG("atomic cas: ret={}, ltail={:x}, addr={:x}", ret, __atomic_load_n(l_l_tail_, __ATOMIC_SEQ_CST), addr);                                    
        if (ret) {                  
            return;
        }
        // otherwise, another thread is in the process of trying to acquire the
        // lock, so spins waiting for it to finish
        while (l_desc_.next == nullptr) { cpu_relax(); }
      }
      REMUS_DEBUG("LocalUnlock(): setting successor's budget to {}", l_desc_.budget-1);
      // in either case, once the successor has appeared, the unlock() method sets
      // its successor’s budget, indicating that the lock is now free
      l_desc_.next->budget = l_desc_.budget - 1;
      // at this point no other thread can access this node and it can be reused
      // std::atomic_thread_fence(std::memory_order_release); //didnt do shit
      l_desc_.next = nullptr;
  }

  uint64_t reaq_count_;

  int64_t local_budget_;
  int64_t remote_budget_;

  bool is_local_; //resued for each call to lock for easy check on whether worker is local to key we are attempting to lock
  std::unordered_set<int> local_clients_; 
  
  Peer self_;
  std::shared_ptr<rdma_capability> pool_; // pool of alocks that the handle is local to (initalized in cluster/node_impl.h)

  //Pointer to alock to allow it to be read/write via rdma
  rdma_ptr<ALock> a_lock_pointer_;
  
  // Access to fields remotely
  rdma_ptr<rdma_ptr<RemoteDescriptor>> r_tail_;
  rdma_ptr<rdma_ptr<LocalDescriptor>> r_l_tail_;
  rdma_ptr<uint64_t> r_victim_;

  // Access to fields locally
  uint64_t* l_r_tail_;
  uint64_t* l_l_tail_; 
  uint64_t* l_victim_;
  
  // Prealloc used for rdma writes of rdma descriptor in RemoteUnlock
  rdma_ptr<ALock> prealloc_;
  rdma_ptr<rdma_ptr<RemoteDescriptor>> r_prealloc_;

  // Pointers to pre-allocated descriptor to be used locally
  rdma_ptr<LocalDescriptor> l_desc_pointer_;
  LocalDescriptor l_desc_;

  // Pointers to pre-allocated descriptor to be used remotely
  rdma_ptr<RemoteDescriptor> r_desc_pointer_;
  volatile RemoteDescriptor* r_desc_;

};