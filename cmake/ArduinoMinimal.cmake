if(NOT ARDUINO_IDE)
  set(ARDUINO_IDE "${CMAKE_CURRENT_SOURCE_DIR}/../arduino-1.8.3")
endif()

set(RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build")
set(LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build")
set(LIBRARY_OUTPUT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/build")
set(GITDEPS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/gitdeps")

set(ARDUINO_BOARD "arduino_zero")
set(ARDUINO_MCU "cortex-m0plus")
set(ARDUINO_FCPU "48000000L")

set(ARDUINO_IDE_LIBRARIES_PATH "${ARDUINO_IDE}/libraries")
set(ARDUINO_TOOLS_PATH "${ARDUINO_IDE}/packages/arduino/tools")

set(ARDUINO_BOARD_CORE_ROOT "${ARDUINO_IDE}/packages/adafruit/hardware/samd/1.0.12")
set(ARDUINO_BOARD_CORE_LIBRARIES_PATH "${ARDUINO_BOARD_CORE_ROOT}/libraries")
set(ARDUINO_CORE_DIRECTORY "${ARDUINO_BOARD_CORE_ROOT}/cores/arduino/")
set(ARDUINO_BOARD_DIRECTORY "${ARDUINO_BOARD_CORE_ROOT}/variants/${ARDUINO_BOARD}")
set(ARDUINO_BOOTLOADER "${ARDUINO_BOARD_CORE_ROOT}/variants/${ARDUINO_BOARD}/linker_scripts/gcc/flash_with_bootloader.ld")

set(ARDUINO_CMSIS_DIRECTORY "${ARDUINO_TOOLS_PATH}/CMSIS/4.0.0-atmel/CMSIS/Include/")
set(ARDUINO_DEVICE_DIRECTORY "${ARDUINO_TOOLS_PATH}/CMSIS/4.0.0-atmel/Device/ATMEL/")
set(ARM_TOOLS "${ARDUINO_TOOLS_PATH}/arm-none-eabi-gcc/4.8.3-2014q1/bin")
set(CMAKE_C_COMPILER "${ARM_TOOLS}/arm-none-eabi-gcc")
set(CMAKE_CXX_COMPILER "${ARM_TOOLS}/arm-none-eabi-g++")
set(CMAKE_ASM_COMPILER "${ARM_TOOLS}/arm-none-eabi-gcc")
set(ARDUINO_OBJCOPY "${ARM_TOOLS}/arm-none-eabi-objcopy")
set(ARDUINO_NM "${ARM_TOOLS}/arm-none-eabi-nm")
SET(CMAKE_AR "${ARM_TOOLS}/arm-none-eabi-ar")
SET(CMAKE_RANLIB "${ARM_TOOLS}/arm-none-eabi-ranlib")

set(PRINTF_FLAGS -lc -u _printf_float)
set(ARDUINO_USB_STRING_FLAGS "-DUSB_MANUFACTURER=\"Arduino LLC\" -DUSB_PRODUCT=\"\\\"Arduino Zero\\\"\"")
set(CMAKE_BOARD_FLAGS "-DF_CPU=${ARDUINO_FCPU} -DARDUINO=2491 -DARDUINO_M0PLUS=10605 -DARDUINO_SAMD_ZERO -DARDUINO_ARCH_SAMD -D__SAMD21G18A__ -DUSB_VID=0x2341 -DUSB_PID=0x804d -DUSBCON")
set(CMAKE_C_FLAGS   "-g -Os -std=gnu11   -ffunction-sections -fdata-sections -nostdlib --param max-inline-insns-single=500 -MMD -mcpu=${ARDUINO_MCU} -mthumb ${CMAKE_BOARD_FLAGS}")
set(CMAKE_CXX_FLAGS "-g -Os -std=gnu++11 -ffunction-sections -fdata-sections -nostdlib --param max-inline-insns-single=500 -MMD -mcpu=${ARDUINO_MCU} -mthumb ${CMAKE_BOARD_FLAGS} -fno-threadsafe-statics  -fno-rtti -fno-exceptions")
set(CMAKE_ASM_FLAGS "-g -x assembler-with-cpp ${CMAKE_BOARD_FLAGS}")

include(LibraryFlags)
include(Samd21)

include_directories(${ARDUINO_CMSIS_DIRECTORY})
include_directories(${ARDUINO_DEVICE_DIRECTORY})
include_directories(${ARDUINO_CORE_DIRECTORY})
include_directories(${ARDUINO_BOARD_DIRECTORY})

link_directories(${ARDUINO_IDE_LIBRARIES_PATH})
link_directories(${ARDUINO_BOARD_CORE_LIBRARIES_PATH})

function(read_arduino_libraries VAR_NAME PATH)
  set(libraries)

  set(libraries_file ${PATH}/arduino-libraries)
  message("-- Looking for ${libraries_file}")
  if(EXISTS ${libraries_file})
    execute_process(COMMAND arduino-deps --dir ${GITDEPS_DIRECTORY} --config ${libraries_file})

    link_directories(${CMAKE_SOURCE_DIR}/gitdeps)

    file(READ ${libraries_file} libraries_raw)
    STRING(REGEX REPLACE "\n" ";" libraries_raw "${libraries_raw}")

    foreach(temp ${libraries_raw})
      if(${temp} MATCHES "^https?.+")
        string(REGEX REPLACE ".*/" "" short_name ${temp})
        string(REGEX REPLACE ".git" "" short_name ${short_name})
        list(APPEND libraries ${short_name})
      else()
        list(APPEND libraries ${temp})
      endif()
    endforeach()
  else()
  endif()

  set(${VAR_NAME} ${libraries} PARENT_SCOPE)
endfunction()

set(ARDUINO_SOURCE_FILES
  ${ARDUINO_BOARD_DIRECTORY}/variant.cpp
  ${ARDUINO_CORE_DIRECTORY}/pulse_asm.S
  ${ARDUINO_CORE_DIRECTORY}/avr/dtostrf.c
  ${ARDUINO_CORE_DIRECTORY}/wiring_shift.c
  ${ARDUINO_CORE_DIRECTORY}/WInterrupts.c
  ${ARDUINO_CORE_DIRECTORY}/pulse.c
  ${ARDUINO_CORE_DIRECTORY}/cortex_handlers.c
  ${ARDUINO_CORE_DIRECTORY}/wiring_digital.c
  ${ARDUINO_CORE_DIRECTORY}/startup.c
  ${ARDUINO_CORE_DIRECTORY}/hooks.c
  ${ARDUINO_CORE_DIRECTORY}/wiring_private.c
  ${ARDUINO_CORE_DIRECTORY}/itoa.c
  ${ARDUINO_CORE_DIRECTORY}/delay.c
  ${ARDUINO_CORE_DIRECTORY}/wiring_analog.c
  ${ARDUINO_CORE_DIRECTORY}/USB/PluggableUSB.cpp
  ${ARDUINO_CORE_DIRECTORY}/USB/USBCore.cpp
  ${ARDUINO_CORE_DIRECTORY}/USB/samd21_host.c
  ${ARDUINO_CORE_DIRECTORY}/USB/CDC.cpp
  ${ARDUINO_CORE_DIRECTORY}/wiring.c
  ${ARDUINO_CORE_DIRECTORY}/abi.cpp
  ${ARDUINO_CORE_DIRECTORY}/Print.cpp
  ${ARDUINO_CORE_DIRECTORY}/Reset.cpp
  ${ARDUINO_CORE_DIRECTORY}/Stream.cpp
  ${ARDUINO_CORE_DIRECTORY}/Tone.cpp
  ${ARDUINO_CORE_DIRECTORY}/WMath.cpp
  ${ARDUINO_CORE_DIRECTORY}/RingBuffer.cpp
  ${ARDUINO_CORE_DIRECTORY}/SERCOM.cpp
  ${ARDUINO_CORE_DIRECTORY}/Uart.cpp
  ${ARDUINO_CORE_DIRECTORY}/WString.cpp
  ${ARDUINO_CORE_DIRECTORY}/new.cpp
  ${ARDUINO_CORE_DIRECTORY}/IPAddress.cpp
  ${ARDUINO_CORE_DIRECTORY}/main.cpp
)

add_library(core STATIC ${ARDUINO_SOURCE_FILES})

macro(arduino TARGET_NAME TARGET_SOURCE_FILES LIBRARIES)
  message("-- Configuring ${TARGET_NAME}")

  # Read everything about all the libraries we're depending on.
  read_arduino_libraries(PROJECT_LIBRARIES ${CMAKE_CURRENT_SOURCE_DIR})
  set(ALL_LIBRARIES "${GLOBAL_LIBRARIES};${PROJECT_LIBRARIES};${LIBRARIES}")
  setup_libraries(LIBRARY_INFO "${ARDUINO_BOARD}" "${ALL_LIBRARIES}")

  # Configure top level binrary target/dependencies.
  set_source_files_properties(${TARGET_SOURCE_FILES} PROPERTIES LANGUAGE CXX)

  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set_source_files_properties(${TARGET_SOURCE_FILES} PROPERTIES COMPILE_FLAGS "${EXTRA_CXX_FLAGS_PROJECT} -x c++")
  else()
    set_source_files_properties(${TARGET_SOURCE_FILES} PROPERTIES COMPILE_FLAGS "${EXTRA_CXX_FLAGS_PROJECT}")
  endif()

  add_library(${TARGET_NAME} STATIC ${ARDUINO_CORE_DIRECTORY}/main.cpp ${TARGET_SOURCE_FILES})
  add_custom_target(${TARGET_NAME}.elf)
  add_dependencies(${TARGET_NAME}.elf core ${TARGET_NAME})

  # Pull all library includes and tack them onto the end of our flag vars and
  # also add them as dependencies of the top level target.
  set(LIB_INCLUDES)
  foreach(key ${LIBRARY_INFO})
    set(LIB_INCLUDES "${LIB_INCLUDES} ${${key}_INCLUDES}")

    list(GET "${key}_INFO" 3 HEADERS_ONLY)
    list(GET "${key}_INFO" 4 LIB_TARGET_NAME)

    if(NOT HEADERS_ONLY)
      message("-- Dependency ${TARGET_NAME} ${LIB_TARGET_NAME}")
      add_dependencies(${TARGET_NAME}.elf ${LIB_TARGET_NAME})
      list(APPEND LIBRARY_DEPS "${LIBRARY_OUTPUT_DIRECTORY}/lib${LIB_TARGET_NAME}.a")
    endif()
  endforeach(key)

  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${EXTRA_C_FLAGS_ALL} ${LIB_INCLUDES}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${EXTRA_CXX_FLAGS_ALL} ${LIB_INCLUDES}")

  add_custom_command(TARGET ${TARGET_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_C_COMPILER} -Os -Wl,--gc-sections -save-temps -T${ARDUINO_BOOTLOADER} ${PRINTF_FLAGS}
    --specs=nano.specs --specs=nosys.specs -mcpu=${ARDUINO_MCU} -mthumb -Wl,--cref -Wl,--check-sections
    -Wl,--gc-sections -Wl,--unresolved-symbols=report-all -Wl,--warn-common -Wl,--warn-section-align
    -Wl,-Map,${LIBRARY_OUTPUT_DIRECTORY}/${TARGET_NAME}.map -o ${LIBRARY_OUTPUT_DIRECTORY}/${TARGET_NAME}.elf
    -lm ${LIBRARY_OUTPUT_DIRECTORY}/lib${TARGET_NAME}.a ${LIBRARY_DEPS} ${LIBRARY_OUTPUT_DIRECTORY}/libcore.a
  )

  add_custom_target(${TARGET_NAME}.bin)

  add_dependencies(${TARGET_NAME}.bin ${TARGET_NAME}.elf)

  add_custom_command(TARGET ${TARGET_NAME}.bin POST_BUILD COMMAND ${ARDUINO_OBJCOPY} -O binary
    ${RUNTIME_OUTPUT_DIRECTORY}/${TARGET_NAME}.elf
    ${RUNTIME_OUTPUT_DIRECTORY}/${TARGET_NAME}.bin)

  add_custom_command(TARGET ${TARGET_NAME}.bin POST_BUILD COMMAND ${ARDUINO_NM} --print-size --size-sort --radix=d
    ${RUNTIME_OUTPUT_DIRECTORY}/${TARGET_NAME}.elf > ${RUNTIME_OUTPUT_DIRECTORY}/${TARGET_NAME}.syms)

  add_custom_target(${TARGET_NAME}_bin ALL DEPENDS ${TARGET_NAME}.bin)

  set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES
    "${LIBRARY_OUTPUT_DIRECTORY}/${TARGET_NAME}.elf"
    "${LIBRARY_OUTPUT_DIRECTORY}/${TARGET_NAME}.bin"
    "${LIBRARY_OUTPUT_DIRECTORY}/${TARGET_NAME}.map")
endmacro()

function(library_find_path VAR_NAME LIB_NAME_OR_RELATIVE_PATH LIB_SHORT_NAME)
    get_property(LIBRARY_SEARCH_PATH
      DIRECTORY # Property Scope
      PROPERTY LINK_DIRECTORIES)

    foreach(LIB_SEARCH_PATH ${LIBRARY_SEARCH_PATH} ${ARDUINO_LIBRARIES_PATH} ${CMAKE_CURRENT_SOURCE_DIR}
                            ${CMAKE_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/libraries ${ARDUINO_EXTRA_LIBRARIES_PATH})
      if(EXISTS ${LIB_SEARCH_PATH}/${LIB_NAME_OR_RELATIVE_PATH}/${LIB_SHORT_NAME}.h)
        set(${VAR_NAME} ${LIB_SEARCH_PATH}/${LIB_NAME_OR_RELATIVE_PATH} PARENT_SCOPE)
        break()
      endif()
      if(EXISTS ${LIB_SEARCH_PATH}/${LIB_NAME_OR_RELATIVE_PATH}/src/${LIB_SHORT_NAME}.h)
        set(${VAR_NAME} ${LIB_SEARCH_PATH}/${LIB_NAME_OR_RELATIVE_PATH}/src PARENT_SCOPE)
        break()
      endif()
      if(EXISTS ${LIB_SEARCH_PATH}/${LIB_NAME_OR_RELATIVE_PATH}/src)
        set(${VAR_NAME} ${LIB_SEARCH_PATH}/${LIB_NAME_OR_RELATIVE_PATH}/src PARENT_SCOPE)
        break()
      endif()
      if(EXISTS ${LIB_SEARCH_PATH}/${LIB_NAME_OR_RELATIVE_PATH})
        set(${VAR_NAME} ${LIB_SEARCH_PATH}/${LIB_NAME_OR_RELATIVE_PATH} PARENT_SCOPE)
        break()
      endif()
    endforeach()
endfunction()

function(setup_libraries VAR_NAME ARDUINO_BOARD LIBRARIES)
  set(ALL_LIBS)
  set(ALL_LIB_TARGETS)
  set(ALL_LIB_INCLUDES)

  foreach(LIB_NAME_OR_RELATIVE_PATH ${LIBRARIES})
    string(REGEX REPLACE ".*/" "" LIB_SHORT_NAME ${LIB_NAME_OR_RELATIVE_PATH})

    library_find_path(LIB_PATH ${LIB_NAME_OR_RELATIVE_PATH} ${LIB_SHORT_NAME})

    if(NOT LIB_PATH)
      foreach(LIB_SEARCH_PATH ${LIBRARY_SEARCH_PATH} ${ARDUINO_LIBRARIES_PATH} ${CMAKE_CURRENT_SOURCE_DIR}
                              ${CMAKE_CURRENT_SOURCE_DIR}/libraries ${ARDUINO_EXTRA_LIBRARIES_PATH})
        message("Path: ${LIB_SEARCH_PATH}")
      endforeach()

      message(FATAL_ERROR "Error finding ${LIB_NAME_OR_RELATIVE_PATH}")
    endif()

    # Detect if recursion is needed
    if (NOT DEFINED ${LIB_SHORT_NAME}_RECURSE)
      set(${LIB_SHORT_NAME}_RECURSE False)
    endif()

    find_sources(LIB_SRCS ${LIB_PATH} ${${LIB_SHORT_NAME}_RECURSE})

    headers_only(HEADERS_ONLY "${LIB_SRCS}")

    set(LIB_TARGET_NAME ${ARDUINO_BOARD}_${LIB_SHORT_NAME})

    set(LIB_INCLUDES "-I\"${LIB_PATH}\" -I\"${LIB_PATH}/utility\"")

    # Create target if we don't have one yet.
    if(NOT TARGET ${LIB_TARGET_NAME})
      if(NOT HEADERS_ONLY)
        add_library(${LIB_TARGET_NAME} STATIC ${LIB_SRCS})

        message("-- Configuring library: ${LIB_TARGET_NAME} (${LIB_PATH})")

        if (LIB_INCLUDES)
          string(REPLACE ";" " " LIB_INCLUDES "${LIB_INCLUDES}")
        endif()

        set_target_properties(${LIB_TARGET_NAME} PROPERTIES
          COMPILE_FLAGS "${ARDUINO_COMPILE_FLAGS} ${LIB_INCLUDES} -I\"${LIB_PATH}\" -I\"${LIB_PATH}/utility\" ${COMPILE_FLAGS}"
          LINK_FLAGS "${ARDUINO_LINK_FLAGS} ${LINK_FLAGS}")

        target_link_libraries(${LIB_TARGET_NAME} ${ARDUINO_BOARD}_CORE ${ALL_LIB_TARGETS})

        list(APPEND ALL_LIB_INCLUDES ${LIB_INCLUDES})
        list(APPEND ALL_LIB_TARGETS ${LIB_TARGET_NAME})
      else()
        message("-- Configuring headers only library: ${LIB_TARGET_NAME}")
      endif()
    else()
      message("-- Library already configured: ${LIB_TARGET_NAME}")

      list(APPEND ALL_LIB_TARGETS ${LIB_TARGET_NAME})
    endif()

    # message("-- ${LIB_SHORT_NAME} ${LIB_NAME_OR_RELATIVE_PATH}")
    # message("   ${LIB_PATH}")
    # message("   ${HEADERS_ONLY}")

    set(INFO ${LIB_SHORT_NAME} ${LIB_NAME_OR_RELATIVE_PATH} ${LIB_PATH} ${HEADERS_ONLY} ${LIB_TARGET_NAME})

    set(LIB_${LIB_SHORT_NAME}_INFO "${INFO}" PARENT_SCOPE)
    set(LIB_${LIB_SHORT_NAME}_SOURCES "${LIB_SRCS}" PARENT_SCOPE)
    set(LIB_${LIB_SHORT_NAME}_INCLUDES "${LIB_INCLUDES}" PARENT_SCOPE)

    list(APPEND ALL_LIBS "LIB_${LIB_SHORT_NAME}")
  endforeach()

  set(${VAR_NAME} ${ALL_LIBS} PARENT_SCOPE)
endfunction()

function(headers_only VAR_NAME FILES)
  set(${VAR_NAME} True PARENT_SCOPE)
  foreach(temp ${FILES})
    if(${temp} MATCHES "(.cpp|cxx|c)$")
      set(${VAR_NAME} False PARENT_SCOPE)
    endif()
  endforeach()
endfunction()

function(find_sources VAR_NAME LIB_PATH RECURSE)
  set(FILE_SEARCH_LIST
    ${LIB_PATH}/*.cpp
    ${LIB_PATH}/*.c
    ${LIB_PATH}/*.cc
    ${LIB_PATH}/*.cxx
    ${LIB_PATH}/*.h
    ${LIB_PATH}/*.hh
    ${LIB_PATH}/*.hxx)

  if(RECURSE)
    file(GLOB_RECURSE LIB_FILES ${FILE_SEARCH_LIST})
  else()
    file(GLOB LIB_FILES ${FILE_SEARCH_LIST})
  endif()

  set(${VAR_NAME} ${LIB_FILES} PARENT_SCOPE)
endfunction()
