cmake_minimum_required(VERSION 3.5)
project(Debugger-Emu LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(ZLIB_INCLUDE_DIR extern/zlib)
set(ZLIB_LIBRARY extern/zlib)
set(OPENSSL_ROOT_DIR "C:\\Users\\ander\\Downloads\\OpenSSL\\1.1.1d")
set(PERL_EXECUTABLE "C:\\Users\\ander\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\ActiveState\\ActiveState Perl-5.32 CLI")
#set(ZLIB_INCLUDE_DIR extern/zlib)


if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_compile_options(-fPIE -fPIC)
endif()

#add_subdirectory(extern/zlib)
add_subdirectory(extern/retdec)
#add_subdirectory(extern/capstone)
add_subdirectory(extern/cxxopts)
add_subdirectory(valkyrieGUI)
add_subdirectory(middleware)
#add_subdirectory(Emu)

if(WIN32)

elseif(UNIX)
    #TODO: 
endif(WIN32)

