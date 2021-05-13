#!/bin/bash
## 参数介绍
## d) db-capacity
## e) swap-endpoint
## c) 是否启用clef


#set接受参数
v_db="30000000"
v_end="304ee59b22ca40eb86be1c051c8d79e2"
v_clef="true"

#接收可选参数
while getopts :d:e:c: opt
do
  case "$opt" in
  d) v_db=$OPTARG;; 
  e) v_end=$OPTARG;;
  c) v_clef=$OPTARG;;
  *) echo "Unknown option: $opt" ;;
  esac
done


screen_clef_name=$"clef"
screen_bee_name=$"bee"
passwd=$"passwd"

echo -e "let's start the bee programe... \n"
echo -e "your current bee path is \n"

echo `pwd`

apt update && apt install expect jq

# 开始安装bee和clef包
dpkg -i `pwd`/bee-clef_0.4.10_amd64.deb
dpkg -i `pwd`/bee_0.5.3_amd64.deb

chmod +x `pwd`/clef-service

cmd_clef=$"`pwd`/clef-service start";

# cmd_bee=$"bee start --verbosity 5 --swap-endpoint https://goerli.infura.io/v3/304ee59b22ca40eb86be1c051c8d79e2 --debug-api-enable --clef-signer-enable --clef-signer-endpoint /var/lib/bee-clef/clef.ipc"
cmd_bee=$"bee start --config /etc/bee/bee.yaml"

screen -dmS $screen_clef_name

screen -x -S $screen_clef_name -p 0 -X stuff "$cmd_clef"
screen -x -S $screen_clef_name -p 0 -X stuff "\n"

/usr/bin/expect <<EOF
send "\01d"
expect eof
EOF

sleep 30s


# screen -dmS $screen_bee_name
# screen -x -S $screen_bee_name -p 0 -X stuff "$cmd_bee"
# screen -x -S $screen_bee_name -p 0 -X stuff "\n"

/usr/bin/expect <<EOF
spawn screen -S $screen_bee_name $cmd_bee
expect {
"*Password:" {  send "123456\r";exp_continue }
"*Confirm*" { send "123456\r" }
}
send "\01d"
# send "d"
expect eof
EOF

echo '{"id": 1, "jsonrpc": "2.0", "method": "account_list"}' | nc -U /var/lib/bee-clef/clef.ipc
