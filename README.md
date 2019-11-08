# pybind11-cuda

Starting point for GPU accelerated python libraries 

Adapted from original work from https://github.com/PWhiddy/pybind11-cuda
Present work uses [modern CMake/Cuda](https://developer.download.nvidia.com/video/gputechconf/gtc/2019/presentation/s9444-build-systems-exploring-modern-cmake-cuda-v2.pdf) approach

# Prerequisites

Cuda

Python 3.6 or greater 

Cmake >= 3.12 for the new FindPython3 module

# To build 

```bash
mkdir build; cd build
# provide a default cuda hardware architecture to build for
export CUDAFLAGS="-arch=sm_50"
cmake ..
make
``` 

Test it with 
```python3 test_mul.py``` 
 
# Features demonstrated 

Compiles out of the box with cmake 

Numpy integration 

C++ Templating for composable kernels with generic data types 

Originally based on https://github.com/torstem/demo-cuda-pybind11
