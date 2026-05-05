cmake_minimum_required(VERSION 3.16)
project(Debugger VERSION 1.0.0 LANGUAGES CXX)

# Allow cmake_minimum_required to accept old-style syntax from dependencies
cmake_policy(SET CMP0128 NEW)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(GOOGLETEST_DIR "${CMAKE_BUILD_DIRECTORY}/lib")

include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/609281088cfefc76f9d0ce82e1ff6c30cc3591e5.zip
)
# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_compile_options(-fPIE -fPIC)
endif()

add_subdirectory(tests)
add_subdirectory(extern/cxxopts)
add_subdirectory(valkyrieGUI)
add_subdirectory(middleware)

