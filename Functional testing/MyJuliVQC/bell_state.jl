using MyJuliVQC

# Create a 2-qubit state |00⟩
ψ = StateVector(2)

# Build a quantum circuit
circuit = QCircuit()
push!(circuit, HGate(1))          # Hadamard on qubit 1
push!(circuit, CNOTGate(1, 2))    # Controlled-NOT from qubit 1 to 2

# Apply the circuit to the state
apply!(circuit, ψ)

# Inspect the resulting state
println("Final state vector:")
println(ψ)

# Repeat measurement times on a copy of the pre-measurement state
nshots = 1000000
counts = Dict{Int, Int}(0 => 0, 1 => 0)

for _ in 1:nshots
    psi_copy = deepcopy(ψ)  # copy state before measurement
    outcome, prob = measure!(psi_copy, 1)
    counts[outcome] = get(counts, outcome, 0) + 1
end

# Print counts and frequencies
println("\nMeasurement statistics for qubit 1 over $nshots shots:")
for outcome in sort(collect(keys(counts)))
    c = counts[outcome]
    freq = c / nshots
    println("Outcome $outcome: count = $c, frequency = $freq")
end