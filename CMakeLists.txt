cmake_minimum_required(VERSION 3.5)
project(DeObfuscatorTerminal LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_compile_options(-fPIE -fPIC)
endif()

find_package(QT NAMES Qt6 Qt5 COMPONENTS Widgets REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Widgets REQUIRED)

add_subdirectory(extern/unicorn)
#add_subdirectory(extern/capstone)
add_subdirectory(extern/cxxopts)
add_subdirectory(extern/retdec)
add_subdirectory(src)

if(WIN32)

elseif(UNIX)
    #TODO: 
endif(WIN32)

