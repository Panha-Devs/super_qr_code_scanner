cmake_minimum_required(VERSION 3.10)
project(super_qr_code_scanner)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# OpenCV from Maven (AAR gets extracted by Gradle)
# Works for both debug and release builds
find_library(OpenCV_LIB opencv_java4 
    PATHS "${CMAKE_CURRENT_SOURCE_DIR}/../../../build/opencv_sdk/native/jni/${ANDROID_ABI}"
    NO_DEFAULT_PATH
)

# Include OpenCV headers from extracted AAR
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../../../build/opencv_sdk/native/jni/include")

# Add ZXing source from bundled location
# EXCLUDE_FROM_ALL prevents building unnecessary ZXing targets
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../src/zxing-cpp-core zxing EXCLUDE_FROM_ALL)

# Add C API wrapper
add_library(super_qr_code_scanner SHARED
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/super_qr_code_scanner_api.cpp
)

target_include_directories(super_qr_code_scanner PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/zxing-cpp-core/src
    ${CMAKE_CURRENT_SOURCE_DIR}/..
)

target_link_libraries(super_qr_code_scanner
    ${OpenCV_LIB}
    ZXing
    log
    android
)
