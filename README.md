# pybind11-cuda

Starting point for GPU accelerated python libraries

Adapted from original work from https://github.com/PWhiddy/pybind11-cuda

Present work uses [modern CMake/Cuda](https://developer.download.nvidia.com/video/gputechconf/gtc/2019/presentation/s9444-build-systems-exploring-modern-cmake-cuda-v2.pdf) approach

# Prerequisites

Cuda

Python 3.6 or greater

Cmake >= 3.12 (for CUDA support and the new FindPython3 module)

# To build

```bash
mkdir build; cd build
# provide a default cuda hardware architecture to build for
export CUDAFLAGS="-arch=sm_50"
cmake ..
make
```

If you use cmake version >= 3.18, you can use [variable CMAKE_CUDA_ARCHITECTURES](https://cmake.org/cmake/help/latest/variable/CMAKE_CUDA_ARCHITECTURES.html) instead of CUDAFLAGS:

```bash
mkdir build; cd build
# provide a default cuda hardware architecture to build for
cmake -DCMAKE_CUDA_ARCHITECTURES="75" ..
make
```

Test it with
```python3 test_mul.py```

_gpu_library.so_ and _test_mul.py_ must be in the same folder. Alternatively you can path to _gpu_library.so_ to your PYTHONPATH env variable.

# Features demonstrated

- Compiles out of the box with cmake
- Numpy integration
- C++ Templating for composable kernels with generic data types

Originally based on https://github.com/torstem/demo-cuda-pybind11
