cmake_minimum_required(VERSION 3.16)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Quick Gui Svg Sql Network Test)
find_package(Qt6 REQUIRED COMPONENTS Widgets Core Svg Gui Sql Quick Network Xml QuickControls2 Core5Compat Test Charts Qml)

# --- Python & pybind11 setup ---
# Use python_env/ when present (local embedded distribution); otherwise fall
# back to whatever Python the caller/CI has already provided via PATH or
# -DPython3_EXECUTABLE=.
if(NOT Python3_EXECUTABLE AND EXISTS "${CMAKE_SOURCE_DIR}/python_env")
    set(Python3_ROOT_DIR "${CMAKE_SOURCE_DIR}/python_env")
endif()
find_package(Python3 COMPONENTS Interpreter Development.Embed REQUIRED)

include(FetchContent)
FetchContent_Declare(
  pybind11
  GIT_REPOSITORY https://github.com/pybind/pybind11.git
  GIT_TAG        v2.11.1
)
FetchContent_MakeAvailable(pybind11)

qt_standard_project_setup()

set(PROJECT_SOURCES
    src/main.cpp
    resources/icons.qrc
    resources/qml.qrc
    src/include/cliente/midclient.h src/include/cliente/midclient.cpp
    src/include/utils/xmlsavestate.h src/include/utils/xmlsavestate.cpp
    src/include/utils/nodeserialize.h src/include/utils/nodeserialize.cpp
    src/include/utils/workspacemanager.h src/include/utils/workspacemanager.cpp
    src/include/utils/toastmanager.h src/include/utils/toastmanager.cpp
    src/include/utils/logmanager.h src/include/utils/logmanager.cpp
    src/include/utils/fastlinechart.h src/include/utils/fastlinechart.cpp
    src/include/utils/viewportgriditem.h src/include/utils/viewportgriditem.cpp
    src/include/utils/pythonhighlighter.h src/include/utils/pythonhighlighter.cpp
    src/include/utils/pythonengine.h src/include/utils/pythonengine.cpp
    src/include/mainwindow.cpp
    src/include/mainwindow.ui
    src/include/qmlwindow.h src/include/qmlwindow.cpp
    src/include/viewportwindow.h src/include/viewportwindow.cpp
    src/include/behaviours/common/fileopener.h src/include/behaviours/common/fileopener.cpp
    src/include/behaviours/common/cameraviewer.h src/include/behaviours/common/cameraviewer.cpp
    src/include/behaviours/common/processesviewer.h src/include/behaviours/common/processesviewer.cpp
    src/include/behaviours/common/hexviewer.h src/include/behaviours/common/hexviewer.cpp
    src/include/behaviours/common/linechartviewer.h src/include/behaviours/common/linechartviewer.cpp
    src/include/behaviours/common/randomgeneratorviewer.h src/include/behaviours/common/randomgeneratorviewer.cpp
    src/include/behaviours/logic/hub.h src/include/behaviours/logic/hub.cpp
    src/include/behaviours/logic/comparison.h src/include/behaviours/logic/comparison.cpp
    src/include/behaviours/logic/gate.h src/include/behaviours/logic/gate.cpp
    src/include/behaviours/logic/stringformat.h src/include/behaviours/logic/stringformat.cpp
    src/include/behaviours/common/constantvalue.h src/include/behaviours/common/constantvalue.cpp
    src/include/behaviours/common/textdisplay.h src/include/behaviours/common/textdisplay.cpp
    src/include/behaviours/common/timernode.h src/include/behaviours/common/timernode.cpp
    src/include/behaviours/common/counter.h src/include/behaviours/common/counter.cpp
    src/include/behaviours/math/mathoperation.h src/include/behaviours/math/mathoperation.cpp
    src/include/behaviours/math/mathfunction.h src/include/behaviours/math/mathfunction.cpp
    src/include/behaviours/math/clamp.h src/include/behaviours/math/clamp.cpp
    src/include/behaviours/math/maprange.h src/include/behaviours/math/maprange.cpp
    src/include/behaviours/math/filter.h src/include/behaviours/math/filter.cpp
    src/include/behaviours/math/expressioneval.h src/include/behaviours/math/expressioneval.cpp
    src/include/behaviours/script/variablereader.h src/include/behaviours/script/variablereader.cpp
    src/include/behaviours/script/variablewriter.h src/include/behaviours/script/variablewriter.cpp
    src/include/behaviours/script/variablemonitor.h src/include/behaviours/script/variablemonitor.cpp
    src/include/behaviours/script/pythonbehaviour.h src/include/behaviours/script/pythonbehaviour.cpp
    src/include/behaviours/common/piechartviewer.h src/include/behaviours/common/piechartviewer.cpp
    src/include/behaviours/common/barchartviewer.h src/include/behaviours/common/barchartviewer.cpp
    src/include/behaviours/common/gaugeviewer.h src/include/behaviours/common/gaugeviewer.cpp
    src/include/behaviours/common/signalgenerator.h src/include/behaviours/common/signalgenerator.cpp
    src/include/behaviours/common/serialmonitor.h src/include/behaviours/common/serialmonitor.cpp
    src/include/behaviours/behaviourregistry.h src/include/behaviours/behaviourregistry.cpp
    src/include/behaviours/connections.h src/include/behaviours/connections.cpp
    src/include/model/tablemodel.h src/include/model/tablemodel.cpp
    src/include/model/connectionmodel.h src/include/model/connectionmodel.cpp
    src/include/model/thememanager.h src/include/model/thememanager.cpp
    src/include/model/abstracttheme.h src/include/model/abstracttheme.cpp
    src/include/model/subtheme.h src/include/model/subtheme.cpp
    src/include/model/nodetheme.h src/include/model/nodetheme.cpp
    src/include/model/colorpreset.h src/include/model/colorpreset.cpp
    src/include/model/presetmanager.h src/include/model/presetmanager.cpp
    src/include/model/globalproperties.h src/include/model/globalproperties.cpp
    src/include/model/nodevariable.h src/include/model/nodevariable.cpp
    src/include/model/variablemanager.h src/include/model/variablemanager.cpp
    src/include/behaviours/behaviours.h src/include/behaviours/behaviours.cpp
    src/include/commands/nodeundocommands.h src/include/commands/nodeundocommands.cpp
    src/include/subwindows/taskmanagerwindow.h src/include/subwindows/taskmanagerwindow.cpp
    src/include/subwindows/testconnectionwindow.h src/include/subwindows/testconnectionwindow.cpp
    src/include/subwindows/qmlmdisubwindow.cpp
    src/include/subwindows/qmlmdisubwindow.h
    src/include/subwindows/debuggermain.cpp
    src/include/subwindows/debuggermain.h
    src/include/subwindows/debuggermain.ui
)


qt_add_executable(Debugger
    ${PROJECT_SOURCES}
    src/include/behaviours/common/componentsviewer.h src/include/behaviours/common/componentsviewer.cpp
)

target_link_libraries(Debugger PRIVATE Qt6::Widgets Qt6::Core Qt6::Quick Qt6::Xml Qt6::Charts Qt6::Qml cxxopts pybind11::embed)

set_target_properties(Debugger PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    AUTOMOC TRUE)

target_include_directories(Debugger PUBLIC
                          "${CMAKE_SOURCE_DIR}/middleware/include"
                          "src/"
                          "src/include"
                          )

# Copy python_env to the build directory only when the embedded distribution
# exists locally (not present in CI where the system Python is used instead).
if(EXISTS "${CMAKE_SOURCE_DIR}/python_env")
    add_custom_command(TARGET Debugger POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_SOURCE_DIR}/python_env"
            "$<TARGET_FILE_DIR:Debugger>/python_env"
    )
    if(WIN32)
        add_custom_command(TARGET Debugger POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CMAKE_SOURCE_DIR}/python_env/python311.dll"
                "$<TARGET_FILE_DIR:Debugger>/python311.dll"
        )
    endif()
endif()
