# rule110Cuda
A naive implementation of the [rule 110](https://en.wikipedia.org/wiki/Rule_110) in C with sdl2 and cuda

## compilation

you may need to change your target device in CMakeList.txt, see [this](https://en.wikipedia.org/wiki/CUDA#Supported_GPUs) page a change the number in arch and code corresponding to your device

compiling is as simple as :
```bash
mkdir build
cd build
cmake ..
make
```  
