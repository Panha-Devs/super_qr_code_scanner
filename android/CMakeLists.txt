cmake_minimum_required(VERSION 3.10)
project(super_qr_code_scanner)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find OpenCV
find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})

# Add ZXing source from bundled location
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../src/zxing-cpp-core zxing)

# Add C API wrapper
add_library(super_qr_code_scanner SHARED
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/super_qr_code_scanner_api.cpp
)

target_include_directories(super_qr_code_scanner PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/zxing-cpp-core/src
    ${CMAKE_CURRENT_SOURCE_DIR}/..
)

target_link_libraries(super_qr_code_scanner
    ${OpenCV_LIBS}
    ZXing
    log
)
