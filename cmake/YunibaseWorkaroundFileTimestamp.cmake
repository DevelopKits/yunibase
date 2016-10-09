find_program(workaround_touch_use_touch_command
    touch)
function(workaround_touch_prebuilt_files base)
    # FIXME: Special WAR for absolute paths
    if("${base}" STREQUAL "/")
        set(pths0 ${ARGN})
    else()
        set(pths0)
        foreach(e ${ARGN})
            list(APPEND pths0 ${base}/${e})
        endforeach()
    endif()
    # GLOB over directories
    set(pths)
    foreach(e ${pths0})
        if(IS_DIRECTORY ${e})
            # Expand a directory into files
            file(GLOB_RECURSE content ${e}/*)
            list(APPEND pths ${content})
        elseif(EXISTS ${e})
            # Do not create nonexistent dir/files
            list(APPEND pths ${e})
        endif()
    endforeach()
    if(workaround_touch_use_touch_command)
        message(STATUS "Workaround: Touch (w/ touch)")
        foreach(e ${pths})
            message(STATUS "${e}")
        endforeach()
        execute_process(COMMAND
            ${workaround_touch_use_touch_command}
            ${pths})
    else()
        foreach(e ${pths})
            message(STATUS "Workaround: Touch ${base}/${e}")
            execute_process(COMMAND
                ${CMAKE_COMMAND} -E touch_nocreate ${base}/${e}
                # Ignore error
                )
        endforeach()
    endif()
endfunction()
