add_library(gpu_library SHARED
  gpu_library.cu)

#target_include_directories(gpu_library PUBLIC ${Python3_INCLUDE_DIRS})
target_include_directories(gpu_library PUBLIC ${CMAKE_SOURCE_DIR}/pybind11/include)
target_link_libraries(gpu_library PUBLIC
  #${PYTHON3_PYTHON}
  Python3::Python
  cudart)

# set what comes before the library name, here no "lib"
set_target_properties(gpu_library PROPERTIES PREFIX "")
