using JSON, Base.Threads
using BenchmarkTools
using QuantumCircuits, JuliVQC
import MPSSimulator.fuse_gates
using DataFrames
using CSV
mark = "JuliVQC"

const single_gate_nqubits = 10:30
const benchmarks = Dict()


function build_circuit_H(nqubits::Int)
	circuit = QCircuit()
	push!(circuit, HGate(1))
	return circuit
end

function build_circuit_RX(nqubits::Int)
	circuit = QCircuit()
	push!(circuit, RxGate(1,pi/4, isparas=false))
	return circuit
end


function build_circuit_CNOT(nqubits::Int)
	circuit = QCircuit()
	push!(circuit, CNOTGate((1, 2)))
	return circuit
end



macro task(name::String, nqubits_ex, body)
    nqubits = nqubits_ex.args[2]
    msg = "benchmarking $name"
    quote
        @info $msg
        benchmarks[$(name)] = Dict()
        benchmarks[$(name)]["nqubits"] = $(esc(nqubits))
        benchmarks[$(name)]["meantimes"] = []
        benchmarks[$(name)]["stdtimes"] = []
        benchmarks[$(name)]["minimumtimes"] = []
        benchmarks[$(name)]["maximumtimes"] = []
        for result in $(esc(body))
            push!(benchmarks[$(name)]["meantimes"],  result[1])
            push!(benchmarks[$(name)]["stdtimes"], result[2])
            push!(benchmarks[$(name)]["minimumtimes"], result[3])
            push!(benchmarks[$(name)]["maximumtimes"], result[4])
        end

    end
end


@task "H" nqubits=single_gate_nqubits begin
    map(single_gate_nqubits) do k
        t = @benchmark apply!($(build_circuit_H(k)), $(StateVector(ComplexF32, k)))
        data = (mean(t).time/1e9, std(t).time/1e9, minimum(t).time/1e9, maximum(t).time/1e9)

    end
end

@task "RX" nqubits=single_gate_nqubits begin
    map(single_gate_nqubits) do k
        t = @benchmark apply!($(build_circuit_RX(k)), $(StateVector(ComplexF32, k)))
        data = mean(t).time/1e9, std(t).time/1e9, minimum(t).time/1e9, maximum(t).time/1e9
    end
end

@task "CNOT" nqubits=single_gate_nqubits begin
    map(single_gate_nqubits) do k
        t = @benchmark apply!($(build_circuit_CNOT(k)), $(StateVector(ComplexF32, k)))
        data = mean(t).time/1e9, std(t).time/1e9, minimum(t).time/1e9, maximum(t).time/1e9
    end
end



if !ispath("./.benchmarks/Linux-CPython-3.9-64bit")
    mkpath("./.benchmarks/Linux-CPython-3.9-64bit")
end

write("./.benchmarks/Linux-CPython-3.9-64bit/single_gate_test.json", JSON.json(benchmarks,4))