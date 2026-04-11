cmake_minimum_required(VERSION 3.10.2)
project(buddybook_flutter)

# Force 16KB page size for all native code
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,max-page-size=16384")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-z,max-page-size=16384")

# Include Flutter plugins if defined
if(DEFINED FLUTTER_PLUGIN_TARGET)
    foreach(target ${FLUTTER_PLUGIN_TARGET})
        include(${target})
    endforeach()
endif()
