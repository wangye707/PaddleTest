#!/usr/bin/env bash
#外部传入参数说明
# $1: 'single' 单卡训练； 'multi' 多卡训练； 'recv' 恢复训练
# $2:  $XPU = gpu or cpu
#获取当前路径
cur_path=`pwd`
model_name=${PWD##*/}

echo "$model_name 模型train阶段"

#路径配置
root_path=$cur_path/../../
code_path=$cur_path/../../PaddleSlim/demo/dygraph/unstructured_pruning
log_path=$root_path/log/$model_name/
mkdir -p $log_path
#临时环境更改

export FLAGS_cudnn_deterministic=True

#访问RD程序
print_info(){
if [ $1 -ne 0 ];then
    echo "exit_code: 1.0" >> ${log_path}/$2.log
    echo -e "\033[31m FAIL_$2 \033[0m"
    echo $2 fail log as follows
    cat ${log_path}/$2.log
    cp ${log_path}/$2.log ${log_path}/FAIL_$2.log
else
    cat ${log_path}/$2.log
    echo "exit_code: 0.0" >> ${log_path}/$2.log
fi
}

cd $code_path
echo -e "\033[32m `pwd` train \033[0m";

if [ "$1" = "linux_st_gpu1" ];then #单卡
    python  train.py \
    --data imagenet \
    --lr 0.05 \
    --pruning_mode ratio \
    --ratio 0.55 \
    --batch_size 256 \
    --lr_strategy piecewise_decay \
    --step_epochs 1 2 3 \
    --num_epochs 1 \
    --test_period 1 \
    --model_period 1 \
    --model_path dy_ratio_models \
    --ce_test True > ${log_path}/$2.log 2>&1
    print_info $? $2

elif [ "$1" = "linux_st_gpu2" ];then #多卡
    python -m paddle.distributed.launch \
          --log_dir='train_dy_ratio_log' \
          train.py \
          --batch_size 64 \
          --data 'cifar10' \
          --pruning_mode ratio \
          --ratio 0.75 \
          --lr 0.005 \
          --num_epochs 20 \
          --step_epochs 13 17 \
          --initial_ratio 0.15 \
          --pruning_steps 10 \
          --stable_epochs 0 \
          --pruning_epochs 10 \
          --tunning_epochs 10 \
          --pruning_strategy gmp \
          --local_sparsity True \
          --prune_params_type 'conv1x1_only' \
          --ce_test True > ${log_path}/$2.log 2>&1
    print_info $? $2

elif [ "$1" = "linux_st_cpu" ];then #cpu
    python  train.py \
    --data imagenet \
    --lr 0.05 \
    --pruning_mode ratio \
    --ratio 0.55 \
    --batch_size 256 \
    --lr_strategy piecewise_decay \
    --step_epochs 1 2 3 \
    --num_epochs 1 \
    --test_period 1 \
    --model_period 1 \
    --model_path dy_ratio_models \
    --use_gpu False > ${log_path}/$2.log 2>&1
    print_info $? $2

fi
