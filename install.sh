#!/bin/bash
## 参数介绍
## $1 = 单服务器节点数量,默认ip按照顺序添加
## $2 = 硬盘存储空间设置
## $3 = 1 不安装bee-clef
screen_clef_name = $"clef"
screen_bee_name = $"bee"

echo -e "let's start the bee programe... \n"
echo -e "your current bee path is \n"

echo `pwd`

# 开始安装bee和clef包
dpkg -i `pwd`/bee-clef_0.4.10_amd64.deb
dpkg -i `pwd`/bee_0.5.3_amd64.deb

chmod +x `pwd`/clef-service

cmd_clef=$"`pwd`/clef-service start";

cmd_bee=$"bee start --verbosity 5 --swap-endpoint https://goerli.infura.io/v3/304ee59b22ca40eb86be1c051c8d79e2 --debug-api-enable --clef-signer-enable --clef-signer-endpoint /var/lib/bee-clef/clef.ipc"

screen -x -S $screen_clef_name -p 0 -X stuff "$cmd_clef"

sleep 1m

screen -x -S $screen_bee_name -p 0 -X stuff "$cmd_bee"
