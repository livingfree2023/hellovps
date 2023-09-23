#in openwrt
cftoken=[****]
cfzone=[****]
cfbestipid=[****]
cfbestipname=[****]

echo "------------------"
date
echo "------------------"

currentIP=$(nslookup [****] 1.1.1.1 | grep "Address: "|awk -F': ' '{ print $2 }')
echo "Current bestip is $currentIP"

/usr/bin/cdnspeedtest \
     -url https://speed.leosblog.link/500MB-CZIPtestfile.org.zip \
     -o currentspeed.tmp \
     -dt 5 \
     -ip $currentIP

currentSpeed=$(cat currentspeed.tmp |awk -F',' 'NR==2 {print $6}')

echo "Current speed is $currentSpeed"
echo "Speed testing..."

/usr/bin/cdnspeedtest \
	-dn 3 \
	-url [****] \
	-o /usr/share/cloudflarespeedtestresult.txt \
	-f /usr/share/CloudflareSpeedTest/ip.txt \
	-tl 180 \
	-tll 20 \
	-tlr 0.2 \
	-dt 5 \
	-sl 25 \
	> /dev/null 2>&1

head /usr/share/cloudflarespeedtestresult.txt

newIP=$(sed -n "2,1p" /usr/share/cloudflarespeedtestresult.txt | awk -F, '{print $1}')
newSpeed=$(sed -n "2,1p" /usr/share/cloudflarespeedtestresult.txt | awk -F, '{print $6}')

if [[ $(($newSpeed-$currentSpeed)) > 0 ]]; then
  echo "New Speed is faster. Updating to DNS: bestip.leosvps.cf"

  response=$(
		curl -s\
		-X PUT "https://api.cloudflare.com/client/v4/zones/$cfzone/dns_records/$cfbestipid" \
		-H "Authorization: Bearer $cftoken" \
		-H "Content-Type: application/json" \
		--data '{"type":"A","name":"'$cfbestipname'","content":"'$newIP'","ttl":1,"proxied":false, "Comment":"auto updated by script"}' \
		| jq -r '.success')

  echo "Update successful = $response"

else
  echo "Current Speed is faster, skipping updating DNS"
fi


echo "------------------"
echo "Done"
echo "------------------"
