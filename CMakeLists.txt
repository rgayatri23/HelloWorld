cmake_minimum_required (VERSION 3.8)
set (CMAKE_CUDA_COMPILER_ID NVIDIA)
set (CMAKE_CUDA_HOST_COMPILER mpicc)
set (CMAKE_C_COMPILER mpicc)
set (CMAKE_CXX_COMPILER mpicxx)

SET(EXE cudahello)


set (CMAKE_CUDA_ARCHITECTURES 70;80)
project (mpi-cuda-hello)
enable_language (CXX CUDA)
set (CMAKE_VERBOSE_MAKEFILE TRUE)

find_package(OpenMP REQUIRED)
find_package(CUDA REQUIRED)

add_executable (${EXE} cudahello.cpp)

target_include_directories(${EXE} PRIVATE ${CUDA_TOOLKIT_ROOT_DIR}/samples/common/inc)
target_include_directories(${EXE} PRIVATE ${CUDA_TOOLKIT_ROOT_DIR}/include)
target_link_libraries(${EXE} PUBLIC OpenMP::OpenMP_CXX)
target_link_libraries(${EXE} PUBLIC OpenMP::OpenMP_CXX)
target_link_libraries(${EXE} PUBLIC ${CUDA_LIBRARIES})
