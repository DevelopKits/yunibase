# 

macro(apply_envp ev app)
    set(ENV{${ev}} "${app}:$ENV{${ev}}")
    message(STATUS "ENV: ${ev} = $ENV{${ev}}")
    if("${ARGN}" STREQUAL "")
        # Complete
    else()
        apply_envp(${ARGN})
    endif()
endmacro()

macro(get_current_timestamp var_year var)
    # Require CMake 3.0
    #  Year2@day@hour24@min@sec
    #  fix??: It breaks if build covered the century..
    string(TIMESTAMP _currenttime "%y@%j@%H@%M@%S")
    if(${_currenttime} MATCHES "(..)@(...)@(..)@(..)@(..)")
        set(_year2 ${CMAKE_MATCH_1})
        set(_day ${CMAKE_MATCH_2})
        set(_hour ${CMAKE_MATCH_3})
        set(_min ${CMAKE_MATCH_4})
        set(_sec ${CMAKE_MATCH_5})
    else()
        message(FATAL_ERROR "Huh? ${_currenttime}")
    endif()

    set(${var_year} ${_year2})
    # Do the math(TM)
    math(EXPR ${var} 
        "(((${_day} * 24) + ${_hour}) * 60 + ${_min}) * 60 + ${_sec}")
endmacro()

macro(try_process result resultsym time workdir outlog errlog timeout)
    # ARGN = CMD
    set(_do_next TRUE)
    if(${timeout} EQUAL 0)
        set(_timeoutarg "")
    else()
        set(_timeoutarg TIMEOUT ${timeout})
    endif()
    while(_do_next)
        get_current_timestamp(start_year start_time)
        execute_process(COMMAND ${ARGN}
            WORKING_DIRECTORY ${workdir}
            OUTPUT_FILE ${outlog}
            ERROR_FILE ${errlog}
            ${_timeoutarg}
            RESULT_VARIABLE rr)
        get_current_timestamp(end_year end_time)
        set(_do_next FALSE)
    endwhile()
    if(NOT ${start_year} STREQUAL ${end_year})
        message(FATAL_ERROR "Happy new year!")
    endif()
    math(EXPR ${time} "${end_time} - ${start_time}")
    set(${result} ${rr})
    if(rr)
        # FIXME: Set TIMEOUT for timeout
        set(${resultsym} FAIL)
    else()
        set(${resultsym} SUCCESS)
    endif()
endmacro()

function(gen_report prefix reportfile result duration)
    string(TIMESTAMP _timestamp)

    file(WRITE ${reportfile}
        "set(${prefix}_RESULT ${result})\n")
    file(APPEND ${reportfile}
        "set(${prefix}_DURATION ${duration})\n")
    file(APPEND ${reportfile}
        "set(${prefix}_TIMESTAMP \"${_timestamp}\")\n")
endfunction()

macro(run_step tgt stepname dir cfgdir rptdir logdir envp)
    set(outlog ${logdir}/${tgt}_${stepname}_stdout.log)
    set(errlog ${logdir}/${tgt}_${stepname}_stderr.log)
    set(report ${rptdir}/${tgt}_${stepname}_report.cmake)
    file(MAKE_DIRECTORY ${rptdir})
    file(MAKE_DIRECTORY ${logdir})
    if(EXISTS ${cfgdir}/config.cmake)
        include(${cfgdir}/config.cmake)
    endif()
    if("${stepname}" MATCHES "Test")
        set(is_test TRUE)
    else()
        set(is_test FALSE)
    endif()
    if("${stepname}" MATCHES "Bootstrap")
        set(is_bootstrap TRUE)
    else()
        set(is_bootstrap FALSE)
    endif()

    set(skip_this_step FALSE)
    if(is_test AND SKIP_TEST)
        set(skip_this_step TRUE)
    endif()
    if(is_bootstrap)
        if(SKIP_BOOTSTRAP)
            set(skip_this_step TRUE)
        endif()
    else()
        if(BOOTSTRAP_ONLY)
            set(skip_this_step TRUE)
        endif()
    endif()

    if(skip_this_step)
        message(STATUS "Skip: ${tgt}:${stepname}")
    else()
        message(STATUS "Running ${tgt}:${stepname}")
        foreach(e ${ARGN})
            message(STATUS " ${e}")
        endforeach()
        try_process(rr result etime 
            ${dir} ${outlog} ${errlog} 
            0 
            ${ARGN})
        if(rr)
            file(READ ${outlog} log_out)
            file(READ ${errlog} log_err)
            message(STATUS "stdout(${tgt}_${stepname}):")
            message("${log_out}")
            message(STATUS "stderr(${tgt}_${stepname}):")
            message("${log_err}")
            if(is_test)
                message(STATUS "Error in ${tgt}_${stepname} (ignored)")
            else()
                message(FATAL_ERROR "Error in ${tgt}_${stepname}")
            endif()
        endif()
        gen_report(${tgt}_${stepname} ${report} 
            ${result} ${etime})
        message(STATUS "Done ${tgt}:${stepname}")
    endif()
endmacro()
