cmake_minimum_required(VERSION 3.8)

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Quick Gui Svg Sql Network Test REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Svg Gui Sql Quick Network Test REQUIRED)

set(PROJECT_SOURCES
    src/main.cpp
    )

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(middleware
        ${PROJECT_SOURCES}
    )
else()
    if(ANDROID)
        add_library(middleware SHARED
            ${PROJECT_SOURCES}
        )
    else()
        add_executable(middleware
            ${PROJECT_SOURCES}
        )
    endif()
endif()

target_link_libraries(middleware PRIVATE Qt${QT_VERSION_MAJOR}::Core cxxopts)

#add_executable(Emu ${PROJECT_SOURCES})

#target_link_libraries (Main PUBLIC cxxopts unicorn capstone-shared)
target_include_directories(middleware PUBLIC

                          )
