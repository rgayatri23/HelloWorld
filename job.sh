#!/bin/bash
#SBATCH -A nstaff
#SBATCH -C gpu
#SBATCH -q debug
#SBATCH -t 0:05:00
#SBATCH --nodes 2
#SBATCH --ntasks-per-node=4
#SBATCH -J cudahello
#SBATCH -o %x-%j.ou
#SBATCH --cpus-per-task=4
#SBATCH --gpus-per-task=1
#SBATCH --gpu-bind=none

cat $0

module load PrgEnv-gnu
export MPICH_GPU_SUPPORT_ENABLED=1

#mpi=mpich
mpi=openmpi

if [ $mpi = "mpich" ]; then
    source /global/homes/r/rgayatri/PrgEnv-env/mpich4.1.env
else
    source /global/homes/r/rgayatri/PrgEnv-env/openmpi5.0.0rc10-ofi-cuda-22.5_11.7
fi

exe=cudahello
#exe=mpihello

total_tasks=$SLURM_NTASKS
ntasks_node=$SLURM_NTASKS_PER_NODE

srun_command="srun -n${total_tasks} --gpus-per-task=${SLURM_GPUS_PER_TASK} --gpu-bind=none"

command="$srun_command ./${exe}.ex $parameters"

echo $command
$command
