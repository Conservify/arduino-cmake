set(ARDUINO_IDE "$ENV{HOME}/conservify/arduino-1.8.3")
set(ARDUINO_IDE_LIBRARIES_PATH "${ARDUINO_IDE}/libraries")
set(ARDUINO_CORE_ROOT_PATH "${ARDUINO_IDE}/packages/arduino")
set(ARDUINO_CORE_PATH "${ARDUINO_CORE_ROOT_PATH}/hardware/samd/1.6.6")
set(ARDUINO_CORE_LIBRARIES_PATH "${ARDUINO_CORE_PATH}/libraries")

set(ARDUINO_BOARD_CORE_ROOT_PATH "${ARDUINO_IDE}/packages/adafruit")
set(ARDUINO_BOARD_CORE_PATH "${ARDUINO_BOARD_CORE_ROOT_PATH}/hardware/samd/1.0.12")
set(ARDUINO_BOARD_CORE_LIBRARIES_PATH "${ARDUINO_BOARD_CORE_PATH}/libraries")

set(ARDUINO_BOARD "arduino_zero")
set(ARDUINO_MCU "cortex-m0plus")
set(ARDUINO_FCPU "48000000L")
set(BOARD_ID ${ARDUINO_BOARD})
set(EXECUTABLE_OUTPUT_PATH  "${CMAKE_CURRENT_SOURCE_DIR}/build")
set(LIBRARY_OUTPUT_PATH  "${CMAKE_CURRENT_SOURCE_DIR}/build")

set(ARDUINO_CORE_DIR "${ARDUINO_BOARD_CORE_PATH}/cores/arduino/")
set(ARDUINO_BOARD_DIR "${ARDUINO_BOARD_CORE_PATH}/variants/${ARDUINO_BOARD}")
set(ARDUINO_CMSIS_DIR "${ARDUINO_CORE_ROOT_PATH}/tools/CMSIS/4.0.0-atmel/CMSIS/Include/")
set(ARDUINO_DEVICE_DIR "${ARDUINO_CORE_ROOT_PATH}/tools/CMSIS/4.0.0-atmel/Device/ATMEL/")

set(ARM_TOOLS "${ARDUINO_CORE_ROOT_PATH}/tools/arm-none-eabi-gcc/4.8.3-2014q1/bin")
set(CMAKE_C_COMPILER "${ARM_TOOLS}/arm-none-eabi-gcc")
set(CMAKE_CXX_COMPILER "${ARM_TOOLS}/arm-none-eabi-g++")
set(CMAKE_ASM_COMPILER "${ARM_TOOLS}/arm-none-eabi-gcc")
set(ARDUINO_OBJCOPY "${ARM_TOOLS}/arm-none-eabi-objcopy")

set(ARDUINO_BOOTLOADER "${ARDUINO_BOARD_CORE_PATH}/variants/${ARDUINO_BOARD}/linker_scripts/gcc/flash_with_bootloader.ld")

set(PRINTF_FLAGS -lc -u _printf_float)
set(CMAKE_BOARD_FLAGS "-DF_CPU=${ARDUINO_FCPU} -DARDUINO=2491 -DARDUINO_M0PLUS=10605 -DARDUINO_SAMD_ZERO -DARDUINO_ARCH_SAMD -D__SAMD21G18A__ -DUSB_VID=0x2341 -DUSB_PID=0x804d -DUSBCON -DUSB_MANUFACTURER=\"Arduino LLC\" -DUSB_PRODUCT=\"\\\"Arduino Zero\\\"\"")
set(CMAKE_C_FLAGS   "-g -Os -w -std=gnu11   -ffunction-sections -pedantic -Werror -fdata-sections -nostdlib --param max-inline-insns-single=500 -MMD -mcpu=${ARDUINO_MCU} -mthumb ${CMAKE_BOARD_FLAGS}")
set(CMAKE_CXX_FLAGS "-g -Os -w -std=gnu++11 -ffunction-sections -pedantic -Werror -fdata-sections -nostdlib --param max-inline-insns-single=500 -MMD -mcpu=${ARDUINO_MCU} -mthumb ${CMAKE_BOARD_FLAGS} -fno-threadsafe-statics  -fno-rtti -fno-exceptions")
set(CMAKE_ASM_FLAGS "-g -x assembler-with-cpp ${CMAKE_BOARD_FLAGS}")
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")
set(CMAKE_SYSTEM_NAME Generic)
set(TUNNING_FLAGS "")

set(GITDEPS "${CMAKE_CURRENT_SOURCE_DIR}/gitdeps")

include_directories(${ARDUINO_CMSIS_DIR})
include_directories(${ARDUINO_DEVICE_DIR})
include_directories(${ARDUINO_CORE_DIR})
include_directories(${ARDUINO_BOARD_DIR})

link_directories(${ARDUINO_IDE_LIBRARIES_PATH})
link_directories(${ARDUINO_BOARD_CORE_LIBRARIES_PATH})

function(read_arduino_libraries VAR_NAME PATH)
  set(libraries)

  set(libraries_file ${PATH}/arduino-libraries)
  if(EXISTS ${libraries_file})
    execute_process(COMMAND arduino-deps --dir ${GITDEPS} --config ${libraries_file})

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
  endif()

  set(${VAR_NAME} ${libraries} PARENT_SCOPE)
endfunction()

set(ARDUINO_SOURCE_FILES
  ${ARDUINO_BOARD_DIR}/variant.cpp
  ${ARDUINO_CORE_DIR}/pulse_asm.S
  ${ARDUINO_CORE_DIR}/avr/dtostrf.c
  ${ARDUINO_CORE_DIR}/wiring_shift.c
  ${ARDUINO_CORE_DIR}/WInterrupts.c
  ${ARDUINO_CORE_DIR}/pulse.c
  ${ARDUINO_CORE_DIR}/cortex_handlers.c
  ${ARDUINO_CORE_DIR}/wiring_digital.c
  ${ARDUINO_CORE_DIR}/startup.c
  ${ARDUINO_CORE_DIR}/hooks.c
  ${ARDUINO_CORE_DIR}/wiring_private.c
  ${ARDUINO_CORE_DIR}/itoa.c
  ${ARDUINO_CORE_DIR}/delay.c
  ${ARDUINO_CORE_DIR}/wiring_analog.c
  ${ARDUINO_CORE_DIR}/USB/PluggableUSB.cpp
  ${ARDUINO_CORE_DIR}/USB/USBCore.cpp
  ${ARDUINO_CORE_DIR}/USB/samd21_host.c
  ${ARDUINO_CORE_DIR}/USB/CDC.cpp
  ${ARDUINO_CORE_DIR}/wiring.c
  ${ARDUINO_CORE_DIR}/abi.cpp
  ${ARDUINO_CORE_DIR}/Print.cpp
  ${ARDUINO_CORE_DIR}/Reset.cpp
  ${ARDUINO_CORE_DIR}/Stream.cpp
  ${ARDUINO_CORE_DIR}/Tone.cpp
  ${ARDUINO_CORE_DIR}/WMath.cpp
  ${ARDUINO_CORE_DIR}/RingBuffer.cpp
  ${ARDUINO_CORE_DIR}/SERCOM.cpp
  ${ARDUINO_CORE_DIR}/Uart.cpp
  ${ARDUINO_CORE_DIR}/WString.cpp
  ${ARDUINO_CORE_DIR}/new.cpp
  ${ARDUINO_CORE_DIR}/IPAddress.cpp
  ${ARDUINO_CORE_DIR}/main.cpp
)

add_library(core STATIC ${ARDUINO_SOURCE_FILES})

read_arduino_libraries(GLOBAL_LIBRARIES ${CMAKE_CURRENT_SOURCE_DIR})

macro(arduino TARGET_NAME TARGET_SOURCE_FILES LIBRARIES)
  read_arduino_libraries(PROJECT_LIBRARIES ${CMAKE_CURRENT_SOURCE_DIR})

  set(ALL_LIBRARIES "${GLOBAL_LIBRARIES};${PROJECT_LIBRARIES};${LIBRARIES}")

  setup_arduino_libraries(ALL_LIBS ${BOARD_ID} "${ALL_SRCS}" "${ALL_LIBRARIES}" "${LIB_DEP_INCLUDES}" "")

  set(PATHS)
  foreach(TEMP ${ALL_LIBS_INCLUDES})
    set(PATHS "${PATHS} ${TEMP}")
  endforeach()

  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${PATHS}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${PATHS}")

  add_library(${TARGET_NAME} STATIC ${ARDUINO_CORE_DIR}/main.cpp ${SOURCE_FILES})

  add_custom_target(${TARGET_NAME}.elf)

  add_dependencies(${TARGET_NAME}.elf core ${TARGET_NAME})

  set(LIBRARY_DEPS)
  foreach(LIB_PATH ${ALL_LIBRARIES})
    get_filename_component(LIB_NAME ${LIB_PATH} NAME)
    add_dependencies(${TARGET_NAME}.elf ${BOARD_ID}_${LIB_NAME})
    list(APPEND LIBRARY_DEPS "${LIBRARY_OUTPUT_PATH}/lib${BOARD_ID}_${LIB_NAME}.a")
  endforeach()

  add_custom_command(TARGET ${TARGET_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_C_COMPILER} -Os -Wl,--gc-sections -save-temps -T${ARDUINO_BOOTLOADER} ${PRINTF_FLAGS}
    --specs=nano.specs --specs=nosys.specs -mcpu=${ARDUINO_MCU} -mthumb -Wl,--cref -Wl,--check-sections
    -Wl,--gc-sections -Wl,--unresolved-symbols=report-all -Wl,--warn-common -Wl,--warn-section-align
    -Wl,-Map,${LIBRARY_OUTPUT_PATH}/${TARGET_NAME}.map -o ${LIBRARY_OUTPUT_PATH}/${TARGET_NAME}.elf
    -lm ${LIBRARY_OUTPUT_PATH}/lib${TARGET_NAME}.a ${LIBRARY_DEPS} ${LIBRARY_OUTPUT_PATH}/libcore.a
  )

  add_custom_target(${TARGET_NAME}.bin)

  add_dependencies(${TARGET_NAME}.bin ${TARGET_NAME}.elf)

  add_custom_command(TARGET ${TARGET_NAME}.bin POST_BUILD COMMAND ${ARDUINO_OBJCOPY} -O binary
    ${EXECUTABLE_OUTPUT_PATH}/${TARGET_NAME}.elf
    ${EXECUTABLE_OUTPUT_PATH}/${TARGET_NAME}.bin)

  add_custom_target(${TARGET_NAME}_bin ALL DEPENDS ${TARGET_NAME}.bin)

  set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES
    "${LIBRARY_OUTPUT_PATH}/${TARGET_NAME}.elf"
    "${LIBRARY_OUTPUT_PATH}/${TARGET_NAME}.bin"
    "${LIBRARY_OUTPUT_PATH}/${TARGET_NAME}.map")
endmacro()

function(find_arduino_libraries VAR_NAME LIBRARIES)
  set(ARDUINO_LIBS)

  foreach(LIBNAME ${LIBRARIES})
    get_property(LIBRARY_SEARCH_PATH
      DIRECTORY     # Property Scope
      PROPERTY LINK_DIRECTORIES)

    set(missing True)

    foreach(LIB_SEARCH_PATH ${LIBRARY_SEARCH_PATH} ${ARDUINO_LIBRARIES_PATH} ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_SOURCE_DIR}
                            ${CMAKE_CURRENT_SOURCE_DIR}/libraries ${ARDUINO_EXTRA_LIBRARIES_PATH})
      if(NOT EXISTS ${LIB_SEARCH_PATH})
        # message(FATAL_ERROR "Missing ${LIB_SEARCH_PATH}")
      endif()
      if(EXISTS ${LIB_SEARCH_PATH}/${LIBNAME}/${LIBNAME}.h)
        list(APPEND ARDUINO_LIBS ${LIB_SEARCH_PATH}/${LIBNAME})
        set(missing False)
        break()
      endif()
      if(EXISTS ${LIB_SEARCH_PATH}/${LIBNAME}/src/${LIBNAME}.h)
        list(APPEND ARDUINO_LIBS ${LIB_SEARCH_PATH}/${LIBNAME})
        set(missing False)
        break()
      endif()
      if(EXISTS ${LIB_SEARCH_PATH}/${LIBNAME})
        list(APPEND ARDUINO_LIBS ${LIB_SEARCH_PATH}/${LIBNAME})
        set(missing False)
        break()
      endif()
    endforeach()

    if(missing)
      foreach(LIB_SEARCH_PATH ${LIBRARY_SEARCH_PATH} ${ARDUINO_LIBRARIES_PATH} ${CMAKE_CURRENT_SOURCE_DIR}
                              ${CMAKE_CURRENT_SOURCE_DIR}/libraries ${ARDUINO_EXTRA_LIBRARIES_PATH})
        message("Path: ${LIB_SEARCH_PATH}")
      endforeach()
      message(FATAL_ERROR "Error finding ${LIBNAME}")
    endif()
  endforeach()

  if(ARDUINO_LIBS)
    list(REMOVE_DUPLICATES ARDUINO_LIBS)
  endif()

  set(${VAR_NAME} ${ARDUINO_LIBS} PARENT_SCOPE)
endfunction()

function(setup_arduino_libraries VAR_NAME BOARD_ID SRCS LIBRARIES COMPILE_FLAGS LINK_FLAGS)
  set(LIB_TARGETS)
  set(LIB_INCLUDES)

  find_arduino_libraries(TARGET_LIBS "${LIBRARIES}")

  foreach(TARGET_LIB ${TARGET_LIBS})
    setup_arduino_library(LIB_DEPS ${BOARD_ID} ${TARGET_LIB} "${COMPILE_FLAGS}" "${LINK_FLAGS}")

    list(APPEND LIB_TARGETS ${LIB_DEPS})
    list(APPEND LIB_INCLUDES ${LIB_DEPS_INCLUDES})

    message("INCL:  ${BOARD_ID} ${TARGET_LIB} ${COMPILE_FLAGS} ${LINK_FLAGS} : ${LIB_DEPS_INCLUDES}")

  endforeach()

  set(${VAR_NAME}          ${LIB_TARGETS}  PARENT_SCOPE)
  set(${VAR_NAME}_INCLUDES ${LIB_INCLUDES} PARENT_SCOPE)
endfunction()

set(Wire_RECURSE True)
set(Ethernet_RECURSE True)
set(SD_RECURSE True)

function(setup_arduino_library VAR_NAME BOARD_ID LIB_PATH COMPILE_FLAGS LINK_FLAGS)
  set(LIB_TARGETS)
  set(LIB_INCLUDES)

  get_filename_component(LIB_NAME ${LIB_PATH} NAME)

  # SD library compatibility. I thought libraries had to have the header in the root directory?
  if(EXISTS ${LIB_PATH}/src/${LIB_NAME}.h)
    set(LIB_PATH "${LIB_PATH}/src")
  endif()

  set(TARGET_LIB_NAME ${BOARD_ID}_${LIB_NAME})

  # Do this everytime, not just when creating the target. That way if a library
  # is used more than once it'll get included.
  list(APPEND LIB_INCLUDES "-I\"${LIB_PATH}\" -I\"${LIB_PATH}/utility\"")

  # Create target if we don't have one yet.
  if(NOT TARGET ${TARGET_LIB_NAME})
    string(REGEX REPLACE ".*/" "" LIB_SHORT_NAME ${LIB_NAME})

    # Detect if recursion is needed
    if (NOT DEFINED ${LIB_SHORT_NAME}_RECURSE)
      set(${LIB_SHORT_NAME}_RECURSE False)
    endif()

    find_sources(LIB_SRCS ${LIB_PATH} ${${LIB_SHORT_NAME}_RECURSE})

    if(LIB_SRCS)
      add_library(${TARGET_LIB_NAME} STATIC ${LIB_SRCS})

      if (LIB_INCLUDES)
        string(REPLACE ";" " " LIB_INCLUDES "${LIB_INCLUDES}")
      endif()

      set_target_properties(${TARGET_LIB_NAME} PROPERTIES
        COMPILE_FLAGS "${ARDUINO_COMPILE_FLAGS} ${LIB_INCLUDES} -I\"${LIB_PATH}\" -I\"${LIB_PATH}/utility\" ${COMPILE_FLAGS}"
        LINK_FLAGS "${ARDUINO_LINK_FLAGS} ${LINK_FLAGS}")

      target_link_libraries(${TARGET_LIB_NAME} ${BOARD_ID}_CORE ${LIB_TARGETS})

      list(APPEND LIB_TARGETS ${TARGET_LIB_NAME})
    endif()
  else()
    list(APPEND LIB_TARGETS ${TARGET_LIB_NAME})
  endif()

  if(LIB_TARGETS)
    list(REMOVE_DUPLICATES LIB_TARGETS)
  endif()

  set(${VAR_NAME}          ${LIB_TARGETS}  PARENT_SCOPE)
  set(${VAR_NAME}_INCLUDES ${LIB_INCLUDES} PARENT_SCOPE)
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

  if(LIB_FILES)
    set(${VAR_NAME} ${LIB_FILES} PARENT_SCOPE)
  endif()
endfunction()
