cmake_minimum_required(VERSION 3.5)
project(striprouter)

set(CMAKE_CXX11_EXTENSION_COMPILE_OPTION -std=gnu++17)
list(APPEND CMAKE_C_FLAGS -w)
list(APPEND CMAKE_CXX_FLAGS -w)

cmake_policy(SET "CMP0015" "NEW")

#set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(SOURCE_DIR ${CMAKE_SOURCE_DIR}/src)

if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(LIBRARIES ${CMAKE_SOURCE_DIR}/libraries/linux)
else ()
  set(LIBRARIES ${CMAKE_SOURCE_DIR}/libraries/win64)
endif ()

set(HEADER_LIBRARIES ${CMAKE_SOURCE_DIR}/libraries/header_only)


# GLFW
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(GLFW_LIBRARIES glfw)
else ()
  set(GLFW_LIBRARIES glfw3.lib)
  set(GLFW_INCLUDE_DIRS ${LIBRARIES}/include)
  set(GLFW_LINK_DIRS ${LIBRARIES}/lib)
endif ()

# fmt
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(FMT_LIBRARIES fmt)
  # set(FMT_LIBRARIES ${CMAKE_BINARY_DIR}/libraries/linux/fmt-3.0.1/libfmtd.a)
  set(FMT_INCLUDE_DIR ${LIBRARIES}/fmt-3.0.1)
  set(FMT_LINK_DIR ${LIBRARIES}/fmt-3.0.1/fmt)
  set(BUILD_SHARED_LIBS OFF)
  add_definitions(-fPIC)
  add_subdirectory(${LIBRARIES}/fmt-3.0.1)
else ()
  set(FMT_LIBRARIES fmt.lib)
  set(FMT_INCLUDE_DIR ${LIBRARIES}/include)
  set(FMT_LINK_DIR ${LIBRARIES}/lib/Release)
  #set(FMT_LINK_DIR ${LIBRARIES}/fmt-3.0.1/builds/fmt/Debug)
endif ()

# FreeType2
#CPPFLAGS += $(shell freetype-config --cflags)
#LDFLAGS += $(shell freetype-config --libs)
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  find_package(Freetype REQUIRED)
  set(FREETYPE_LINK_DIRS "")
else ()
  set(FREETYPE_LIBRARIES freetype.lib)
  set(FREETYPE_INCLUDE_DIRS ${LIBRARIES}/include)
  set(FREETYPE_LINK_DIRS ${LIBRARIES}/lib/Release)
endif ()

# glm
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
else ()
  set(GLM_INCLUDE_DIR ${LIBRARIES}/include)
endif ()

# GLEW
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(GLEW_LIBRARIES GLEW)
else ()
  set(GLEW_LIBRARIES glew32.lib)
  set(GLEW_INCLUDE_DIRS ${LIBRARIES}/include)
  set(GLEW_LINK_DIR ${LIBRARIES}/lib/Release)
endif ()

# OpenGL and GLU
find_package(OpenGL REQUIRED)

# X
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(X_LIBRARIES Xrandr X11 Xxf86vm Xinerama Xcursor Xi)
else ()
  set(X_LIBRARIES "")
endif ()

# GCC
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(GCC_LIBRARIES m pthread dl)
else ()
  set(GCC_LIBRARIES "")
endif ()

if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")
  # Handling of compiler warnings
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wfatal-errors -Wno-deprecated-declarations")
  # Add relative ./lib to dynamic linker search path
  #set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wl,--enable-new-dtags,--rpath=${ORIGIN}./lib")
endif ()

# NanoGUI
set(NANO_INCLUDE_DIR
  ${LIBRARIES}/nanogui/include
#  ${LIBRARIES}/nanogui/ext/eigen
#  ${LIBRARIES}/nanogui/ext/nanovg/src
)
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(NANO_LIBRARIES nanogui)
  set(NANO_LINK_DIR ${LIBRARIES}/nanogui/build)
else ()
  set(NANO_LIBRARIES nanogui.lib)
  set(NANO_LINK_DIR ${LIBRARIES}/lib/Release)
  #set(NANO_LINK_DIR ${LIBRARIES}/nanogui/build/Debug)
endif ()


add_subdirectory(${CMAKE_SOURCE_DIR}/libraries/linux/nanogui)

# Eigen
#find_package(Eigen3 REQUIRED)

# libpng
# png++
# Header-only library that depends on libpng.
# Linux: Installing libpng++-dev with apt-get pulls in libpng.
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  find_package(PNG REQUIRED)
else ()
  set(PNG_INCLUDE_DIRS
	${HEADER_LIBRARIES}/pngpp
#	${LIBRARIES}/libpng-1.6.26
  )
endif ()

# simple_svg
set(SIMPLE_SVG_INCLUDE_DIR ${HEADER_LIBRARIES}/simple_svg)

# CmdParser
set(CMD_PARSER_INCLUDE_DIR ${HEADER_LIBRARIES}/cmdparser)

set(SOURCE_FILES
  ${SOURCE_DIR}/circuit.cpp
  ${SOURCE_DIR}/circuit_parser.cpp
  ${SOURCE_DIR}/circuit_writer.cpp
  ${SOURCE_DIR}/ga_interface.cpp
  ${SOURCE_DIR}/ga_core.cpp
  ${SOURCE_DIR}/gl_error.cpp
  ${SOURCE_DIR}/gui.cpp
  ${SOURCE_DIR}/gui_status.cpp
  ${SOURCE_DIR}/icon.cpp
  ${SOURCE_DIR}/layout.cpp
  ${SOURCE_DIR}/main.cpp
  ${SOURCE_DIR}/nets.cpp
  ${SOURCE_DIR}/ogl_text.cpp
  ${SOURCE_DIR}/render.cpp
  ${SOURCE_DIR}/router.cpp
  ${SOURCE_DIR}/settings.cpp
  ${SOURCE_DIR}/shader.cpp
  ${SOURCE_DIR}/status.cpp
  ${SOURCE_DIR}/thread_stop.cpp
  ${SOURCE_DIR}/ucs.cpp
  ${SOURCE_DIR}/utils.cpp
  ${SOURCE_DIR}/via.cpp
  ${SOURCE_DIR}/write_svg.cpp
)
  LIST(APPEND EIGEN3_INCLUDE_DIR ${CMAKE_INSTALL_PREFIX}/include/eigen3)
  LIST(APPEND EIGEN3_INCLUDE_DIR /usr/include/eigen3)

include_directories(
  ${HEADER_LIBRARIES}
  ${CMD_PARSER_INCLUDE_DIR}
  ${EIGEN3_INCLUDE_DIR}
  ${FMT_INCLUDE_DIR}
  ${FREETYPE_INCLUDE_DIRS}
  ${GLEW_INCLUDE_DIRS}
  ${GLFW_INCLUDE_DIRS}
  ${GLM_INCLUDE_DIR}
  ${NANO_INCLUDE_DIR}
  ${OPENGL_INCLUDE_DIR}
  ${PNG_INCLUDE_DIRS}
  ${SIMPLE_SVG_INCLUDE_DIR}
  ${CMAKE_SOURCE_DIR}/libraries/linux/nanogui/ext/nanovg/src
  ${CMAKE_SOURCE_DIR}/libraries/linux/nanovg/src
  ${CMAKE_SOURCE_DIR}/libraries/header_only/simple-svg
  ${CMAKE_SOURCE_DIR}/libraries/header_only/CmdParser
  ${CMAKE_SOURCE_DIR}/libraries/header_only/glm
  ${CMAKE_SOURCE_DIR}/libraries/header_only/glm/glm
)

link_directories(
  ${FMT_LINK_DIR}
  ${FREETYPE_LINK_DIRS}
  ${GLEW_LINK_DIR}
  ${GLFW_LINK_DIRS}
  ${NANO_LINK_DIR}
)

link_libraries(
  ${FMT_LIBRARIES}
  ${FREETYPE_LIBRARIES}
  ${GCC_LIBRARIES}
  ${GLEW_LIBRARIES}
  ${GLFW_LIBRARIES}
  ${NANO_LIBRARIES}
  ${OPENGL_LIBRARIES}
  ${PNG_LIBRARIES}
  ${X_LIBRARIES}
)

add_definitions(${PNG_DEFINITIONS} -DGLM_ENABLE_EXPERIMENTAL=1)

# Suppress GLM warning about having switched from degrees to radians as default
add_definitions(-DGLM_FORCE_RADIANS)

# Copy shaders to binary dir
# Apparently, this can't be done with glob or directory.
set(SHADER_SRC ${SOURCE_DIR}/shaders)
set(SHADER_DST ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/shaders)
file(MAKE_DIRECTORY ${SHADER_DST})
configure_file(${SHADER_SRC}/text_background.frag ${SHADER_DST} COPYONLY)
configure_file(${SHADER_SRC}/text_background.vert ${SHADER_DST} COPYONLY)
configure_file(${SHADER_SRC}/text.frag ${SHADER_DST} COPYONLY)
configure_file(${SHADER_SRC}/text.vert ${SHADER_DST} COPYONLY)
configure_file(${SHADER_SRC}/fill.frag ${SHADER_DST} COPYONLY)
configure_file(${SHADER_SRC}/fill.vert ${SHADER_DST} COPYONLY)

add_executable(striprouter ${SOURCE_FILES})

install(TARGETS striprouter DESTINATION bin)

install(DIRECTORY bin/benchmarks DESTINATION share/striprouter)
install(DIRECTORY bin/circuits DESTINATION share/striprouter)
install(DIRECTORY bin/fonts DESTINATION share/striprouter)
install(DIRECTORY bin/perf DESTINATION share/striprouter)
install(DIRECTORY bin/shaders DESTINATION share/striprouter)

