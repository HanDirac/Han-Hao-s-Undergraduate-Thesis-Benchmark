## Environment Requirements

#
Scripts in the **MyJuliVQC** folder require **Julia version 1.10 or later**.
The installation instructions for it can be found at:

- MyJuliVQC: https://github.com/HanDirac/MyJuliVQC.jl 


#
To run the scripts in the **PennyLane** folder, it is recommended to first create a **Python virtual environment using conda with Python 3.10**. After activating the environment, execute the following commands inside this virtual environment:
```
set PYTHONNOUSERSITE=1
pip install "numpy<2" pennylane
pip install matplotlib jupyter ipykernel
python -m ipykernel install --user --name pennylane_clean --display-name "Python (pennylane_clean)"
```
Then run the scripts inside this virtual environment.



