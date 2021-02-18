#!/bin/bash
#SBATCH --account=m1759
#SBATCH -N 1
#SBATCH -C gpu
#SBATCH --ntasks-per-node=7
#SBATCH --cpus-per-task=10
#SBATCH --gpus-per-task=1
#SBATCH --time=00:02:00
#SBATCH --job-name=cudahello

echo "slurm-tasks-per-node = $SLURM_NTASKS_PER_NODE"
echo "slurm-cpus-per-task = $SLURM_CPUS_PER_TASKS"
echo "slurm-cpus-on-node = $SLURM_CPUS_ON_NODE"
#srun bash -c 'echo "slurm-cpus-per-task = $SLURM_CPUS_PER_TASKS"'

num_nodes=$SLURM_JOB_NUM_NODES
ntasks_node=$SLURM_NTASKS_PER_NODE
cpus_node=$SLURM_CPUS_ON_NODE
ht_node=2				# hyperthreads per node
c_task=$(( $cpus_node / $ntasks_node ))	# number of cores/node

exe=./cudahello
debug="true"
r=$SLURM_NTASKS_PER_NODE			# default number of ranks per node

command="srun -n$ntasks_node -c$c_task $exe"
echo $command
$command
