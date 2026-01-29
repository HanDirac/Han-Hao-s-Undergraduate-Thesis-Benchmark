本测试在 Yang Group HPC of HFNL 的CPU计算节点上进行。Yang Group HPC of HFNL 的CPU计算节点，各节点128核，503 GB 内存； CPU型号为AMD EPYC 7763 64-Core Processor，主频1500 MHz，计算频率2450 MHz。该服务器的操作系统为CentOS Linux release 7.9.2009。

以下列出我在服务器上的具体操作：

初始化：
本测试需要julia 1.10及以上的版本。若不具备则需要先安装。
接着，在该Performance testing文件夹中执行以下指令：

```
julia
```
```julia
using Pkg
Pkg.generate("JuliVQC_env")
Pkg.activate("JuliVQC_env")
```
接下来按“]”进入Pkg, 然后执行以下指令：
```julia
add https://github.com/weiyouLiao/QuantumCircuits.jl
add https://github.com/weiyouLiao/JuliVQC.jl
add https://github.com/guochu/QuantumSpins
add https://github.com/guochu/MPSSimulator
```
接下来按后退键推出Pkg，然后执行以下指令：
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
接下来按“]”进入Pkg, 然后执行以下指令：
```julia
add https://github.com/HanDirac/MyJuliVQC.jl
```
接下来按后退键推出Pkg，然后执行以下指令：
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

JuliVQC/MyJuliVQC里的脚本得用JuliVQC_env/MyJuliVQC_env运行。

(最后别望了排版)