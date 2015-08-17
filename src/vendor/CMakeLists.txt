include(ExternalProject)

ExternalProject_Add(ssb-dbgen
  GIT_REPOSITORY https://github.com/ajw0100/ssb-dbgen.git
  UPDATE_COMMAND /usr/bin/env echo Ignored: update
  PATCH_COMMAND /usr/bin/env echo Ignored: patch
  CONFIGURE_COMMAND /usr/bin/env echo Ignored: configure
  BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/ssb-dbgen-prefix/src/ssb-dbgen
  BUILD_COMMAND make
  INSTALL_COMMAND /usr/bin/env echo Ignored: install
)

# TODO: consolidate these 3 commands into 1 w/ a regex
install(
  DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/ssb-dbgen-prefix/src/ssb-dbgen
  DESTINATION ${CMAKE_INSTALL_PREFIX}/vendor
  FILES_MATCHING PATTERN "dbgen"
  PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
              OWNER_EXECUTE GROUP_EXECUTE WORLD_EXECUTE
  PATTERN "CMakeFiles" EXCLUDE
  PATTERN "*.cmake" EXCLUDE
  PATTERN "Makefile" EXCLUDE
)

install(
  DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/ssb-dbgen-prefix/src/ssb-dbgen
  DESTINATION ${CMAKE_INSTALL_PREFIX}/vendor
  FILES_MATCHING PATTERN "*.sh"
  PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
              OWNER_EXECUTE GROUP_EXECUTE WORLD_EXECUTE
  PATTERN "CMakeFiles" EXCLUDE
  PATTERN "*.cmake" EXCLUDE
  PATTERN "Makefile" EXCLUDE
)

install(
  DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/ssb-dbgen-prefix/src/ssb-dbgen
  DESTINATION ${CMAKE_INSTALL_PREFIX}/vendor
  PATTERN "CMakeFiles" EXCLUDE
  PATTERN "*.cmake" EXCLUDE
  PATTERN "Makefile" EXCLUDE
  PATTERN "dbgen" EXCLUDE
  PATTERN "*.sh" EXCLUDE
)
