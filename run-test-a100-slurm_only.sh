#!/bin/bash
#SBATCH --account=nstaff
#SBATCH -N 1
#SBATCH -C dgx
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=32
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

## print numactl --hardware command
numactl_hdw="numactl --hardware"
echo "$numactl_hdw"
$numactl_hdw

echo "slurm-tasks-per-node = $ntasks_node"
echo "slurm-cpus-per-task = $SLURM_CPUS_PER_TASK"
echo "slurm-cpus-on-node = $cpus_node"
echo "gpus-per-task = $gpu_task, total-gpus-req = $total_gpus"

export OMP_NUM_THREADS=16
export OMP_PROC_BIND=spread
export OMP_PLACES=threads
exe=./cudahello

r=$SLURM_NTASKS_PER_NODE			# default number of ranks per node

export EXE=$exe

if [[ ${SLURM_JOB_PARTITION} == "dgx" ]]; then
  option=2
  if [[ ${OPTION} == "0" ]]; then
    # Rank to numa domain is reordered to minize distance to the GPU
    command="srun -n$ntasks_node -c$c_task --cpu_bind=map_ldom:3,2,1,0,7,6,5,4 $exe"
  elif [[ ${OPTION} == "1" ]]; then
    # Only use numa domains 3, 1, 7 and 5 to avoid Infinity Fabric hops
    # Reduce the number of threads, and unset OMP bindings
    #   this means the OS can float cores and hopefully balance them w/o overlap
    export OMP_NUM_THREADS=8
    unset OMP_PROC_BIND
    unset OMP_PLACES
    command="srun -n$ntasks_node -c$c_task --cpu_bind=map_ldom:3,3,1,1,7,7,5,5 $exe"
  elif [[ ${OPTION} == "2" ]]; then
    # Only use numa domains 3, 1, 7 and 5 to avoid Infinity Fabric hops
    # Explicity bind 1/2 the threads per domain
    #   should be an advantage over option 1
    export OMP_NUM_THREADS=8
    mask7h="0xff000000000000000000000000000000"
    mask7l="0x00ff0000000000000000000000000000"
    mask5h="0x00000000ff0000000000000000000000"
    mask5l="0x0000000000ff00000000000000000000"
    mask3h="0x0000000000000000ff00000000000000"
    mask3l="0x000000000000000000ff000000000000"
    mask1h="0x000000000000000000000000ff000000"
    mask1l="0x00000000000000000000000000ff0000"
    export mask="$mask3h,$mask3l,$mask1h,$mask1l,$mask7h,$mask7l,$mask5h,$mask5l"
    command="srun -n$ntasks_node -c$c_task --cpu_bind=mask_cpu:$mask $exe"
  else
    # Nominal slurm binding of linear numa domain mapping 0,1,2,3,4,5,6,7
    #   however, this is not optimal as up to 2 IF hops are encountered
    command="srun -n$ntasks_node -c$c_task --cpu_bind=cores $exe"
  fi
else
  export OMP_NUM_THREADS=10
  command="srun -n$ntasks_node -c$c_task --cpu_bind=cores $exe"
fi

#### Echo and run command
echo $command
$command
