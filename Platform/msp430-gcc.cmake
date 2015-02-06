# Helper macro for LIST_REPLACE
macro(LIST_REPLACE LISTV OLDVALUE NEWVALUE)
	LIST(FIND ${LISTV} ${OLDVALUE} INDEX)
	LIST(INSERT ${LISTV} ${INDEX} ${NEWVALUE})
	MATH(EXPR __INDEX "${INDEX} + 1")
	LIST(REMOVE_AT ${LISTV} ${__INDEX})
endmacro(LIST_REPLACE)

# Wrapper around ADD_EXECUTABLE, which adds the necessary -mmcu flags and
# sets up builds for multiple devices. Also creates targets to generate 
# disassembly listings, size outputs, map files, and to upload to device. 
# Also adds all these extra files created including map files to the clean
# list.
FUNCTION(add_msp430_executable EXECUTABLE_NAME DEPENDENCIES)
	SET(DEVICES ${SUPPORTED_DEVICES})
	
	SET(EXE_NAME ${EXECUTABLE_NAME})
	LIST(REMOVE_AT  ARGV	0)
	
	SET(DEPS ${DEPENDENCIES})
	SEPARATE_ARGUMENTS(DEPS)
	LIST(REMOVE_AT  ARGV    0)
	
	FOREACH(device ${DEVICES})
		
		SET(ELF_FILE ${EXE_NAME}-${device}.elf)
		SET(MAP_FILE ${EXE_NAME}-${device}.map)
		SET(LST_FILE ${EXE_NAME}-${device}.lst)
		
		ADD_EXECUTABLE(${ELF_FILE} ${ARGN})
		SET_TARGET_PROPERTIES(
			${ELF_FILE} PROPERTIES
			COMPILE_FLAGS "-mmcu=${device}"
			LINK_FLAGS "-mmcu=${device} -Wl,-Map,${MAP_FILE}"
			)
		
		SET(DDEPS ${DEPS})
		
		IF(DDEPS)
		    LIST(REMOVE_DUPLICATES DDEPS)
		FOREACH(dep ${DDEPS})
			LIST_REPLACE(DDEPS "${dep}" "${dep}-${device}")
		ENDFOREACH(dep)
		    TARGET_LINK_LIBRARIES(${ELF_FILE} ${DDEPS})
		ENDIF(DDEPS)
		
		ADD_CUSTOM_TARGET(
			${EXE_NAME}-${device}.lst ALL
			${MSP430_OBJDUMP} -h -S ${ELF_FILE} > ${LST_FILE}
			DEPENDS ${ELF_FILE}
			)

		ADD_CUSTOM_TARGET(
			${EXE_NAME}-${device}-size ALL
			${MSP430_SIZE} ${ELF_FILE}
			DEPENDS ${ELF_FILE}
			)

		ADD_CUSTOM_TARGET(
			${EXE_NAME}-${device}-upload
			# TODO This needs to be better structured to allow 
			# programmer change
			${PROGBIN} -n ${PROGRAMMER} \"prog ${ELF_FILE}\"
			DEPENDS ${ELF_FILE}
			)

		LIST(APPEND	all_lst_files	${LST_FILE})
		LIST(APPEND 	all_elf_files 	${ELF_FILE})
		LIST(APPEND	all_map_files	${MAP_FILE})

	ENDFOREACH(device)
	
	ADD_CUSTOM_TARGET(
		${EXE_NAME} ALL
		DEPENDS ${all_elf_files}
		)

	GET_DIRECTORY_PROPERTY(clean_files ADDITIONAL_MAKE_CLEAN_FILES)
	LIST(APPEND clean_files ${all_map_files})
	LIST(APPEND clean_files ${all_lst_files})
	SET_DIRECTORY_PROPERTIES(PROPERTIES 
		ADDITIONAL_MAKE_CLEAN_FILES "${clean_files}"
	)
ENDFUNCTION(add_msp430_executable)

# Wrapper around ADD_LIBRARY, which adds the necessary -mmcu flags and
# sets up builds for multiple devices. 
FUNCTION(add_msp430_library LIBRARY_NAME LIBRARY_TYPE DEPENDENCIES)
	SET(DEVICES ${SUPPORTED_DEVICES})
	
	SET(LIB_NAME ${LIBRARY_NAME})
	LIST(REMOVE_AT  ARGV    0)
	
	SET(DEPS ${DEPENDENCIES})
	LIST(REMOVE_AT  ARGV    0)
	
	SET(TYPE ${LIBRARY_TYPE})
	LIST(REMOVE_AT  ARGV	0)
	
	FOREACH(device ${DEVICES})
		SET(LIB_FILE ${LIB_NAME}-${device})
		
		ADD_LIBRARY(${LIB_FILE} ${TYPE} ${ARGN})
		SET_TARGET_PROPERTIES(
				${LIB_FILE} PROPERTIES
				COMPILE_FLAGS "-mmcu=${device}"
				LINK_FLAGS "-mmcu=${device}"
			)
		
		SET(DDEPS ${DEPS})
		FOREACH(dep ${DEPS})
			LIST_REPLACE(DDEPS "${dep}" "${dep}-${device}")
		ENDFOREACH(dep)
		IF(DDEPS)
		    TARGET_LINK_LIBRARIES(${LIB_FILE} ${DDEPS})
		ENDIF(DDEPS)
	ENDFOREACH(device)
ENDFUNCTION(add_msp430_library)
