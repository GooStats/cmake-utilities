##/*****************************************************************************/
##// Author: Xuefeng Ding <xuefeng.ding.physics@gmail.com>
##// Insitute: Princeton University, Princeton, NJ 08542, USA
##// Date: 2021 March 28th
##// Version: v1.0
##// Description: cmake-utilities
##//
##// All rights reserved. 2021 copyrighted.
##/*****************************************************************************/
macro(INITIALIZE_CUDA)
  set(CMAKE_CXX_STANDARD 14)
  set(CMAKE_CXX_EXTENSIONS OFF)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_POSITION_INDEPENDENT_CODE ON)

  set(DEVICE_LISTING CUDA OMP CPP TBB Auto)
  set(HOST_LISTING OMP CPP TBB Auto)
  mark_as_advanced(DEVICE_LISTING HOST_LISTING)
  set(DEVICE Auto CACHE STRING "The compute device, options are ${DEVICE_LISTING}")
  set(HOST Auto CACHE STRING "The compute device, options are ${HOST_LISTING}")
  if(NOT ${DEVICE} IN_LIST DEVICE_LISTING)
    message(FATAL_ERROR "You must select a device from ${DEVICE_LISTING}, not ${DEVICE}")
  endif()
  if(NOT ${HOST} IN_LIST HOST_LISTING)
    message(FATAL_ERROR "You must select a host from ${HOST_LISTING}, not ${HOST}")
  endif()

  if(DEVICE STREQUAL Auto)
    find_package(CUDA 6.0)
    if(CUDA_FOUND)
      set(DEVICE CUDA CACHE STRING "The compute device, options are ${DEVICE_LISTING}" FORCE)
    else()
      find_package(OpenMP)
      if(OpenMP_CXX_FOUND OR OpenMP_FOUND)
        set(DEVICE OMP CACHE STRING "The compute device, options are ${DEVICE_LISTING}" FORCE)
      else()
        set(DEVICE CPP CACHE STRING "The compute device, options are ${DEVICE_LISTING}" FORCE)
      endif()
    endif()
    message(STATUS "Auto device selection: ${DEVICE}")
  endif()

  if(HOST STREQUAL Auto)
    if(DEVICE STREQUAL OMP)
      set(HOST OMP CACHE STRING "The host device, options are ${HOST_LISTING}" FORCE)
    elseif(DEVICE STREQUAL TBB)
      set(HOST TBB CACHE STRING "The host device, options are ${HOST_LISTING}" FORCE)
    else()
      set(HOST CPP CACHE STRING "The host device, options are ${HOST_LISTING}" FORCE)
    endif()
    message(STATUS "Auto host selection: ${HOST}")
  endif()

  set(THRUST_REQUIRED_SYSTEMS ${HOST} ${DEVICE})

  thrust_create_target(MyThrust HOST ${HOST} DEVICE ${DEVICE})
  target_compile_features(MyThrust INTERFACE cxx_std_14)

  set(CUDA_ARCH 60 CACHE STRING "The GPU Archetecture, can be 60 70 etc.")
  if(DEVICE STREQUAL CUDA)
    enable_language(CUDA)
    set(CMAKE_CUDA_STANDARD 14)
    set(CMAKE_CUDA_SEPARABLE_COMPILATION ON) # effective when created
    set(CMAKE_CUDA_ARCHITECTURES ${CUDA_ARCH}) # effective when created
  endif()
endmacro()

function(goofit_add_library GNAME)
  add_library(${GNAME} STATIC ${ARGN})
  if(NOT DEVICE STREQUAL CUDA)
    SET_SOURCE_FILES_PROPERTIES(${ARGN} PROPERTIES LANGUAGE CXX)
    target_compile_options(${GNAME} PUBLIC -x c++)
  endif()
endfunction()
