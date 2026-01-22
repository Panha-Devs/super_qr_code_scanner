cmake_minimum_required(VERSION 3.18)
project(super_qr_code_scanner VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# =========================
# Platform Detection
# =========================
if(ANDROID)
    set(PLATFORM "android")
    if(ANDROID_ABI STREQUAL "arm64-v8a")
        set(ABI "arm64-v8a")
    elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
        set(ABI "armeabi-v7a")
    elseif(ANDROID_ABI STREQUAL "x86_64")
        set(ABI "x86_64")
    elseif(ANDROID_ABI STREQUAL "x86")
        set(ABI "x86")
    endif()
elseif(IOS)
    set(PLATFORM "ios")
    if(CMAKE_OSX_ARCHITECTURES MATCHES "arm64")
        set(ABI "arm64")
    elseif(CMAKE_OSX_ARCHITECTURES MATCHES "x86_64")
        set(ABI "x86_64")
    endif()
elseif(APPLE)
    set(PLATFORM "macos")
    if(CMAKE_OSX_ARCHITECTURES MATCHES "arm64")
        set(ABI "arm64")
    elseif(CMAKE_OSX_ARCHITECTURES MATCHES "x86_64")
        set(ABI "x86_64")
    endif()
elseif(WIN32)
    set(PLATFORM "windows")
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(ABI "x64")
    else()
        set(ABI "x86")
    endif()
elseif(UNIX)
    set(PLATFORM "linux")
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(ABI "x64")
    else()
        set(ABI "x86")
    endif()
endif()

message(STATUS "Platform: ${PLATFORM}")
message(STATUS "ABI: ${ABI}")

# =========================
# Source Files
# =========================
set(SOURCES
    super_qr_code_scanner_api.cpp
)

# =========================
# Library Paths
# =========================
set(OPENCV_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/opencv/include)
set(OPENCV_LIB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/opencv/libs/${PLATFORM}-${ABI})

set(ZXING_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/zxing/include)
set(ZXING_LIB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/zxing/libs/${PLATFORM}-${ABI})

# =========================
# Include Directories
# =========================
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${OPENCV_INCLUDE_DIR}
    ${ZXING_INCLUDE_DIR}
)

# =========================
# Create Shared Library
# =========================
add_library(${PROJECT_NAME} SHARED ${SOURCES})

# Add compile definitions to disable OpenCV plugin loading
target_compile_definitions(${PROJECT_NAME} PRIVATE 
    NO_GETENV
    OPENCV_DISABLE_PLUGINS_IMPL
)

# =========================
# Link Libraries
# =========================
# Find OpenCV libraries
if(ANDROID)
    file(GLOB OPENCV_LIBS "${OPENCV_LIB_DIR}/libopencv_*.so")
elseif(IOS OR APPLE)
    file(GLOB OPENCV_LIBS "${OPENCV_LIB_DIR}/libopencv_*.dylib" "${OPENCV_LIB_DIR}/libopencv_*.a")
elseif(WIN32)
    file(GLOB OPENCV_LIBS "${OPENCV_LIB_DIR}/opencv_*.lib")
else()
    file(GLOB OPENCV_LIBS "${OPENCV_LIB_DIR}/libopencv_*.so")
endif()

# Find ZXing library
if(ANDROID)
    set(ZXING_LIB "${ZXING_LIB_DIR}/libZXing.a")
elseif(IOS OR APPLE)
    set(ZXING_LIB "${ZXING_LIB_DIR}/libZXing.a")
elseif(WIN32)
    set(ZXING_LIB "${ZXING_LIB_DIR}/ZXing.lib")
else()
    set(ZXING_LIB "${ZXING_LIB_DIR}/libZXing.a")
endif()

message(STATUS "OpenCV libraries: ${OPENCV_LIBS}")
message(STATUS "ZXing library: ${ZXING_LIB}")

target_link_libraries(${PROJECT_NAME}
    ${OPENCV_LIBS}
    ${ZXING_LIB}
)

# =========================
# Android Specific
# =========================
if(ANDROID)
    target_link_libraries(${PROJECT_NAME}
        log
        android
    )
endif()

# =========================
# iOS/macOS Specific
# =========================
if(IOS OR APPLE)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        FRAMEWORK FALSE
        MACOSX_RPATH TRUE
    )
    target_link_libraries(${PROJECT_NAME}
        "-framework Foundation"
        "-framework CoreFoundation"
    )
endif()

# =========================
# Install
# =========================
install(TARGETS ${PROJECT_NAME}
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)
