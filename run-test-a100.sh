#!/bin/bash
#SBATCH --account=nstaff
#SBATCH -N 1
#SBATCH -C dgx
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=16
#SBATCH --gpus-per-task=1
#SBATCH --time=00:02:00
#SBATCH -J HelloWorld
#SBATCH -o HelloWorld.o%j

num_nodes=$SLURM_JOB_NUM_NODES
ntasks_node=$SLURM_NTASKS_PER_NODE
cpus_node=$SLURM_CPUS_ON_NODE
ht_node=2				# hyperthreads per node
c_task=$(( $cpus_node / $ntasks_node ))	# number of cores/node
gpu_task=$SLURM_GPUS_PER_TASK
total_gpus=$(($gpu_task * $ntasks_node ))

# Hoping that the the compilation happened inside a dir named build
build_dir="build"


echo "slurm-tasks-per-node = $ntasks_node"
echo "slurm-cpus-per-task = $SLURM_CPUS_PER_TASK"
echo "slurm-cpus-on-node = $cpus_node"
echo "gpus-per-task = $gpu_task, total-gpus-req = $total_gpus"

if [[ ${SLURM_JOB_PARTITION} == "dgx" ]]
then
export OMP_NUM_THREADS=16
exe=$build_dir/./cudahello.a100
else
export OMP_NUM_THREADS=10
exe=$build_dir/./cudahello.v100
fi

r=$SLURM_NTASKS_PER_NODE			# default number of ranks per node

export EXE=$exe

if [[ ${SLURM_JOB_PARTITION} == "dgx" ]]
then
command="srun -n$ntasks_node -c$c_task ./bind-cori-a100.sh"
else
command="srun -n$ntasks_node -c$c_task ./bind-cori-v100.sh"
fi

#### Echo and run command
echo $command
$command
