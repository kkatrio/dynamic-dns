### Dynamic netlify DNS

needs:
- bash
- curl
- jq

supposed to run in a cronjob with something like
`*/5 * * * * make -C /home/kon/dynamic-dns/`

An .env file must exist, like:
ACCESS_TOKEN=<app token>
DOMAIN=<domain>
SUBDOMAIN=<subdomain>
