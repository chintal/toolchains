

FIND_PACKAGE(Doxygen)

IF(DOXYGEN_FOUND)
    SET(TMP_PP_INCL_DIRS)
    GET_PROPERTY(dirs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
    FOREACH(dir ${dirs})
        SET(TMP_PP_INCL_DIRS "${TMP_PP_INCL_DIRS} ${dir}")
    ENDFOREACH(dir ${dirs})
    SET(DOXYGEN_OUTPUT_DIR  "${CMAKE_SOURCE_DIR}/../doc")
        
    CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in
                    ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile @ONLY)

    ADD_CUSTOM_TARGET(doc-build   ${DOXYGEN_EXECUTABLE}
                        ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
                        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                        COMMENT "Generating documentation with Doxygen" VERBATIM)

#     ADD_CUSTOM_TARGET(doc-pdf   make
#                         WORKING_DIRECTORY ${DOXYGEN_OUTPUT_DIR}/latex
#                         COMMENT "Generating documentation PDF from Latex" VERBATIM
#                         DEPENDS doc-build)
                        
    ADD_CUSTOM_TARGET(doc       COMMENT "Generating Documenation" VERBATIM
                        DEPENDS doc-build)
    
ENDIF(DOXYGEN_FOUND)

