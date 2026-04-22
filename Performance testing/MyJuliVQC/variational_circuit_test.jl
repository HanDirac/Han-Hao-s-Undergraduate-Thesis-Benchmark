using JSON, Base.Threads
using BenchmarkTools
using MyJuliVQC
using CSV
const gradientMJVQC = MyJuliVQC.gradient
mark = "MyJuliVQC"
const nqubit_list = 12:25  # 
const benchmarks = Dict()

function build_circuit(L::Int)
	depth = 10
	circuit = QCircuit()
	for i in 1:L
		push!(circuit, RzGate(i, randn()*2π; isparas=false))
		push!(circuit, RyGate(i, randn()*2π; isparas=false))
		push!(circuit, RzGate(i, randn()*2π; isparas=false))
	end		
	for i in 1:depth
		if isodd(i)
			for j in 1:(L-1)
		    	push!(circuit, CNOTGate(j, j+1))
			end
		else
			for j in (L-1):-1:1
		    	push!(circuit, CNOTGate(j, j+1))
			end			
		end
		for j in 1:L
			push!(circuit, RzGate(j, randn()*2π; isparas=false))
			push!(circuit, RyGate(j, randn()*2π; isparas=false))
			push!(circuit, RzGate(j, randn()*2π; isparas=false))
		end
	end
	circuit = fuse_gates(circuit)
	return circuit	
end



function ad_excute(circuit, state, ham)
	loss_obj = LossExpectationRealSV(ham, state)
	g = gradientMJVQC(loss_obj, circuit)
    return g
end

function _nparas(::Type{T}, L::Int, depth::Int) where {T <: Number} 
	n = depth+1
	return (T <: Real) ? n * L : n * L * 3
end 

function variational_circuit_1d(L::Int, depth::Int; θs::Vector{<:Real}=rand(_nparas(ComplexF64, L, depth)) .* 2π)
	paras = θs
	(length(paras) == _nparas(ComplexF64, L, depth)) || throw("wrong number of parameters.")
	circuit = QCircuit()
	ncount = 1
	for i in 1:L
		push!(circuit, RzGate(i, paras[ncount]; isparas=true))
		ncount += 1
		push!(circuit, RyGate(i, paras[ncount]; isparas=true))
		ncount += 1
		push!(circuit, RzGate(i, paras[ncount]; isparas=true))
		ncount += 1
	end		
	for i in 1:depth
		if isodd(i)
			for j in 1:(L-1)
		    	push!(circuit, CNOTGate(j, j+1))
			end
		else
			for j in (L-1):-1:1
		    	push!(circuit, CNOTGate(j, j+1))
			end			
		end
		for j in 1:L
			push!(circuit, RzGate(j, paras[ncount]; isparas=true))
			ncount += 1
			push!(circuit, RyGate(j, paras[ncount]; isparas=true))
			ncount += 1
			push!(circuit, RzGate(j, paras[ncount]; isparas=true))
			ncount += 1
		end
	end
	@assert ncount == length(paras)+1
	return circuit	
end

function heisenberg_chain(L::Int; J::Real=1., Jzz::Real=J, hz::Real=0.)
    terms = QubitsTerm[]
    # one site terms
    for i in 1:L
        push!(terms, QubitsTerm(Dict(i => "Z"); coeff = hz))
    end
    # nearest-neighbour interactions
    for i in 1:L-1
        t = QubitsTerm(Dict(i => "+", i+1 => "-"); coeff=2*J)
        push!(terms, t)
        push!(terms, adjoint(t))
        push!(terms, QubitsTerm(Dict(i => "Z", i+1 => "Z"); coeff=Jzz))
    end
    op = simplify!(QubitsOperator(terms))
    return op
end
heisenberg_1d(L::Int; kwargs...) = heisenberg_chain(L; kwargs...)

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


@task "vqc" nqubits=nqubit_list begin
    map(nqubit_list) do k
        circuit = build_circuit(k)
        t = @benchmark apply!($circuit, state) setup=(state = StateVector(ComplexF32, $k))
        tojson(x) = isfinite(x) ? x : missing   # NaN/Inf -> missing
        data = (mean(t).time/1e9, tojson(std(t).time/1e9), minimum(t).time/1e9, maximum(t).time/1e9)
    end
end

@task "ad" nqubits=nqubit_list begin
    map(nqubit_list) do k
		circ = variational_circuit_1d(k, 10)
        ham  = heisenberg_1d(k)
        t = @benchmark begin
            state = StateVector(ComplexF32, $k)   # 每次重建，避免被就地修改污染
            g = ad_excute($circ, state, $ham)
            # 模拟一次梯度下降步：s = 0 - η g
			s = zeros(eltype(g), size(g))
			@. s -= 0.01 * g

			s   # 返回，防止被优化掉
        end
        tojson(x) = isfinite(x) ? x : missing   # NaN/Inf -> missing
        data = (mean(t).time/1e9, tojson(std(t).time/1e9), minimum(t).time/1e9, maximum(t).time/1e9)
    end
end

if !ispath("./.benchmarks/MyJuliVQC")
    mkpath("./.benchmarks/MyJuliVQC")
end

write("./.benchmarks/MyJuliVQC/variational_circuit_test.json", JSON.json(benchmarks, 4; allownan=true))