#!/usr/bin/env bash 

[ -f .env ] && source .env
[ -z "$ACCESS_TOKEN" ] && { echo "ACCESS_TOKEN environment variable not set"; exit 1; }
[ -z "$DOMAIN" ] && { echo "DOMAIN environment variable not set"; exit 1; }
[ -z "$SUBDOMAIN" ] && { echo "SUBDOMAIN environment variable not set"; exit 1; }

API="https://api.netlify.com/api/v1"
DNS_ZONE="$(<<< "$DOMAIN" tr "." "_")"
DNS_RECORDS_URL="$API/dns_zones/$DNS_ZONE/dns_records?access_token=$ACCESS_TOKEN"

IPV4=$(curl -sL -4 ifconfig.io)
echo "ip is $IPV4"


CURRENT_DNS=$(curl -sL "$DNS_RECORDS_URL" | jq -r 'map(select(.type == "A"))')

search_dns_records(){
	<<< "$CURRENT_DNS" jq "$@"
}

record_exists(){
	search_dns_records -e "map(select(.hostname == \"$SUBDOMAIN.$DOMAIN\"))[0]" > /dev/null
}

ip_changed(){
	RECORD_IP="$(search_dns_records -r "map(select(.hostname == \"$SUBDOMAIN.$DOMAIN\"))[0].value")"
	[[ $RECORD_IP == $IPV4 ]] && return 1
	echo "ip changed!"
}

delete_dns_record(){
	echo "deleting existing record..."
	RECORD_ID="$(search_dns_records -r "map(select(.hostname == \"$SUBDOMAIN.$DOMAIN\"))[0].id")"
	if [[ $(curl -o /dev/null -sL -w "%{http_code}" -X DELETE "$API/dns_zones/$DNS_ZONE/dns_records/$RECORD_ID?access_token=$ACCESS_TOKEN") -eq 204 ]]; then
		return 0
	else
		return 1
	fi
}

create_dns_record(){
	echo "creating existing record..."
	PAYLOAD=$(jq -n -r '{type:"A",hostname:"'$SUBDOMAIN'.$DOMAIN",ttl:"3600",value:"'$IPV4'"}')
	if [[ $(curl -o /dev/null -sL -w "%{http_code}" -d "$PAYLOAD" -H 'content-type:application/json' "$DNS_RECORDS_URL") -eq 201 ]]; then
		return 0
	else
		return 1
	fi
}

if record_exists && ip_changed; then
	delete_dns_record && echo "deleted"
	create_dns_record && echo "created"
fi
