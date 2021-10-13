cmake_minimum_required(VERSION 3.8)

#add_subdirectory(extern/retdec)
add_subdirectory(deps/unicorn-1.0.3)

set(PROJECT_SOURCES
    src/main.cpp
    )

if(CMAKE_VERSION VERSION_LESS "3.7.0")
    set(CMAKE_INCLUDE_CURRENT_DIR ON)
endif()



find_package(Qt5 COMPONENTS Core Quick Gui Svg Sql Network Test REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Svg Gui Sql Quick Network Test REQUIRED)


add_executable(Emu
    ${PROJECT_SOURCES}
    )

target_link_libraries(Emu PRIVATE Qt${QT_VERSION_MAJOR}::Core cxxopts unicorn retdec::fileformat)

#add_executable(Emu ${PROJECT_SOURCES})

#target_link_libraries (Main PUBLIC cxxopts unicorn capstone-shared)
target_include_directories(Emu PUBLIC

                          )
