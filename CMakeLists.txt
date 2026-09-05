cmake_minimum_required(VERSION 3.16)

project(org.webosports.app.firstuse CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)

include(webOS/webOS)
webos_modules_init(1 0 0 QUALIFIER RC3)
webos_component(0 3 0)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility=hidden -fvisibility-inlines-hidden -Wall -std=c++1z")

find_package(Qt6 COMPONENTS Qml Quick)
if (NOT Qt6_FOUND)
    find_package(Qt5 5.15 REQUIRED COMPONENTS Qml Quick)
endif()

set(APP_DIR ${WEBOS_INSTALL_WEBOS_APPLICATIONSDIR}/org.webosports.app.firstuse)
set(APP_DATA appinfo.json)

set(LICENSE_DIR ${WEBOS_INSTALL_DATADIR}/luneos-license-agreements)
set(LICENSE_DATA licenses/main_en.html)

install(FILES ${APP_DATA} DESTINATION ${APP_DIR})
install(FILES ${LICENSE_DATA} DESTINATION ${LICENSE_DIR})
install(DIRECTORY qml DESTINATION ${APP_DIR})

add_subdirectory(plugin)
