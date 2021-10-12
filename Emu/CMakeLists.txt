cmake_minimum_required(VERSION 3.8)

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Quick Gui Svg Sql Network Test REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Svg Gui Sql Quick Network Test REQUIRED)

#add_subdirectory(extern/retdec)
add_subdirectory(deps/unicorn-1.0.3)

set(PROJECT_SOURCES
    src/main.cpp
    )

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(Emu
        ${PROJECT_SOURCES}
    )
else()
    if(ANDROID)
        add_library(Emu SHARED
            ${PROJECT_SOURCES}
        )
    else()
        add_executable(Emu
            ${PROJECT_SOURCES}
        )
    endif()
endif()

target_link_libraries(Emu PRIVATE Qt${QT_VERSION_MAJOR}::Widgets Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Quick cxxopts unicorn retdec::fileformat)

#add_executable(Emu ${PROJECT_SOURCES})

#target_link_libraries (Main PUBLIC cxxopts unicorn capstone-shared)
target_include_directories(Emu PUBLIC

                          )
