include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR})

add_library(firstuse MODULE plugin.cpp)
target_link_libraries(firstuse Qt::Quick)

execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/qmldir"
                                                              "${CMAKE_CURRENT_BINARY_DIR}/qmldir")

install(TARGETS firstuse DESTINATION ${APP_DIR}/firstuse)
install(FILES qmldir DESTINATION ${APP_DIR}/firstuse)
