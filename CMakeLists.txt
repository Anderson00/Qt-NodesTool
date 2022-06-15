cmake_minimum_required(VERSION 3.5)
project(Debugger-Emu LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(GOOGLETEST_DIR "${CMAKE_BUILD_DIRECTORY}/lib")
set(ZLIB_INCLUDE_DIR extern/zlib)
set(ZLIB_LIBRARY extern/zlib)
set(OPENSSL_ROOT_DIR "C:\\Users\\ander\\Downloads\\openssl-1.1\\x64\\lib")
set(PERL_EXECUTABLE "C:\\Users\\ander\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\ActiveState\\ActiveState Perl-5.32 CLI")

#set(ZLIB_INCLUDE_DIR extern/zlib)

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

#add_subdirectory(extern/zlib)
add_subdirectory(tests)
#add_subdirectory(extern/retdec)
#add_subdirectory(extern/capstone)
add_subdirectory(extern/cxxopts)
add_subdirectory(valkyrieGUI)
add_subdirectory(middleware)
#add_subdirectory(Emu)

if(WIN32)

elseif(UNIX)
    #TODO: 
endif(WIN32)

