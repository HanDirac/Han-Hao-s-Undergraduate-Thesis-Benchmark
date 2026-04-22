using JSON, Base.Threads
using BenchmarkTools
using MyJuliVQC
using DataFrames
using CSV
mark = "MyJuliVQC"
#BenchmarkTools.DEFAULT_PARAMETERS.seconds = 5000
#BenchmarkTools.DEFAULT_PARAMETERS.samples = 5
#BenchmarkTools.DEFAULT_PARAMETERS.evals = 1
const gradientMJVQC = MyJuliVQC.gradient
const nqubit_list = [5 6 7 8 9 10 11 12]
const benchmarks = Dict()
println("running")
function build_noisy_circuit(L::Int)
	depth = 4
	circuit = QCircuit()
	for i in 1:L
		push!(circuit, RxGate(i, randn()*2π; isparas=true))
		push!(circuit, RzGate(i, randn()*2π; isparas=true))
		push!(circuit, Depolarizing(i; p=0.01))
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
			push!(circuit, RxGate(j, randn()*2π; isparas=true))
			push!(circuit, RzGate(j, randn()*2π; isparas=true))
			push!(circuit, RxGate(j, randn()*2π; isparas=true))
		end
		for i in 1:L
			push!(circuit, Depolarizing(i; p=0.01))
		end
	end
	return circuit	
end

thread_count = Threads.nthreads()
key = "vqc_thread$(thread_count)"
println(key)
benchmarks[key] = Dict(
    "thread" => string(thread_count),
    "nqubits" => nqubit_list,
    "meantimes" => Union{Missing,Float64}[],
	"stdtimes" => Union{Missing,Float64}[],
	"minimumtimes" => Union{Missing,Float64}[],
	"maximumtimes" => Union{Missing,Float64}[]
)

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

function ad_excute(circuit, state, ham)
	loss_obj = LossExpectationRealDM(ham, state)
	g = gradientMJVQC(loss_obj, circuit)
    return g
end

for nqubit in nqubit_list
	result = @benchmark begin
		g = ad_excute($(build_noisy_circuit(nqubit)), $(DensityMatrix(ComplexF32, nqubit)), $(heisenberg_1d(nqubit)))
		s = zeros(eltype(g), size(g))
		@. s -= 0.01 * g
		s   # 返回，防止被优化掉
	end
	tojson(x) = isfinite(x) ? x : missing
	push!(benchmarks[key]["meantimes"], tojson(mean(result).time/1e9))
	push!(benchmarks[key]["stdtimes"], tojson(std(result).time/1e9))
	push!(benchmarks[key]["minimumtimes"], tojson(minimum(result).time/1e9))
	push!(benchmarks[key]["maximumtimes"], tojson(maximum(result).time/1e9))
end


function read_and_append_json(filename, new_data)
    existing_data = Dict()

    if isfile(filename) && filesize(filename) > 0
        try
            existing_data = JSON.parsefile(filename)
        catch e
            println("JSON error", e)
        end
    end

    existing_data = merge(existing_data, new_data)

    json_str = JSON.json(existing_data; pretty=4)

    open(filename, "w") do io
        write(io, json_str)
    end
end
new_data = Dict(key => benchmarks[key])

filename = "./.benchmarks/MyJuliVQC/noisy_ad_performance.json"


read_and_append_json(filename, new_data)