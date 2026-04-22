#!/bin/bash
#SBATCH --job-name=ju_var_cir
#SBATCH --partition=normal         # 可改：short / normal / long / gpu
#SBATCH --cpus-per-task=1
#SBATCH --exclusive            # 独占整节点
#SBATCH --mem=0                # 使用该节点所有内存
#SBATCH --output=slurm-%j.out      # 标准输出
#SBATCH --error=slurm-%j.err       # 标准错误（也可合并到上面）

set -euo pipefail

# 如果集群有 module，可以按需加载（没有就删掉）
# module load julia/1.10

# 线程（建议跟随 Slurm 分到的核数）
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
export MKL_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
export MKL_DOMAIN_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
export JULIA_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}

# 到脚本所在目录（可选，但通常方便相对路径）
cd "$SLURM_SUBMIT_DIR"

# 运行 JuliVQC 的 single-gate benchmark
julia --project=../JuliVQC_env variational_circuit_test.jl


