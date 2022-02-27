cmake_minimum_required(VERSION 3.5)
project(valkyrie-test LANGUAGES CXX)

SET(CMAKE_CXX_FLAGS "-g -O0 -Wall -fprofile-arcs -ftest-coverage")
SET(CMAKE_CXX_OUTPUT_EXTENSION_REPLACE 1)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

if(CMAKE_VERSION VERSION_LESS "3.7.0")
    set(CMAKE_INCLUDE_CURRENT_DIR ON)
endif()

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Network Test REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Network Test REQUIRED)


enable_testing()

add_definitions(-DGTEST_LANGUAGE_CXX11)
find_package(Threads REQUIRED)

if (EXISTS $ENV{GOOGLETEST_DIR})
    message($ENV{GOOGLETEST_DIR})
    set(GOOGLETEST_DIR $ENV{GOOGLETEST_DIR})
    message("${GOOGLETEST_DIR}")
endif()
if (EXISTS ${GOOGLETEST_DIR})
    set(GTestSrc ${GOOGLETEST_DIR}/googletest)
    set(GMockSrc ${GOOGLETEST_DIR}/googlemock)
elseif (UNIX AND EXISTS /usr/src/gtest)
    set(GTestSrc /usr/src/gtest)
    message(WARNING "Using gtest from system")
    if (EXISTS /usr/src/gmock)
        set(GMockSrc /usr/src/gmock)
    endif ()
else ()
    #message( FATAL_ERROR "No googletest src dir found - set GOOGLETEST_DIR to enable!")
endif ()
set(GTestFiles ${GTestSrc}/src/gtest-all.cc)
set(GTestIncludes ${GTestSrc} ${GTestSrc}/include)
if (NOT ${GMockSrc} STREQUAL "")
    list(APPEND GTestFiles ${GMockSrc}/src/gmock-all.cc)
    list(APPEND GTestIncludes ${GMockSrc} ${GMockSrc}/include)
endif ()

include_directories(${GTestIncludes})

add_test(valkyrie-test VakyrieTest)

include_directories("../middleware/src")

add_executable(valkyrie-test
    main.cpp
    middleware/model/cache.cpp

    "../middleware/src/model/agenteobserver.cpp"
    )

target_link_libraries(valkyrie-test PRIVATE
        Threads::Threads
        gtest_main
        Qt${QT_VERSION_MAJOR}::Test
        Qt${QT_VERSION_MAJOR}::Core
        Qt${QT_VERSION_MAJOR}::Network
    )
