cmake_minimum_required(VERSION 3.8)

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Quick Gui Svg Sql Network Test REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Svg Gui Sql Quick Network Test REQUIRED)

set(PROJECT_SOURCES
    main.cpp
    resources/icons.qrc
    resources/qml.qrc
    include/utils/xmlsavestate.cpp
    include/utils/xmlsavestate.h
    include/mainwindow.cpp
    include/mainwindow.ui
    include/qmlwindow.cpp
    include/qmlwindow.h
    include/subwindows/qmlmdisubwindow.cpp
    include/subwindows/qmlmdisubwindow.h
    include/subwindows/debuggermain.cpp
    include/subwindows/debuggermain.h
    include/subwindows/debuggermain.ui)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(Main
        ${PROJECT_SOURCES}
    )
else()
    if(ANDROID)
        add_library(Main SHARED
            ${PROJECT_SOURCES}
        )
    else()
        add_executable(Main
            ${PROJECT_SOURCES}
        )
    endif()
endif()

target_link_libraries(Main PRIVATE Qt${QT_VERSION_MAJOR}::Widgets Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Quick cxxopts unicorn retdec::pelib)

#add_executable(Main main.cpp ${SOURCE_FILES_CURSES})

#target_link_libraries (Main PUBLIC cxxopts unicorn capstone-shared)
target_include_directories(Main PUBLIC
                          "${PROJECT_BINARY_DIR}"
                          "${PROJECT_SOURCE_DIR}/extern/unicorn/include"
                          "${PROJECT_SOURCE_DIR}/extern/retdec/include"
                          #"${PROJECT_SOURCE_DIR}/extern/capstone/include"
                          "include/"
                          )
