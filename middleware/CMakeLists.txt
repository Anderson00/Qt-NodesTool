cmake_minimum_required(VERSION 3.8)
project(middleware VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

if(CMAKE_VERSION VERSION_LESS "3.7.0")
    set(CMAKE_INCLUDE_CURRENT_DIR ON)
endif()

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Network REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Network REQUIRED)

set(PROJECT_SOURCES
    src/main.cpp
    src/utils.h
    src/model/client.h src/model/client.cpp
    src/network/tcpserver.cpp src/network/tcpserver.h
    src/controller/middlewarecontroller.h src/controller/middlewarecontroller.cpp
    src/controller/networkcontroller.h src/controller/networkcontroller.cpp
    )

add_executable(middleware
    ${PROJECT_SOURCES}
    )

target_link_libraries(middleware Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Network cxxopts)

target_include_directories(middleware PUBLIC

                          )
