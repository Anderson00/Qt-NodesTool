cmake_minimum_required(VERSION 3.8)

# Download & Configure Qaterial as part of your build system
include(FetchContent)
FetchContent_Declare(
  Qaterial
  GIT_REPOSITORY https://github.com/OlivierLDff/Qaterial.git
  GIT_TAG        master
  GIT_SHALLOW    1
)
FetchContent_MakeAvailable(Qaterial)

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Quick Gui Svg Sql Network Test Qaterial REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Svg Gui Sql Quick Network Test REQUIRED)

set(PROJECT_SOURCES
    src/main.cpp
    resources/icons.qrc
    resources/qml.qrc
    src/include/cliente/midclient.h src/include/cliente/midclient.cpp
    src/include/utils/xmlsavestate.h src/include/utils/xmlsavestate.cpp
    src/include/mainwindow.cpp
    src/include/mainwindow.ui
    src/include/qmlwindow.h src/include/qmlwindow.cpp
    src/include/viewportwindow.h src/include/viewportwindow.cpp
    src/include/behaviours/common/fileopener.h src/include/behaviours/common/fileopener.cpp
    src/include/behaviours/common/processesviewer.h src/include/behaviours/common/processesviewer.cpp
    src/include/behaviours/common/hexviewer.h src/include/behaviours/common/hexviewer.cpp
    src/include/behaviours/common/linechartviewer.h src/include/behaviours/common/linechartviewer.cpp
    src/include/behaviours/common/randomgeneratorviwer.h src/include/behaviours/common/randomgeneratorviwer.cpp
    src/include/behaviours/logic/hub.h src/include/behaviours/logic/hub.cpp
    src/include/behaviours/behaviourloader.h src/include/behaviours/behaviourloader.cpp
    src/include/behaviours/connections.h src/include/behaviours/connections.cpp
    src/include/model/tablemodel.h src/include/model/tablemodel.cpp
    src/include/model/connectionmodel.h src/include/model/connectionmodel.cpp
    src/include/behaviours/behaviours.h src/include/behaviours/behaviours.cpp
    src/include/subwindows/taskmanagerwindow.h src/include/subwindows/taskmanagerwindow.cpp
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

target_link_libraries(Debugger PRIVATE Qt${QT_VERSION_MAJOR}::Widgets Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Quick cxxopts Qaterial QOlm::QOlm)

#add_executable(Main main.cpp ${SOURCE_FILES_CURSES})
set_target_properties(Debugger PROPERTIES AUTOMOC TRUE)

#target_link_libraries (Main PUBLIC cxxopts unicorn capstone-shared)
target_include_directories(Debugger PUBLIC                          
                          #"${PROJECT_SOURCE_DIR}/extern/unicorn/include"
                          #"${PROJECT_SOURCE_DIR}/extern/retdec/include"
                          #"${PROJECT_SOURCE_DIR}/extern/capstone/include"
                          "src/"
                          "src/include"
                          )
