project(rule110Cuda)

cmake_minimum_required(VERSION 2.8)

INCLUDE(FindPkgConfig)

PKG_SEARCH_MODULE(SDL2 REQUIRED sdl2)

find_package(CUDA REQUIRED)

set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS};-gencode arch=compute_30,code=sm_30)
file(
    GLOB_RECURSE
    files_src
    src/*.cu
)

file(
    GLOB_RECURSE
    files_header
    include/*.h
)

cuda_add_executable(${PROJECT_NAME} ${files_src} ${files_header})

INCLUDE_DIRECTORIES(${SDL2_INCLUDE_DIRS})
TARGET_LINK_LIBRARIES(${PROJECT_NAME} ${SDL2_LIBRARIES})
