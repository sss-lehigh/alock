#include "rdma_mcs_lock.h"

#include <barrier>
#include <chrono>
#include <memory>
#include <thread>
#include <unordered_map>

#include "rome/logging/logging.h"
#include "rome/rdma/connection_manager/connection_manager.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace X {
namespace {

using Conn = RdmaMcsLock::conn_type;

// constexpr char kIpAddress[] = "10.0.0.1";
// constexpr char kIpAddress2[] = "10.0.0.2";
constexpr char kIpAddress[] = "10.10.1.1";
constexpr char kIpAddress2[] = "10.10.1.2";
constexpr uint16_t kHostId = 0;
constexpr uint16_t kHostPort = 18000;

class RdmaMcsLockTest : public ::testing::Test {
protected:
  using cm_type = MemoryPool::cm_type;
  using peer_type = MemoryPool::Peer;

  RdmaMcsLockTest() {
    ROME_INIT_LOG();
    InitPeer(host_);
  }

  void InitPeer(peer_type peer) {
    pool_ = std::make_unique<MemoryPool>(
        peer, std::make_unique<ConnectionManager<Conn::channel_type>>(peer.id));
    locks_.emplace(peer.id,
                   std::make_unique<RdmaMcsLock>(peer, *(pool_.get())));
    peers_.push_back(peer);
  }

  void InitTest() {
    std::vector<std::thread> init_threads;
    auto do_init = [this](const auto &p) {
      ROME_ASSERT_OK(locks_[p.id]->Init(host_, peers_));
    };
    std::for_each(peers_.begin(), peers_.end(),
                  [&init_threads, do_init](const auto &p) {
                    init_threads.emplace_back(do_init, p);
                  });
    std::for_each(init_threads.begin(), init_threads.end(),
                  [](auto &t) { t.join(); });
  }

  const peer_type host_{kHostId, kIpAddress, kHostPort};

  std::unique_ptr<MemoryPool> pool_;
  std::vector<peer_type> peers_;
  std::unordered_map<uint16_t, std::unique_ptr<RdmaMcsLock>> locks_;
};

TEST_F(RdmaMcsLockTest, HostIsLocked) {
  // Test plan: Construct a lock and check that it is unlocked.
  InitTest();
  ASSERT_EQ(peers_.size(), 1);
  auto iter = locks_.find(host_.id);
  ASSERT_NE(iter, locks_.end());
  EXPECT_FALSE(iter->second->IsLocked());
}

TEST_F(RdmaMcsLockTest, PeerIsLocked) {
  // Test plan: Construct a lock and check that it is unlocked.
  std::vector<peer_type> test_peers;
  for (int i = 1; i < 10; i++) {
    test_peers.emplace_back(peer_type{static_cast<uint16_t>(i), kIpAddress,
                                      static_cast<uint16_t>(kHostPort + i)});
    InitPeer(test_peers.back());
  }

  InitTest();
  ASSERT_EQ(peers_.size(), 10);

  std::for_each(test_peers.begin(), test_peers.end(), [&](const auto &p) {
    auto iter = locks_.find(p.id);
    ASSERT_NE(iter, locks_.end());
    EXPECT_FALSE(iter->second->IsLocked());
  });
}

TEST_F(RdmaMcsLockTest, LocksOnce) {
  // Test plan: Construct a lock, then lock it with a single remote process.
  peer_type p{1, kIpAddress, kHostPort + 1};
  InitPeer(p);
  InitTest();
  ASSERT_EQ(peers_.size(), 2);

  auto iter = locks_.find(p.id);
  ASSERT_NE(iter, locks_.end());
  iter->second->Lock();
  EXPECT_TRUE(iter->second->IsLocked());
}

TEST_F(RdmaMcsLockTest, UnlocksOnce) {
  // Test plan: Construct a lock and check that it is unlocked after locking and unlocking.
  peer_type p{1, kIpAddress, kHostPort + 1};
  InitPeer(p);
  InitTest();
  ASSERT_EQ(peers_.size(), 2);

  auto iter = locks_.find(p.id);
  ASSERT_NE(iter, locks_.end());
  iter->second->Lock();
  iter->second->Unlock();
  EXPECT_FALSE(iter->second->IsLocked());
}

TEST_F(RdmaMcsLockTest, MutlipleLocksAndUnlocks) {
  peer_type p{1, kIpAddress, kHostPort + 1};
  InitPeer(p);
  InitTest();
  ASSERT_EQ(peers_.size(), 2);
  auto iter = locks_.find(p.id);
  ASSERT_NE(iter, locks_.end());

  for (int i = 0; i < 100; ++i) {
    iter->second->Lock();
    iter->second->Unlock();
    EXPECT_FALSE(iter->second->IsLocked());
  }
}

TEST_F(RdmaMcsLockTest, MultipleConcurrentLockers) {
  constexpr int kNumClients = 5;

  for (int i = 1; i <= kNumClients; ++i) {
    peer_type p{static_cast<uint16_t>(i), kIpAddress2,
                static_cast<uint16_t>(kHostPort + i)};
    InitPeer(p);
  }
  InitTest();
  ASSERT_EQ(peers_.size(), kNumClients + 1);

  std::atomic<bool> terminate = false;
  auto do_work = [&terminate](auto *l) {
    while (!terminate) {
      l->Lock();
      // std::this_thread::sleep_for(std::chrono::milliseconds(50));
      l->Unlock();
    }
  };

  std::vector<std::thread> threads;
  for (int i = 1; i <= kNumClients; ++i) {
    threads.emplace_back(do_work, locks_[i].get());
  }

  std::this_thread::sleep_for(std::chrono::milliseconds(2000));
  terminate = true;

  for (int i = 0; i < kNumClients; ++i) {
    threads[i].join();
  }
}

} // namespace
} // namespace X