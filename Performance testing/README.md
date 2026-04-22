This test was conducted on the CPU computing nodes of the Yang Group HPC at HFNL. Each CPU computing node has 128 cores and 503 GB of memory; the CPU model is AMD EPYC 7763 64-Core Processor, with a base frequency of 1500 MHz and a operating frequency of 2450 MHz. The server runs CentOS Linux release 7.9.2009.

The specific operations I performed on the server are listed below:

Initialization:
This test requires Julia 1.10 or higher. If not already installed, it must be installed first.
Then, in the *Performance testing* folder, execute the following commands:

```
julia
```
```julia
using Pkg
Pkg.generate("JuliVQC_env")
Pkg.activate("JuliVQC_env")
```
Next, press ] to enter the Pkg REPL mode, and execute the following commands:
```julia
add https://github.com/weiyouLiao/QuantumCircuits.jl
add https://github.com/weiyouLiao/JuliVQC.jl
add https://github.com/guochu/QuantumSpins
add https://github.com/guochu/MPSSimulator
```
Next, press the backspace key to exit the Pkg REPL mode, and then execute the following commands:
```julia
using JuliVQC # to verify installization
exit()
```
```
julia
```
```julia
using Pkg
Pkg.generate("MyJuliVQC_env")
Pkg.activate("MyJuliVQC_env")
```
Next, press the backspace key to exit the Pkg REPL mode, and then execute the following commands:
```julia
add https://github.com/HanDirac/MyJuliVQC.jl
```
Next, press the backspace key to exit the Pkg REPL mode, and then execute the following commands:
```julia
using MyJuliVQC # to verify installization
exit()
```
```
julia --project=JuliVQC_env
```
```julia
using Pkg
Pkg.add([
           "BenchmarkTools",
           "CSV",
           "DataFrames",
           "JSON",
           "KrylovKit",
           "PyCall",
           "Zygote"
       ])
exit()
```
```
julia --project=MyJuliVQC_env
```
```julia
using Pkg
Pkg.add([
           "BenchmarkTools",
           "CSV",
           "DataFrames",
           "JSON",
           "KrylovKit",
           "PyCall",
           "Zygote"
       ])
exit()
```

The scripts in *JuliVQC* and *MyJuliVQC* must be run using  `JuliVQC_env` and `MyJuliVQC_env`, respectively.
