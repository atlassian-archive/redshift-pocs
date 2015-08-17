# -- Functions ---------------------------------------------------------

# Define GNU M4 preprocessor macros
#
# Generate M4 code and M4 command-line arguments.
#
# It is expected that the caller has defined the following variables:
# BUILD_TIME
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_REGION
# AWS_CF_STACK_NAME
# PGHOST
# WORKER_HOSTS
# WORKER_COUNT
# WORKER_IAM_ROLE
# CORES_PER_WORKER
# TOTAL_CORES
# SSH_USERNAME
# SCALE_FACTOR
# ORDER_KEY_DATA_TYPE
# TABLENAME
function(define_m4_defines OUT_M4_CMD_LINE)
  string(REPLACE ";" "_" WORKER_HOSTS_CSV "${WORKER_HOSTS}")

  set(MACROS
      "__BUILD_TIME__=${BUILD_TIME}"
      "__AWS_ACCESS_KEY_ID__=${AWS_ACCESS_KEY_ID}"
      "__AWS_SECRET_ACCESS_KEY__=${AWS_SECRET_ACCESS_KEY}"
      "__AWS_TEMP_TOKEN__=${AWS_TEMP_TOKEN}"
      "__AWS_REGION__=${AWS_REGION}"
      "__AWS_CF_STACK_NAME__=${AWS_CF_STACK_NAME}"
      "__PGHOST__=${PGHOST}"
      "__WORKER_HOSTS__=${WORKER_HOSTS_CSV}"
      "__WORKER_COUNT__=${WORKER_COUNT}"
      "__WORKER_IAM_ROLE__=${WORKER_IAM_ROLE}"
      "__CORES_PER_WORKER__=${CORES_PER_WORKER}"
      "__TOTAL_CORES__=${TOTAL_CORES}"
      "__SSH_USERNAME__=${SSH_USERNAME}"
      "__SCALE_FACTOR__=${SCALE_FACTOR}"
      "__ORDER_KEY_DATA_TYPE__=${ORDER_KEY_DATA_TYPE}"
      "__TABLENAME__=${TABLENAME}"
  )
  list_replace("^(.+)$" "-D\\\\1" ${OUT_M4_CMD_LINE} ${MACROS})

  # Pass values to caller
  set(${OUT_M4_CMD_LINE} "${${OUT_M4_CMD_LINE}}" PARENT_SCOPE)
endfunction(define_m4_defines)


# -- Macros ------------------------------------------------------------

# Add files to be preprocessed with m4
macro(add_m4_files OUT_TARGET_FILES IN_SOURCE_DIR IN_TARGET_DIR IN_EXTENSION)
  set(IN_M4_ARGUMENTS ${ARGN})

  get_filename_component(SOURCE_DIR_ABS "${IN_SOURCE_DIR}" ABSOLUTE)
  get_filename_component(TARGET_DIR_ABS "${IN_TARGET_DIR}" ABSOLUTE)
  file(
    GLOB_RECURSE FILES
    RELATIVE "${SOURCE_DIR_ABS}"
    "${SOURCE_DIR_ABS}/*.${IN_EXTENSION}_in"
  )
  set(
    M4_PREPROCESSING
    COMMAND ${CMAKE_COMMAND} -E make_directory "\"\${OUTDIR}\""
    COMMAND ${M4_BINARY} ${M4_ARGUMENTS} ${IN_M4_ARGUMENTS}
            "\"\${CURRENT_PATH}\"" > "\"\${OUTFILE}\""
  )
  batch_add_command(
    TARGET_PREFIX "${TARGET_DIR_ABS}/"
    SOURCE_PREFIX "${SOURCE_DIR_ABS}/"
    TARGET_SUFFIX ".${IN_EXTENSION}"
    SOURCE_SUFFIX "[.]${IN_EXTENSION}_in"
    RUN "${M4_PREPROCESSING}"
    COMMENT "Preprocessing \${CURRENT_FILE} with m4."
    TARGET_FILE_LIST_REF ${OUT_TARGET_FILES}
    SOURCE_FILE_LIST ${FILES}
  )
endmacro(add_m4_files)


# -- Subdirectories -----------------------------------------------------------

if(${COMPONENT} STREQUAL "client")
  add_subdirectory(client)
elseif(${COMPONENT} STREQUAL "worker")
  add_subdirectory(worker)
  add_subdirectory(vendor)
else(${COMPONENT} STREQUAL "client")
  add_subdirectory(client)
  add_subdirectory(worker)
  add_subdirectory(vendor)
endif(${COMPONENT} STREQUAL "client")
