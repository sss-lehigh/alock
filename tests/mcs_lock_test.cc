#include "mcs_lock.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "rome/logging/logging.h"

#include "../../../util.h"

namespace X {
namespace {

class McsLockTest : public ::testing::Test {
protected:
  McsLockTest(){
    ROME_INIT_LOG();
    lock_ = std::make_unique<McsLock>();
  }
  std::unique_ptr<McsLock> lock_;
};

TEST_F(McsLockTest, LockIsLocked) {
  // Test plan: Construct a lock and check that it is unlocked.
  ASSERT_NE(lock_, nullptr);
  EXPECT_FALSE(lock_->IsLocked());
}

TEST_F(McsLockTest, LockAndUnlock) {
  // Test plan: Construct a lock and check that it is unlocked. Lock it and check that it is locked. Unlock and check again. 
  ASSERT_NE(lock_, nullptr);
  EXPECT_FALSE(lock_->IsLocked());
  lock_->Lock();
  EXPECT_TRUE(lock_->IsLocked());
  lock_->Unlock();
  EXPECT_FALSE(lock_->IsLocked());
}

} // namespace 
} // namespace X