# ==============================================
# the following code is directly borrowed from
# https://github.com/svenevs/cmake-cuda-targets
# ==============================================

# TODO: make this an actual find module...allow VERSION, QUIET, etc

# TODO: don't use find_package(CUDA)?  But the thread specifically states that
#       we should *NOT* require that enable_language(CUDA) has been done,
#       meaning that e.g. CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES may not exist?
#
#       Solution?
#       include(CheckLanguage)
#       check_language(CUDA)
#       if (NOT CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES)
#       --> then we cannot win?
find_package(CUDA REQUIRED)

# Populate the list of default locations to search for the CUDA libraries.
# TODO: allow user bypass of this?
list(APPEND CUDALibs_HINTS "${CUDA_TOOLKIT_ROOT_DIR}/lib64")
list(APPEND CUDALibs_HINTS "${CUDA_TOOLKIT_ROOT_DIR}/lib")
list(APPEND CUDALibs_HINTS "${CUDA_TOOLKIT_ROOT_DIR}")

function(find_and_add_cuda_import_lib lib_name)
  string(TOUPPER ${lib_name} LIB_NAME)
  find_library(CUDA_${LIB_NAME} ${lib_name} HINTS ${CUDALibs_HINTS})
  if (NOT CUDA_${LIB_NAME} STREQUAL CUDA_${LIB_NAME}-NOTFOUND)
    add_library(CUDA::${lib_name} IMPORTED INTERFACE)
    set_target_properties(CUDA::${lib_name}
      PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES
          "${CUDA_INCLUDE_DIRS}"
        INTERFACE_LINK_LIBRARIES
          "${CUDA_${LIB_NAME}}"
    )
  endif()
endfunction()

# TODO: how to make sure `dependency` can actually be used
# TODO: if dependency cannot be used, is it possible to
#       delete CUDA::${lib_name}?
function(add_cuda_link_dependency lib_name dependency)
  set_property(
    TARGET CUDA::${lib_name}
    APPEND
    PROPERTY
      INTERFACE_LINK_LIBRARIES ${dependency}
  )
endfunction()

# Find the main CUDA runtime dynamic and static libraries.
# These are a hard dependency for all other libraries, and
# must be found.
# TODO: right way to error out?
find_and_add_cuda_import_lib(cudart)
find_and_add_cuda_import_lib(cudart_static)

# TODO: what about windows???
if (UNIX)
  foreach (lib dl pthread rt)
    add_cuda_link_dependency(cudart_static ${lib})
  endforeach()
endif()

# TODO: nvBLAS and example.  Depends on cuBLAS, but not sure how it works.
#       Testing executable may need to find_package(BLAS)?  It seems like the idea is
#       you write a standard BLAS level 3 operation, and at link time nvBLAS will take
#       over somehow?
# cuBLAS treated specially, static library needs to link against a BLAS
# library for *gemm_ symbols.  So both dynamic and static library are only added
# if BLAS can be found for consistency (missing dynamic case will be a library
# load error at runtime).
# Find dynamic blas for cusolver dynamic target
set(BLA_STATIC OFF)
find_package(BLAS)
if (BLAS_FOUND)
  find_and_add_cuda_import_lib(cublas)
  add_cuda_link_dependency(cublas CUDA::cudart)
  add_cuda_link_dependency(cublas ${BLAS_LIBRARIES})
endif()

# Find static blas for cublas static target
set(BLAS_FOUND OFF)
set(BLA_STATIC ON)
find_package(BLAS)
if (BLAS_FOUND)
  find_and_add_cuda_import_lib(cublas_static)
  add_cuda_link_dependency(cublas_static CUDA::cudart_static)
  add_cuda_link_dependency(cublas_static ${BLAS_LIBRARIES})
endif()

# TODO: (nppi* nvblas)
foreach (cuda_lib cufft cufftw curand cusolver cusparse nvgraph nvjpeg)
  # find the dynamic library
  find_and_add_cuda_import_lib(${cuda_lib})
  add_cuda_link_dependency(${cuda_lib} CUDA::cudart)

  # TODO: if UNIX and VERSION >= 6.5
  # find the static library
  find_and_add_cuda_import_lib(${cuda_lib}_static)
  add_cuda_link_dependency(${cuda_lib}_static CUDA::cudart_static)
endforeach()



# NVRTC (Runtime Compilation) is a shared library only.
# TODO: nvrtc needs -lcuda (*NOT* cudart), but -lcuda (at least on this system)
#       is going to point to /lib64/libcuda.so.
#
#       Since this is not in the HINTS paths searched above, what is the right
#       way to create the CUDA::cuda target?
find_and_add_cuda_import_lib(nvrtc)
add_cuda_link_dependency(nvrtc cuda)

# NVTX is a shared library only.
# TODO: is this even useful outside of NSight Eclipse?
find_and_add_cuda_import_lib(nvToolsExt)
add_cuda_link_dependency(nvToolsExt CUDA::cudart)

# cuLIBOS is a static only library, see
#
# https://devblogs.nvidia.com/10-ways-cuda-6-5-improves-performance-productivity
#
# > Static CUDA Libraries
# > CUDA 6.5 (on Linux and Mac OS) now includes static library versions of the
# > cuBLAS, cuSPARSE, cuFFT, cuRAND, and NPP libraries. This can reduce the
# > number of dynamic library dependencies you need to include with your
# > deployed applications. These new static libraries depend on a common thread
# > abstraction layer library cuLIBOS (libculibos.a) distributed as part of the
# > CUDA toolkit.
find_and_add_cuda_import_lib(culibos)
# foreach (cuda_lib cublas cusparse cufft) # curand npp
foreach (cuda_lib cublas cufft cusparse curand nvjpeg)# npp
  add_cuda_link_dependency(${cuda_lib}_static CUDA::culibos)
endforeach()

# cuSOLVER depends on cuBLAS and cuSPARSE
# NOTE: nvGRAPH relies on this, make sure it happens before nvGRAPH dependencies.
foreach (dep cublas cusparse)
  add_cuda_link_dependency(cusolver CUDA::${dep})
  add_cuda_link_dependency(cusolver_static CUDA::${dep}_static)
endforeach()

# nvGRAPH depends on cuBLAS, cuRAND, cuSPARSE, and cuSOLVER.
# NOTE: rely on link dependencies of cuSOLVER, this must happen after cusolver target.
foreach (dep cusolver curand)
  add_cuda_link_dependency(nvgraph CUDA::${dep})
  add_cuda_link_dependency(nvgraph_static CUDA::${dep}_static)
endforeach()

# NPP libraries and dependencies.  See: https://docs.nvidia.com/cuda/npp/index.html
# TODO: document what nppc is (seems to be the underlying implementation for most of NPP?)
find_and_add_cuda_import_lib(nppc)
find_and_add_cuda_import_lib(nppc_static)

# Process the majority of the NPP libraries.
foreach (cuda_lib nppial nppicc nppidei nppif nppig nppim nppist nppitc npps)
  # Find the libraries.
  find_and_add_cuda_import_lib(${cuda_lib})
  find_and_add_cuda_import_lib(${cuda_lib}_static)

  # Designate dynamic link dependencies.
  add_cuda_link_dependency(${cuda_lib} CUDA::cudart)
  # TODO: add this in since it is needed in static or rely on existing dynamic links?
  # add_cuda_link_dependency(${cuda_lib} CUDA::nppc)

  # Designate static link dependencies.
  add_cuda_link_dependency(${cuda_lib}_static CUDA::cudart_static)
  add_cuda_link_dependency(${cuda_lib}_static CUDA::nppc_static)
  add_cuda_link_dependency(${cuda_lib}_static CUDA::culibos)
endforeach()

# nppicom: JPEG compression and decompression functions in nppi_compression_functions.h
find_and_add_cuda_import_lib(nppicom)
find_and_add_cuda_import_lib(nppicom_static)

# nppisu: memory support functions in nppi_support_functions.h
find_and_add_cuda_import_lib(nppisu)
find_and_add_cuda_import_lib(nppisu_static)
add_cuda_link_dependency(nppisu CUDA::cudart)
add_cuda_link_dependency(nppisu_static CUDA::cudart_static)

# TODO: mysterious extra static libraries...what are they for?
find_and_add_cuda_import_lib(cudadevrt)
find_and_add_cuda_import_lib(cublas_device)

# TODO: VERSION 9.2, search libcufft_static_nocallback.a
#       https://docs.nvidia.com/cuda/cufft/index.html#oned-complex-to-complex-transforms

# Do not expose these functions externally.
unset(find_and_add_cuda_import_lib)
unset(add_cuda_link_dependency)
