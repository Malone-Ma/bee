#!/bin/bash
## 参数介绍
## d) db-capacity
## e) swap-endpoint
## c) 是否启用clef
## p) password

apt update && apt install expect jq

#set接受参数
v_db="30000000"
v_end="304ee59b22ca40eb86be1c051c8d79e2"
v_clef="true"
v_password="beebeebee"

#接收可选参数
while getopts :d:e:c:p: opt
do
  case "$opt" in
  d) v_db=$OPTARG;; 
  e) v_end=$OPTARG;;
  c) v_clef=$OPTARG;;
  p) v_password=$OPTARG;;
  *) echo "Unknown option: $opt" ;;
  esac
done

export TERM=vt100

echo -e "let's start the bee programe... \n"

echo -e "start change config file... \n"

mkdir /root/.beeconfig
cp /root/bee/bee-config-default.yaml /root/.beeconfig/bee-config-1.yaml

sed -i "s/v_db/${v_db}/g" /root/.beeconfig/bee-config-1.yaml
sed -i "s/v_end/${v_end}/g" /root/.beeconfig/bee-config-1.yaml
sed -i "s/v_clef/${v_clef}/g" /root/.beeconfig/bee-config-1.yaml

echo -e "have changed config file... \n"

screen_clef_name=$"clef"
screen_bee_name=$"bee"

# 开始安装bee和clef包
dpkg -i /root/bee/bee-clef_0.4.10_amd64.deb
dpkg -i /root/bee/bee_0.5.3_amd64.deb

chmod a+x /root/bee/clef-service && chmod a+x /root/bee/cashout.sh

cp /root/bee/cashout.sh /usr/local/bin

cmd_clef=$"/root/bee/clef-service start";

# cmd_bee=$"bee start --verbosity 5 --swap-endpoint https://goerli.infura.io/v3/304ee59b22ca40eb86be1c051c8d79e2 --debug-api-enable --clef-signer-enable --clef-signer-endpoint /var/lib/bee-clef/clef.ipc"
cmd_bee=$"bee start --config /root/.beeconfig/bee-config-1.yaml"

screen -dmS $screen_clef_name

screen -x -S $screen_clef_name -p 0 -X stuff "$cmd_clef"
screen -x -S $screen_clef_name -p 0 -X stuff "\n"

/usr/bin/expect <<EOF
send "\01d"
expect eof
EOF

sleep 30s
echo -e "start screen bee... \n"

# screen -dmS $screen_bee_name
# screen -x -S $screen_bee_name -p 0 -X stuff "$cmd_bee"
# screen -x -S $screen_bee_name -p 0 -X stuff "\n"

/usr/bin/expect <<EOF
spawn screen -S ${screen_bee_name} ${cmd_bee}
expect {
"*Password:" {  send "${v_password}\r";exp_continue }
"*Confirm*" { send "${v_password}\r" }
}
send "\01d"
expect eof
EOF

echo "* */24 * * * /usr/local/bin/cashout.sh cashout-all 5" >> /var/spool/cron/root

echo '{"id": 1, "jsonrpc": "2.0", "method": "account_list"}' | nc -U /var/lib/bee-clef/clef.ipc
