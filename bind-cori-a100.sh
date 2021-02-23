#!/usr/bin/env bash

# Based on the output of `nvidia-smi topo -m` from Rahul:
#        GPU0    GPU1    GPU2    GPU3    GPU4    GPU5    GPU6    GPU7    mlx5_0  mlx5_1  mlx5_2  mlx5_3  mlx5_4  mlx5_5  mlx5_6  mlx5_7  mlx5_8  mlx5_9  mlx5_10 CPU Affinity    NUMA Affinity
#GPU0     X      NV12    NV12    NV12    NV12    NV12    NV12    NV12    PXB     PXB     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     0-14,16-30      0-7
#GPU1    NV12     X      NV12    NV12    NV12    NV12    NV12    NV12    PXB     PXB     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     0-14,16-30      0-7
#GPU2    NV12    NV12     X      NV12    NV12    NV12    NV12    NV12    SYS     SYS     PXB     PXB     SYS     SYS     SYS     SYS     SYS     SYS     SYS     16-30,144-158   1
#GPU3    NV12    NV12    NV12     X      NV12    NV12    NV12    NV12    SYS     SYS     PXB     PXB     SYS     SYS     SYS     SYS     SYS     SYS     SYS     16-30,144-158   1
#GPU4    NV12    NV12    NV12    NV12     X      NV12    NV12    NV12    SYS     SYS     SYS     SYS     SYS     PXB     PXB     SYS     SYS     SYS     SYS     0-14,16-30      0-7
#GPU5    NV12    NV12    NV12    NV12    NV12     X      NV12    NV12    SYS     SYS     SYS     SYS     SYS     PXB     PXB     SYS     SYS     SYS     SYS     0-14,16-30      0-7
#GPU6    NV12    NV12    NV12    NV12    NV12    NV12     X      NV12    SYS     SYS     SYS     SYS     SYS     SYS     SYS     PXB     PXB     SYS     SYS     0-14,16-30      0-7
#GPU7    NV12    NV12    NV12    NV12    NV12    NV12    NV12     X      SYS     SYS     SYS     SYS     SYS     SYS     SYS     PXB     PXB     SYS     SYS     0-14,16-30      0-7
#mlx5_0  PXB     PXB     SYS     SYS     SYS     SYS     SYS     SYS      X      PXB     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS
#mlx5_1  PXB     PXB     SYS     SYS     SYS     SYS     SYS     SYS     PXB      X      SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS
#mlx5_2  SYS     SYS     PXB     PXB     SYS     SYS     SYS     SYS     SYS     SYS      X      PXB     SYS     SYS     SYS     SYS     SYS     SYS     SYS
#mlx5_3  SYS     SYS     PXB     PXB     SYS     SYS     SYS     SYS     SYS     SYS     PXB      X      SYS     SYS     SYS     SYS     SYS     SYS     SYS
#mlx5_4  SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS      X      SYS     SYS     SYS     SYS     SYS     SYS
#mlx5_5  SYS     SYS     SYS     SYS     PXB     PXB     SYS     SYS     SYS     SYS     SYS     SYS     SYS      X      PXB     SYS     SYS     SYS     SYS
#mlx5_6  SYS     SYS     SYS     SYS     PXB     PXB     SYS     SYS     SYS     SYS     SYS     SYS     SYS     PXB      X      SYS     SYS     SYS     SYS
#mlx5_7  SYS     SYS     SYS     SYS     SYS     SYS     PXB     PXB     SYS     SYS     SYS     SYS     SYS     SYS     SYS      X      PXB     SYS     SYS
#mlx5_8  SYS     SYS     SYS     SYS     SYS     SYS     PXB     PXB     SYS     SYS     SYS     SYS     SYS     SYS     SYS     PXB      X      SYS     SYS
#mlx5_9  SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS      X      PIX
#mlx5_10 SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     SYS     PIX      X


# this is the list of GPUs we have
GPUS=(0 1 2 3 4 5 6 7)

# This is the list of NICs we should use for each GPU
# This is based on matching GPUs to PXB, which is "more connected" than SYS
NICS=(mlx5_0:1 mlx5_1:1 mlx5_2:1 mlx5_3:1 mlx5_5:1 mlx5_6:1 mlx5_7:1 mlx5_8:1)

# This is the list of CPU numa regions we should use for each GPU
# The NUMA Affinity info seems a little weird, so I'm making some socket
# binding assumptions
CPUS=(3 3 1 1 7 7 5 5)

# this is the order we want the GPUs to be assigned in (e.g. for NVLink connectivity)
# Since everything is bound, NVLink connectivity doesn't matter
REORDER=(0 1 2 3 4 5 6 7)

# now given the REORDER array, we set CUDA_VISIBLE_DEVICES, NIC_REORDER and CPU_REORDER to for this mapping
export CUDA_VISIBLE_DEVICES="${GPUS[${REORDER[0]}]},${GPUS[${REORDER[1]}]},${GPUS[${REORDER[2]}]},${GPUS[${REORDER[3]}]},${GPUS[${REORDER[4]}]},${GPUS[${REORDER[5]}]},${GPUS[${REORDER[6]}]},${GPUS[${REORDER[7]}]}"
NIC_REORDER=(${NICS[${REORDER[0]}]} ${NICS[${REORDER[1]}]} ${NICS[${REORDER[2]}]} ${NICS[${REORDER[3]}]} ${NICS[${REORDER[4]}]} ${NICS[${REORDER[5]}]} ${NICS[${REORDER[6]}]} ${NICS[${REORDER[7]}]}) 
CPU_REORDER=(${CPUS[${REORDER[0]}]} ${CPUS[${REORDER[1]}]} ${CPUS[${REORDER[2]}]} ${CPUS[${REORDER[3]}]} ${CPUS[${REORDER[4]}]} ${CPUS[${REORDER[5]}]} ${CPUS[${REORDER[6]}]} ${CPUS[${REORDER[7]}]})

APP="$EXE"

lrank=$SLURM_LOCALID


export UCX_NET_DEVICES=${NIC_REORDER[$lrank]}
numactl_cmd="numactl --cpunodebind=${CPU_REORDER[$lrank]} --membind=${CPU_REORDER[$lrank]}"
echo "Local rank $lrank using UCX device $UCX_NET_DEVICES running $APP"

echo "$numactl_cmd $APP"
$numactl_cmd $APP
#$APP
