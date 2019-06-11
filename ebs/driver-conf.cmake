

SET(PROJECT_VERSION     "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}-${PROJECT_VERSION_TWEAK}")
                         

IF(CMAKE_TOOLCHAIN_FILE)
    # This is a cross-platform build, and therefore is assumed to be intended for an 
    # embedded target
    IF(${USE_ASM_IF_AVAILABLE})
        ENABLE_LANGUAGE(ASM)
    ENDIF()
    SET(CMAKE_INSTALL_PREFIX        ${PLATFORM_PACKAGES_PATH})
    SET(PUBLIC_INCLUDE_DIRECTORY    ${CMAKE_CURRENT_SOURCE_DIR})
    IF(${CMAKE_CURRENT_SOURCE_DIR} STREQUAL ${CMAKE_SOURCE_DIR})
        # This is library only build. 
        MESSAGE("Driver : ${PROJECT_NAME} ${PROJECT_VERSION}") 
        SET(BUILD_INCLUDE_DIR   ${CMAKE_BINARY_DIR}/include)
        CONFIGURE_FILE(
            "${CMAKE_CURRENT_SOURCE_DIR}/config.h.in"
            "${BUILD_INCLUDE_DIR}/config.h"
        )
        INCLUDE_DIRECTORIES(${BUILD_INCLUDE_DIR} ${INCLUDE_DIRECTORIES})
        INSTALL(FILES "${BUILD_INCLUDE_DIR}/config.h" DESTINATION include/${LIBRARY_NAME})
    ELSE()
        # This is a firmware integrated build. Ensure the library headers and generated config file ends up in 
        # the firmware include tree. Lib include folder is symlinked from the src directory. This is messy, 
        # possibly rickety, probably needs to have a better solution, but for the moment it works.
        MESSAGE("Integrated Driver : ${PROJECT_NAME} ${PROJECT_VERSION}") 
        GET_FILENAME_COMPONENT(PARENT_DIR ${CMAKE_CURRENT_SOURCE_DIR} DIRECTORY)
        GET_FILENAME_COMPONENT(DRIVER_NAME ${PARENT_DIR} NAME) 
        SET(INCLUDE_PREFIX  "drivers/${DRIVER_NAME}")
        SET(BUILD_INCLUDE_DIR  ${CMAKE_BINARY_DIR}/include/${INCLUDE_PREFIX})
        EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} -E create_symlink ${PUBLIC_INCLUDE_DIRECTORY} ${BUILD_INCLUDE_DIR})
        CONFIGURE_FILE(
            "${CMAKE_CURRENT_SOURCE_DIR}/config.h.in"
            "${BUILD_INCLUDE_DIR}/config.h"
        )
        INCLUDE_DIRECTORIES(${BUILD_INCLUDE_DIR} ${INCLUDE_DIRECTORIES})
    ENDIF()
ELSE(CMAKE_TOOLCHAIN_FILE)
    MESSAGE("Host Library : ${PROJECT_NAME} ${PROJECT_VERSION}") 
    SET(BUILD_INCLUDE_DIR   ${CMAKE_BINARY_DIR}/include)
    CONFIGURE_FILE(
        "${CMAKE_CURRENT_SOURCE_DIR}/config.h.in"
        "${BUILD_INCLUDE_DIR}/config.h"
    )
    INCLUDE_DIRECTORIES(${BUILD_INCLUDE_DIR} ${INCLUDE_DIRECTORIES})
ENDIF(CMAKE_TOOLCHAIN_FILE)

