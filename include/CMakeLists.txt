add_subdirectory(locks)

target_link_libraries(locks PUBLIC rome::rdma rome::workload rome::util protos)