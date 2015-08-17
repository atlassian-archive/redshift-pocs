# Given the length of the parameter list, we require named arguments.
# IN_COMMAND can contain "\${CURRENT_PATH}" and "\${OUTFILE}"
# IN_COMMENT can contain "\${CURRENT_FILE}" which will be substituted by the
# current file
macro(batch_add_command
    ARG_NAME_1 IN_TARGET_PREFIX
    ARG_NAME_2 IN_SOURCE_PREFIX
    ARG_NAME_3 IN_TARGET_SUFFIX
    ARG_NAME_4 IN_SOURCE_SUFFIX
    ARG_NAME_5 IN_COMMAND
    ARG_NAME_6 IN_COMMENT
    ARG_NAME_7 OUT_TARGET_FILES
    ARG_NAME_8)

    if( (NOT ("${ARG_NAME_1}" STREQUAL TARGET_PREFIX)) OR
        (NOT ("${ARG_NAME_2}" STREQUAL SOURCE_PREFIX)) OR
        (NOT ("${ARG_NAME_3}" STREQUAL TARGET_SUFFIX)) OR
        (NOT ("${ARG_NAME_4}" STREQUAL SOURCE_SUFFIX)) OR
        (NOT ("${ARG_NAME_5}" STREQUAL RUN)) OR
        (NOT ("${ARG_NAME_6}" STREQUAL COMMENT)) OR
        (NOT ("${ARG_NAME_7}" STREQUAL TARGET_FILE_LIST_REF)) OR
        (NOT ("${ARG_NAME_8}" STREQUAL SOURCE_FILE_LIST)) )

        message(FATAL_ERROR "Missing (or misspelled) arguments given to batch_add_command().")
    endif()
    set(IN_SOURCE_FILE_LIST ${ARGN})

    foreach(CURRENT_FILE ${IN_SOURCE_FILE_LIST})
        get_filename_component(CURRENT_PATH "${IN_SOURCE_PREFIX}${CURRENT_FILE}" ABSOLUTE)

        set(OUTFILE "${IN_TARGET_PREFIX}${CURRENT_FILE}")
        if(NOT ("${IN_SOURCE_SUFFIX}" STREQUAL ""))
            string(REGEX REPLACE "${IN_SOURCE_SUFFIX}\$" "${IN_TARGET_SUFFIX}" OUTFILE "${OUTFILE}")
        endif(NOT ("${IN_SOURCE_SUFFIX}" STREQUAL ""))
        get_dir_name(OUTDIR ${OUTFILE})

        string(REPLACE "\${CURRENT_PATH}" "${CURRENT_FILE}" IN_COMMAND "${IN_COMMAND}")
        string(REPLACE "\${OUTFILE}" "${OUTFILE}" IN_COMMAND "${IN_COMMAND}")
        string(REPLACE "\${OUTDIR}" "${OUTDIR}" IN_COMMAND "${IN_COMMAND}")
        string(REPLACE "\${CURRENT_FILE}" "${CURRENT_FILE}" IN_COMMENT "${IN_COMMENT}")

        add_custom_command(OUTPUT "${OUTFILE}"
            ${IN_COMMAND}
            DEPENDS "${CURRENT_PATH}"
            COMMENT "${IN_COMMENT}"
        )

        list(APPEND ${OUT_TARGET_FILES} ${OUTFILE})
    endforeach(CURRENT_FILE)
endmacro(batch_add_command)

macro(get_dir_name OUT_DIR IN_PATH)
    if(${IN_PATH} MATCHES "^.+/[^/]*\$")
        # If the argument for string(REGEX REPLACE does not match the
        # search string, CMake sets the output to the input string
        # This is not what we want, hence the if-block.
        string(REGEX REPLACE "^(.+)/[^/]*\$" "\\1" ${OUT_DIR} "${IN_PATH}")
    else(${IN_PATH} MATCHES "^.+/[^/]*\$")
        set(${OUT_DIR} "")
    endif(${IN_PATH} MATCHES "^.+/[^/]*\$")
endmacro(get_dir_name)

macro(list_replace IN_REGEX IN_REPLACE_STRING OUT_LIST)
    set(IN_LIST ${ARGN})

    set(${OUT_LIST})
    foreach(ITEM ${IN_LIST})
        string(REGEX REPLACE "${IN_REGEX}" "${IN_REPLACE_STRING}" ITEM_REPLACED "${ITEM}")
        list(APPEND ${OUT_LIST} "${ITEM_REPLACED}")
    endforeach(ITEM)
endmacro(list_replace)
