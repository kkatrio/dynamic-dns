include .env

.PHONY: run

run: .env
	./update_dns.sh
