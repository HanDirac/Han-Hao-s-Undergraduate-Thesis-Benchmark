using JuliVQC 
using Zygote
using QuantumCircuits

log_path = "grad_desc_log_notmy.txt"
io = open(log_path, "w")   # "w" 覆盖写；想追加用 "a"

# 小工具：同时打印到屏幕和文件
function logprintln(io::IO, args...)
    println(args...)           # stdout
    println(io, args...)       # file
    flush(io)                  # 立刻写入磁盘（更安全，但略慢）
end

try

# -----------------------------
# Problem setup
# -----------------------------
L      = 3                    # number of qubits
depth  = 2                    # circuit depth
ψ0     = StateVector(L)       # initial state |000⟩

# Simple 1D Heisenberg Hamiltonian as QubitsOperator:
#   H = ∑_i hz * Z_i + ∑_i J * (X_i X_{i+1} + Y_i Y_{i+1} + Z_i Z_{i+1})
function heisenberg_1d(L; hz = 1.0, J = 1.0)
    terms = Vector{QubitsTerm}()

    # Local Z fields
    for i in 1:L
        push!(terms, QubitsTerm(i => "Z"; coeff = hz))
    end

    # Nearest-neighbor interactions: X X + Y Y + Z Z
    for i in 1:L-1
        push!(terms, QubitsTerm(i => "X", i+1 => "X"; coeff = J))
        push!(terms, QubitsTerm(i => "Y", i+1 => "Y"; coeff = J))
        push!(terms, QubitsTerm(i => "Z", i+1 => "Z"; coeff = J))
    end

    return QubitsOperator(terms...)
end

H = heisenberg_1d(L)     # user-defined Hamiltonian as QubitsOperator

# -----------------------------
# Build a variational circuit
# -----------------------------
circuit = QCircuit()

# First layer: local rotations
for i in 1:L
    push!(circuit, RzGate(i, pi/7; isparas = true))
    push!(circuit, RyGate(i, pi/5; isparas = true))
    push!(circuit, RzGate(i, pi/3; isparas = true))
end

# Repeated entangling + rotations
for l in 1:depth
    # entangling chain
    for i in 1:L-1
        push!(circuit, CNOTGate(i, i+1))
    end
    # another layer of local rotations
    for i in 1:L
        push!(circuit, RzGate(i, pi/7; isparas = true))
        push!(circuit, RxGate(i, pi/5; isparas = true))
        push!(circuit, RzGate(i, pi/3; isparas = true))
    end
end

# -----------------------------
# Wrap loss as expectation value
# -----------------------------
loss(circuit) = real(expectation(H, circuit*ψ0))

# Extract initial parameter vector
θ = active_parameters(circuit)

# -----------------------------
# Simple gradient-descent loop
# -----------------------------
η      = 0.01    # learning rate
epochs = 10000      # number of gradient steps

logprintln(io, "Start training: L=$L, depth=$depth, η=$η, epochs=$epochs")
    logprintln(io, "Log file: $(abspath(log_path))")

for epoch in 1:epochs
    # gradient of loss w.r.t. all active parameters in `circuit`
    gθ = gradient(loss, circuit)[1]

    # gradient-descent update (in-place on θ)
    θ .-= η .* gθ

    # write updated parameters back into the circuit
    reset_parameters!(circuit, θ)

    # monitor current loss
    current_loss = loss(circuit)
    logprintln(io, "Epoch $epoch: loss = $current_loss")
end

logprintln(io, "Finished training.")

finally
    close(io)  # 确保即使中途报错也会关闭文件并落盘
end