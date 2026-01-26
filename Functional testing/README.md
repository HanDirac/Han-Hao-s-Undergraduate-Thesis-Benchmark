## Environment Requirements

Scripts in both the `JuliVQC` and `MyJuliVQC` directories require **Julia version 1.10 or later**.

To avoid potential conflicts caused by functions with identical names in different Julia packages, the scripts in these two directories **must be run in separate Julia environments**:

- When running scripts in the `JuliVQC` directory, you should first create a Julia virtual environment and install **only** the `JuliVQC` package in that environment, then execute the scripts within it.
- When running scripts in the `MyJuliVQC` directory, you should first create a Julia virtual environment and install **only** the `MyJuliVQC` package in that environment, then execute the scripts within it.

The installation instructions for these two packages can be found at:

- JuliVQC: https://github.com/weiyouLiao/JuliVQC.jl  
- MyJuliVQC: https://github.com/HanDirac/MyJuliVQC.jl
