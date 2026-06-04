cmake_minimum_required(VERSION 3.16)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Quick Gui Svg Sql Network Test)
find_package(Qt6 REQUIRED COMPONENTS Widgets Core Svg Gui Sql Quick Network Xml QuickControls2 Core5Compat Test Charts Qml LinguistTools)

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
    src/include/utils/desktopmanager.h src/include/utils/desktopmanager.cpp
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
    src/include/presentation/PresentationStage.h src/include/presentation/PresentationStage.cpp
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
    src/include/behaviours/common/textdisplay.h src/include/behaviours/common/textdisplay.cpp
    src/include/behaviours/input/textinputnode.h src/include/behaviours/input/textinputnode.cpp
    src/include/behaviours/input/numberinput.h src/include/behaviours/input/numberinput.cpp
    src/include/behaviours/input/pairinput.h src/include/behaviours/input/pairinput.cpp
    src/include/behaviours/input/keyvalueinput.h src/include/behaviours/input/keyvalueinput.cpp
    src/include/behaviours/input/arrayinput.h src/include/behaviours/input/arrayinput.cpp
    src/include/behaviours/input/datetimeinput.h src/include/behaviours/input/datetimeinput.cpp
    src/include/behaviours/input/colorinput.h src/include/behaviours/input/colorinput.cpp
    src/include/behaviours/input/dictinput.h src/include/behaviours/input/dictinput.cpp
    src/include/behaviours/input/vec2input.h src/include/behaviours/input/vec2input.cpp
    src/include/behaviours/input/vec3input.h src/include/behaviours/input/vec3input.cpp
    src/include/behaviours/scheduling/intervaltrigger.h src/include/behaviours/scheduling/intervaltrigger.cpp
    src/include/behaviours/scheduling/crontrigger.h src/include/behaviours/scheduling/crontrigger.cpp
    src/include/behaviours/scheduling/scheduledscript.h
    src/include/behaviours/scheduling/scriptscheduler.h src/include/behaviours/scheduling/scriptscheduler.cpp
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
    src/include/behaviours/flow/flowstart.h src/include/behaviours/flow/flowstart.cpp
    src/include/behaviours/flow/flowbranch.h src/include/behaviours/flow/flowbranch.cpp
    src/include/behaviours/flow/flowswitch.h src/include/behaviours/flow/flowswitch.cpp
    src/include/behaviours/flow/flowsequence.h src/include/behaviours/flow/flowsequence.cpp
    src/include/behaviours/flow/flowmerge.h src/include/behaviours/flow/flowmerge.cpp
    src/include/behaviours/flow/flowdelay.h src/include/behaviours/flow/flowdelay.cpp
    src/include/behaviours/flow/flowloop.h src/include/behaviours/flow/flowloop.cpp
    src/include/behaviours/flow/flowend.h src/include/behaviours/flow/flowend.cpp
    src/include/behaviours/common/piechartviewer.h src/include/behaviours/common/piechartviewer.cpp
    src/include/behaviours/common/barchartviewer.h src/include/behaviours/common/barchartviewer.cpp
    src/include/behaviours/common/gaugeviewer.h src/include/behaviours/common/gaugeviewer.cpp
    src/include/behaviours/common/signalgenerator.h src/include/behaviours/common/signalgenerator.cpp
    src/include/behaviours/common/serialmonitor.h src/include/behaviours/common/serialmonitor.cpp
    src/include/behaviours/typecoercions.h src/include/behaviours/typecoercions.cpp
    src/include/behaviours/converters/numbercast.h src/include/behaviours/converters/numbercast.cpp
    src/include/behaviours/converters/pairadapter.h src/include/behaviours/converters/pairadapter.cpp
    src/include/behaviours/converters/mergenumbers.h src/include/behaviours/converters/mergenumbers.cpp
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
    src/include/model/languagemanager.h src/include/model/languagemanager.cpp
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
    src/include/behaviours/networking/httprequester.h src/include/behaviours/networking/httprequester.cpp
    src/include/behaviours/data/jsonparser.h src/include/behaviours/data/jsonparser.cpp
    src/include/behaviours/data/statisticsanalyzer.h src/include/behaviours/data/statisticsanalyzer.cpp
    src/include/behaviours/data/datatableviewer.h src/include/behaviours/data/datatableviewer.cpp
    src/include/behaviours/data/jsontreeviewer.h src/include/behaviours/data/jsontreeviewer.cpp
    src/include/behaviours/io/filewatcher.h src/include/behaviours/io/filewatcher.cpp
    src/include/behaviours/ai/aiquerynode.h src/include/behaviours/ai/aiquerynode.cpp
    src/include/behaviours/visualization/heatmapviewer.h src/include/behaviours/visualization/heatmapviewer.cpp
    src/include/behaviours/visualization/radarchartviewer.h src/include/behaviours/visualization/radarchartviewer.cpp
    src/include/behaviours/visualization/nodegraphviewer.h src/include/behaviours/visualization/nodegraphviewer.cpp
    src/include/behaviours/encoding/hashgenerator.h src/include/behaviours/encoding/hashgenerator.cpp
    src/include/behaviours/encoding/base64node.h src/include/behaviours/encoding/base64node.cpp
    src/include/behaviours/encoding/regexprocessor.h src/include/behaviours/encoding/regexprocessor.cpp
    src/include/behaviours/database/sqlitequery.h src/include/behaviours/database/sqlitequery.cpp
    src/include/behaviours/database/csvreaderwriter.h src/include/behaviours/database/csvreaderwriter.cpp
    src/include/behaviours/system/processlauncher.h src/include/behaviours/system/processlauncher.cpp
    src/include/behaviours/system/clipboardnode.h src/include/behaviours/system/clipboardnode.cpp
    src/include/behaviours/system/networkinterfaceinfo.h src/include/behaviours/system/networkinterfaceinfo.cpp
    src/include/behaviours/transform/bufferaccumulator.h src/include/behaviours/transform/bufferaccumulator.cpp
    src/include/behaviours/transform/ratelimiter.h src/include/behaviours/transform/ratelimiter.cpp
    src/include/behaviours/transform/unitconverter.h src/include/behaviours/transform/unitconverter.cpp
    src/include/behaviours/networking/websocketclient.h src/include/behaviours/networking/websocketclient.cpp
    src/include/behaviours/geo/mapviewer.h src/include/behaviours/geo/mapviewer.cpp
)

# ── Translations (Qt 6 i18n) ─────────────────────────────────────────────────
# Scan all QML files automatically so lupdate finds qsTr() calls.
file(GLOB_RECURSE VALKYRIE_QML_FILES
    "${CMAKE_CURRENT_SOURCE_DIR}/resources/qml/*.qml"
)

qt_add_translations(Debugger
    TS_FILES
        translations/Debugger_en.ts
        translations/Debugger_pt_BR.ts
        translations/Debugger_es.ts
    SOURCES
        ${PROJECT_SOURCES}
        # node_strings.cpp is scanned by lupdate but NOT compiled into the binary
        translations/node_strings.cpp
    QML_FILES
        ${VALKYRIE_QML_FILES}
    LUPDATE_OPTIONS
        -no-obsolete
    LRELEASE_OPTIONS
        -compress
)

target_link_libraries(Debugger PRIVATE Qt6::Widgets Qt6::Core Qt6::Quick Qt6::Xml Qt6::Charts Qt6::Qml Qt6::Network Qt6::Sql cxxopts pybind11::embed)

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

# Copy python_env directory only when the embedded distribution exists locally.
if(EXISTS "${CMAKE_SOURCE_DIR}/python_env")
    add_custom_command(TARGET Debugger POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_SOURCE_DIR}/python_env"
            "$<TARGET_FILE_DIR:Debugger>/python_env"
    )
endif()

# Copy the Python runtime library next to the executable on every platform.
# Windows : python3XX.dll lives beside python.exe (Python3_LIBRARY_RELEASE is
#           the import .lib, so we locate the DLL manually).
# macOS   : Python3_LIBRARY_RELEASE is libpython3.X.dylib
# Linux   : Python3_LIBRARY_RELEASE is libpython3.X.so (or versioned .so.1.0)
if(WIN32)
    get_filename_component(_python_dir "${Python3_EXECUTABLE}" DIRECTORY)
    set(_python_dll "${_python_dir}/python${Python3_VERSION_MAJOR}${Python3_VERSION_MINOR}.dll")
    if(EXISTS "${_python_dll}")
        add_custom_command(TARGET Debugger POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${_python_dll}"
                "$<TARGET_FILE_DIR:Debugger>/python${Python3_VERSION_MAJOR}${Python3_VERSION_MINOR}.dll"
        )
    endif()
elseif(Python3_LIBRARY_RELEASE)
    add_custom_command(TARGET Debugger POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${Python3_LIBRARY_RELEASE}"
            "$<TARGET_FILE_DIR:Debugger>/"
    )
endif()
