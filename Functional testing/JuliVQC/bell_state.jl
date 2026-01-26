using JuliVQC
using QuantumCircuits

# Create a 2-qubit quantum state
state = StateVector(2)

# Define a quantum circuit
circuit = QCircuit()
push!(circuit, HGate(1))         # Add a Hadamard gate on qubit 1
push!(circuit, CNOTGate(1, 2))   # Add a CNOT gate between qubits 1 and 2

# Apply the circuit to the quantum state
apply!(circuit, state)

# Repeat measurement on a copy of the pre-measurement state
nshots = 1000000
counts = Dict{Int, Int}(0 => 0, 1 => 0)

for _ in 1:nshots
    psi_copy = deepcopy(state)  # copy state before measurement
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