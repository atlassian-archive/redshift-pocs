# -- Third-party dependencies: Find aws ----------------------------------------
# TODO: Require a specific version.

find_program(
  AWS_BINARY aws
  PATHS /usr/local/bin /usr/bin /bin /opt/local/bin
  DOC "Path to the AWS CLI."
)

if(NOT AWS_BINARY)
  message(FATAL_ERROR "Cannot find the AWS CLI.")
endif(NOT AWS_BINARY)


# -- Third-party dependencies: Find awk ----------------------------------------
# TODO: Replace this with cmake regex

find_program(
  AWK_BINARY awk
  PATHS /usr/local/bin /usr/bin /bin /opt/local/bin
  DOC "Path to awk."
)

if(NOT AWK_BINARY)
  message(FATAL_ERROR "Cannot find awk.")
endif(NOT AWK_BINARY)


# -- Local definitions------------------ --------------------------------------

set(AWS_ACCESS_KEY_ID "$ENV{AWS_ACCESS_KEY_ID}" CACHE STRING "AWS_ACCESS_KEY_ID")
set(AWS_SECRET_ACCESS_KEY "$ENV{AWS_SECRET_ACCESS_KEY}" CACHE STRING "AWS_SECRET_ACCESS_KEY")

# TODO: Make sure these are set
set(AWS_REGION "" CACHE STRING "AWS Region")
set(AWS_CF_STACK_NAME "" CACHE STRING "AWS Cloudformation Stack name")

# Get Redshift hostname from Cloudformation stack output
execute_process(
  COMMAND ${AWS_BINARY} --region ${AWS_REGION} cloudformation describe-stacks --stack-name ${AWS_CF_STACK_NAME}
  COMMAND ${AWK_BINARY} -F\\\" "/\\\"OutputKey\\\": \\\"ClusterHost\\\",/{getline; print $4}"
  OUTPUT_VARIABLE PGHOST
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Get number of EC2 worker nodes
execute_process(
  COMMAND ${AWS_BINARY} --region ${AWS_REGION} ec2 describe-instances --filters Name=tag:Name,Values=${AWS_CF_STACK_NAME}-WorkerAutoScalingGroup
  COMMAND ${AWK_BINARY} -F\\\" "/\\\"PrivateIpAddress\\\":/{print $4}"
  OUTPUT_VARIABLE WORKER_HOSTS
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
if(WORKER_HOSTS)
  string(REGEX REPLACE "\n" ";" WORKER_HOSTS ${WORKER_HOSTS})
  list(REMOVE_DUPLICATES "WORKER_HOSTS")
  list(LENGTH "WORKER_HOSTS" WORKER_COUNT)
else(WORKER_HOSTS)
  set(WORKER_COUNT 0)
endif(WORKER_HOSTS)

# Get number of EC2 worker cores from Cloudformation stack output
execute_process(
  COMMAND ${AWS_BINARY} --region ${AWS_REGION} cloudformation describe-stacks --stack-name ${AWS_CF_STACK_NAME}
  COMMAND ${AWK_BINARY} -F\\\" "/\\\"OutputKey\\\": \\\"vCPUPerWorker\\\",/{getline; print $4}"
  OUTPUT_VARIABLE CORES_PER_WORKER
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Calculate total number of EC2 worker cores
math(EXPR TOTAL_CORES "${WORKER_COUNT}*${CORES_PER_WORKER}")

# Get worker IAM role ARN
execute_process(
  COMMAND ${AWS_BINARY} --region ${AWS_REGION} cloudformation describe-stacks --stack-name ${AWS_CF_STACK_NAME}
  COMMAND ${AWK_BINARY} -F\\\" "/\\\"WorkerIAMRoleARN\\\"/{getline; print $4}"
  OUTPUT_VARIABLE WORKER_IAM_ROLE
  OUTPUT_STRIP_TRAILING_WHITESPACE
)


# -- Build and install all SF files -------------------------------------------

foreach(SCALE_FACTOR ${SCALE_FACTORS})

  if(${SCALE_FACTOR} GREATER 300)
    set(ORDER_KEY_DATA_TYPE "bigint")
  else(${SCALE_FACTOR} GREATER 300)
    set(ORDER_KEY_DATA_TYPE "integer")
  endif(${SCALE_FACTOR} GREATER 300)

  define_m4_defines(M4_DEFINES_CMD_LINE)

  # Add each file type separately for now. We may want to build them
  # separately.

  # SQL files
  add_m4_files(
    CLIENT_SQL_TARGET_FILES
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_BINARY_DIR}/${AWS_CF_STACK_NAME}/SF_${SCALE_FACTOR}"
    "sql"
    ${M4_DEFINES_CMD_LINE}
  )
  add_custom_target(clientSQLFilesSF${SCALE_FACTOR} ALL DEPENDS ${CLIENT_SQL_TARGET_FILES})
  install(
    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    DESTINATION ${CMAKE_INSTALL_PREFIX}
    FILES_MATCHING PATTERN "*.sql"
    PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
    PATTERN "CMakeFiles" EXCLUDE
    PATTERN "*.cmake" EXCLUDE
    PATTERN "Makefile" EXCLUDE
  )

  # Shell files
  add_m4_files(
    CLIENT_SHELL_TARGET_FILES
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_BINARY_DIR}/${AWS_CF_STACK_NAME}/SF_${SCALE_FACTOR}"
    "sh"
    ${M4_DEFINES_CMD_LINE}
  )
  add_custom_target(clientShellFilesSF${SCALE_FACTOR} ALL DEPENDS ${CLIENT_SHELL_TARGET_FILES})
  install(
    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    DESTINATION ${CMAKE_INSTALL_PREFIX}
    FILES_MATCHING PATTERN "*.sh"
    PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
                OWNER_EXECUTE GROUP_EXECUTE WORLD_EXECUTE
    PATTERN "CMakeFiles" EXCLUDE
    PATTERN "*.cmake" EXCLUDE
    PATTERN "Makefile" EXCLUDE
  )

  # Markdown files
  add_m4_files(
    CLIENT_MARKDOWN_TARGET_FILES
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_BINARY_DIR}/${AWS_CF_STACK_NAME}/SF_${SCALE_FACTOR}"
    "md"
    ${M4_DEFINES_CMD_LINE}
  )
  add_custom_target(clientMarkdownFilesSF${SCALE_FACTOR} ALL DEPENDS ${CLIENT_MARKDOWN_TARGET_FILES})
  install(
    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    DESTINATION ${CMAKE_INSTALL_PREFIX}
    FILES_MATCHING PATTERN "*.md"
    PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
    PATTERN "CMakeFiles" EXCLUDE
    PATTERN "*.cmake" EXCLUDE
    PATTERN "Makefile" EXCLUDE
  )

  # COPY manifest files
  add_m4_files(
    CLIENT_COPY_MANIFEST_TARGET_FILES
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_BINARY_DIR}/${AWS_CF_STACK_NAME}/SF_${SCALE_FACTOR}"
    "manifest"
    ${M4_DEFINES_CMD_LINE}
  )
  add_custom_target(
    clientCopyManifestFilesSF${SCALE_FACTOR}
    ALL
    DEPENDS ${CLIENT_COPY_MANIFEST_TARGET_FILES}
  )
  add_custom_command(
    TARGET clientCopyManifestFilesSF${SCALE_FACTOR}
    POST_BUILD
    COMMAND ${AWS_BINARY} s3 sync "${CMAKE_CURRENT_BINARY_DIR}/${AWS_CF_STACK_NAME}/SF_${SCALE_FACTOR}/load-data/manifests" "s3://${AWS_CF_STACK_NAME}/${BUILD_TIME}/${SCALE_FACTOR}" --include "*.manifest" --delete
  )
  install(
    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    DESTINATION ${CMAKE_INSTALL_PREFIX}
    FILES_MATCHING PATTERN "*.manifest"
    PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
    PATTERN "CMakeFiles" EXCLUDE
    PATTERN "*.cmake" EXCLUDE
    PATTERN "Makefile" EXCLUDE
  )

endforeach(SCALE_FACTOR)
