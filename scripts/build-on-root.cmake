# Build yunibase tree on root (without Git updating)
#
# INPUTS:
#   ONLY: List of impl.

set(_buildroot /build)
set(_mypath ${CMAKE_CURRENT_LIST_DIR})
get_filename_component(_mysrc ${_mypath}/.. ABSOLUTE)
get_filename_component(_mysrcroot ${_mysrc}/.. ABSOLUTE)
set(_myrootdir /yunisrc)
# FIXME: Abort on my directory != yunibase
set(_myroot /yunisrc/yunibase)

file(MAKE_DIRECTORY ${_buildroot})

set(_myargs)

if(ONLY)
    list(APPEND _myargs "-DYUNIBASE_ONLY=${ONLY}")
endif()

message(STATUS "Copying tree ${_mysrc} => ${_myroot}")

file(COPY ${_mysrc} DESTINATION ${_myrootdir}
    PATTERN ".git" EXCLUDE)

message(STATUS "Configure(${_myroot})... ${_myargs}")

execute_process(COMMAND
    ${CMAKE_COMMAND} ${_myargs} ${_myroot}
    RESULT_VARIABLE rr
    WORKING_DIRECTORY ${_buildroot}
)
if(rr)
    message(FATAL_ERROR "Faild to configure tree")
endif()

message(STATUS "Building...")

execute_process(COMMAND
    ${CMAKE_COMMAND} --build .
    RESULT_VARIABLE rr
    WORKING_DIRECTORY ${_buildroot})

if(rr)
    message(FATAL_ERROR "Faild to build tree")
endif()

message(STATUS "Done.")
