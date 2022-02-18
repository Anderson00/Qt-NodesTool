cmake_minimum_required(VERSION 3.8)

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Quick Gui Svg Sql Network Test REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Svg Gui Sql Quick Network Test REQUIRED)

# Download & Configure Qaterial as part of your build system
include(FetchContent)
FetchContent_Declare(
  Qaterial
  GIT_REPOSITORY https://github.com/OlivierLDff/Qaterial.git
  GIT_TAG        master
  GIT_SHALLOW    1
)
FetchContent_MakeAvailable(Qaterial)

set(PROJECT_SOURCES
    src/main.cpp
    resources/icons.qrc
    resources/qml.qrc
    src/include/cliente/midclient.h src/include/cliente/midclient.cpp
    src/include/utils/xmlsavestate.cpp
    src/include/utils/xmlsavestate.h
    src/include/mainwindow.cpp
    src/include/mainwindow.ui
    src/include/qmlwindow.cpp
    src/include/qmlwindow.h
    src/include/subwindows/testconnectionwindow.h src/include/subwindows/testconnectionwindow.cpp
    src/include/subwindows/qmlmdisubwindow.cpp
    src/include/subwindows/qmlmdisubwindow.h
    src/include/subwindows/debuggermain.cpp
    src/include/subwindows/debuggermain.h
    src/include/subwindows/debuggermain.ui)


if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(Main
        ${PROJECT_SOURCES}
    )
else()
    if(ANDROID)
        add_library(Debugger SHARED
            ${PROJECT_SOURCES}
        )
    else()
        add_executable(Debugger
            ${PROJECT_SOURCES}
        )
    endif()
endif()

target_link_libraries(Debugger PRIVATE Qt${QT_VERSION_MAJOR}::Widgets Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Quick cxxopts retdec::fileformat Qaterial)

#add_executable(Main main.cpp ${SOURCE_FILES_CURSES})
set_target_properties(Debugger PROPERTIES AUTOMOC TRUE)

#target_link_libraries (Main PUBLIC cxxopts unicorn capstone-shared)
target_include_directories(Debugger PUBLIC                          
                          "${PROJECT_SOURCE_DIR}/extern/unicorn/include"
                          "${PROJECT_SOURCE_DIR}/extern/retdec/include"
                          #"${PROJECT_SOURCE_DIR}/extern/capstone/include"
                          "src/"
                          "src/include"
                          )
