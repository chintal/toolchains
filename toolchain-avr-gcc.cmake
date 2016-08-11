# To be able to use Force Compiler macros.
include(CMakeForceCompiler)

# Add the location of your "toolchains" folder to the module path.
list(APPEND CMAKE_MODULE_PATH "/home/chintal/code/toolchains")
SET(PLATFORM_PACKAGES_PATH "/home/chintal/code/toolchains/packages/avr")
list(APPEND CMAKE_MODULE_PATH "${PLATFORM_PACKAGES_PATH}/lib/cmake")
list(APPEND CMAKE_PREFIX_PATH "${PLATFORM_PACKAGES_PATH}/lib/cmake")
INCLUDE_DIRECTORIES("${PLATFORM_PACKAGES_PATH}/include ${INCLUDE_DIRECTORIES}")

SET(SUPPORTED_DEVICES "atmega16;atmega32;atmega644;atmega48;atmega88;atmega168;atmega328" 
        CACHE STRING "Supported Target Devices")

# Name should be 'Generic' or something for which a 
# Platform/<name>.cmake (or other derivatives thereof, see cmake docs)
# file exists. The cmake installation comes with a Platform folder with
# defined platforms, and we add our custom ones to the "Platform" folder
# within the "toolchain" folder.
set(CMAKE_SYSTEM_NAME avr-gcc)

# Compiler and related toochain configuration
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SET(AVR_LIBC_FOLDER	        /usr/lib/avr)
SET(AVR_INCLUDE_FOLDER	    ${AVR_LIBC_FOLDER}/include)
SET(TOOLCHAIN_PREFIX		avr)

INCLUDE_DIRECTORIES(${AVR_INCLUDE_FOLDER} ${INCLUDE_DIRECTORIES})

# This can be skipped to directly set paths below, or augmented with hints
# and such. See cmake docs of FIND_PROGRAM for details.
FIND_PROGRAM(AVR_CC		    ${TOOLCHAIN_PREFIX}-gcc)
FIND_PROGRAM(AVR_CXX		${TOOLCHAIN_PREFIX}-g++)
FIND_PROGRAM(AVR_AR		    ${TOOLCHAIN_PREFIX}-ar)
FIND_PROGRAM(AVR_AS		    ${TOOLCHAIN_PREFIX}-as)
FIND_PROGRAM(AVR_OBJDUMP	${TOOLCHAIN_PREFIX}-objdump)
FIND_PROGRAM(AVR_OBJCOPY	${TOOLCHAIN_PREFIX}-objcopy)
FIND_PROGRAM(AVR_SIZE	    ${TOOLCHAIN_PREFIX}-size)
FIND_PROGRAM(AVR_NM		    ${TOOLCHAIN_PREFIX}-nm)
FIND_PROGRAM(AVR_DUDE	    avrdude)

# Since the compiler needs an -mmcu flag to do anything, checks need to be bypassed
CMAKE_FORCE_C_COMPILER(${AVR_CC} 	GNU)
CMAKE_FORCE_CXX_COMPILER(${AVR_CXX} 	GNU)

set(AS 		${AVR_AS} CACHE STRING "AS Binary")
set(AR 		${AVR_AR} CACHE STRING "AR Binary")
set(OBJCOPY 	${AVR_OBJCOPY} CACHE STRING "OBJCOPY Binary")
set(OBJDUMP 	${AVR_OBJDUMP} CACHE STRING "OBJDUMP Binary")
set(SIZE 	${AVR_SIZE} CACHE STRING "SIZE Binary") 

IF(NOT CMAKE_BUILD_TYPE)
	SET(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING
		"Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel."
		FORCE)
ENDIF(NOT CMAKE_BUILD_TYPE)

set(AVR_OPT_LEVEL 	"0" CACHE STRING "AVR GCC OPT LEVEL")

set(AVR_WARN_PROFILE "-Wall -Wshadow -Wpointer-arith -Wbad-function-cast -Wcast-align -Wsign-compare -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations -Wunused"
				CACHE STRING "AVR GCC WARNINGS")	

set(AVR_OPTIONS 	"-g -fdata-sections -ffunction-sections -fverbose-asm -std=gnu11" 
				CACHE STRING "AVR GCC OPTIONS")

set(CMAKE_C_FLAGS 	"${AVR_WARN_PROFILE} ${AVR_OPTIONS} -O${AVR_OPT_LEVEL} -DGCC_AVR" CACHE STRING "C Flags")

set(CMAKE_SHARED_LINKER_FLAGS 	"-Wl,--gc-sections -Wl,--print-gc-sections"
					CACHE STRING "Linker Flags")
set(CMAKE_EXE_LINKER_FLAGS 	"-Wl,--gc-sections" 
					CACHE STRING "Linker Flags")

# Specify linker command. This is needed to use gcc as linker instead of ld
# This seems to be the preferred way for MSPGCC atleast, seemingly to avoid
# linking against stdlib.
set(CMAKE_CXX_LINK_EXECUTABLE
	"<CMAKE_C_COMPILER> ${CMAKE_EXE_LINKER_FLAGS} <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>"
	CACHE STRING "C++ Executable Link Command")

set(CMAKE_C_LINK_EXECUTABLE ${CMAKE_CXX_LINK_EXECUTABLE}
	CACHE STRING "C Executable Link Command")

# Programmer and related toochain configuration
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

set(PROGBIN 	${AVR_DUDE} CACHE STRING "Programmer Application")
set(PROGRAMMER	tilib CACHE STRING "Programmer driver")
