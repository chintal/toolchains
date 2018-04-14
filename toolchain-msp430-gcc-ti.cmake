# To be able to use Force Compiler macros.
include(CMakeForceCompiler)

# Add the location of your "toolchains" folder to the module path.
SET(TOOLCHAINS_PATH             "/home/chintal/code/toolchains")     
LIST(APPEND CMAKE_MODULE_PATH   ${TOOLCHAINS_PATH})
SET(PLATFORM_PACKAGES_PATH      "${TOOLCHAINS_PATH}/packages/msp430")
LIST(APPEND CMAKE_MODULE_PATH   "${PLATFORM_PACKAGES_PATH}/lib/cmake")
LIST(APPEND CMAKE_PREFIX_PATH   "${PLATFORM_PACKAGES_PATH}/lib/cmake")
INCLUDE_DIRECTORIES("${PLATFORM_PACKAGES_PATH}/include ${INCLUDE_DIRECTORIES}")

SET(SUPPORTED_DEVICES "msp430f5529;msp430f5521" 
#SET(SUPPORTED_DEVICES "msp430fr5969;msp430fr5959" 
        CACHE STRING "Supported Target Devices")

# Name should be 'Generic' or something for which a 
# Platform/<name>.cmake (or other derivatives thereof, see cmake docs)
# file exists. The cmake installation comes with a Platform folder with
# defined platforms, and we add our custom ones to the "Platform" folder
# within the "toolchain" folder.
set(CMAKE_SYSTEM_NAME msp430-gcc)

# Compiler and related toochain configuration
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SET(MSP430_TI_COMPILER_FOLDER   /opt/ti/msp430/gcc)
SET(MSP430_TI_BIN_FOLDER        ${MSP430_TI_COMPILER_FOLDER}/bin)
SET(MSP430_TI_INCLUDE_FOLDER    ${MSP430_TI_COMPILER_FOLDER}/include)
SET(TOOLCHAIN_PREFIX            msp430-elf)
SET(TOOLCHAIN_BIN_PATH          ${MSP430_TI_BIN_FOLDER})

INCLUDE_DIRECTORIES(${MSP430_TI_INCLUDE_FOLDER}     ${INCLUDE_DIRECTORIES})
LINK_DIRECTORIES(   ${MSP430_TI_INCLUDE_FOLDER}     ${LINK_DIRECTORIES})

# This can be skipped to directly set paths below, or augmented with hints
# and such. See cmake docs of FIND_PROGRAM for details.
FIND_PROGRAM(MSP430_CC      ${TOOLCHAIN_PREFIX}-gcc
                        PATHS ${TOOLCHAIN_BIN_PATH})
FIND_PROGRAM(MSP430_CXX     ${TOOLCHAIN_PREFIX}-g++
                        PATHS ${TOOLCHAIN_BIN_PATH})
FIND_PROGRAM(MSP430_AR      ${TOOLCHAIN_PREFIX}-ar
                        PATHS ${TOOLCHAIN_BIN_PATH})
FIND_PROGRAM(MSP430_AS      ${TOOLCHAIN_PREFIX}-as
                        PATHS ${TOOLCHAIN_BIN_PATH})
FIND_PROGRAM(MSP430_OBJDUMP ${TOOLCHAIN_PREFIX}-objdump
                        PATHS ${TOOLCHAIN_BIN_PATH})
FIND_PROGRAM(MSP430_OBJCOPY ${TOOLCHAIN_PREFIX}-objcopy
                        PATHS ${TOOLCHAIN_BIN_PATH})
FIND_PROGRAM(MSP430_SIZE    ${TOOLCHAIN_PREFIX}-size
                        PATHS ${TOOLCHAIN_BIN_PATH})
FIND_PROGRAM(MSP430_NM      ${TOOLCHAIN_PREFIX}-nm
                        PATHS ${TOOLCHAIN_BIN_PATH})
FIND_PROGRAM(MSP430_MSPDEBUG    mspdebug)

# Since the compiler needs an -mmcu flag to do anything, checks need to be bypassed
set(CMAKE_C_COMPILER    ${MSP430_CC} CACHE STRING "C Compiler")
set(CMAKE_CXX_COMPILER  ${MSP430_CXX} CACHE STRING "C++ Compiler")

set(AS      ${MSP430_AS}        CACHE STRING "AS Binary")
set(AR      ${MSP430_AR}        CACHE STRING "AR Binary")
set(OBJCOPY ${MSP430_OBJCOPY}   CACHE STRING "OBJCOPY Binary")
set(OBJDUMP ${MSP430_OBJDUMP}   CACHE STRING "OBJDUMP Binary")
set(SIZE 	${MSP430_SIZE}      CACHE STRING "SIZE Binary") 

IF(NOT CMAKE_BUILD_TYPE)
    SET(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING
        "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel."
        FORCE)
ENDIF(NOT CMAKE_BUILD_TYPE)

set(MSPGCC_WARN_PROFILE "-Wall -Wshadow -Wpointer-arith -Wbad-function-cast -Wcast-align -Wsign-compare -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations -Wunused"
                CACHE STRING "Warnings")

set(MSPGCC_DISABLED_BUILTINS   "-fno-builtin-printf -fno-builtin-sprintf"
                CACHE STRING "Disabled Builtins")

set(MSPGCC_OPTIONS  "-g -fdata-sections -ffunction-sections -fverbose-asm ${MSPGCC_DISABLED_BUILTINS}" 
                CACHE STRING "Compile Options")

                
set(CMAKE_C_FLAGS   "${MSPGCC_WARN_PROFILE} ${MSPGCC_OPTIONS} -DGCC_MSP430" 
                CACHE STRING "C Flags")

set(CMAKE_SHARED_LINKER_FLAGS 	"-Wl,--gc-sections -Wl,--print-gc-sections"
                CACHE STRING "Shared Library Linker Flags")

set(CMAKE_EXE_LINKER_FLAGS 	"-Wl,--gc-sections" 
                CACHE STRING "Executable Linker Flags")

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

set(PROGBIN     ${MSP430_MSPDEBUG} CACHE STRING "Programmer Application")
set(PROGRAMMER  tilib CACHE STRING "Programmer driver")
