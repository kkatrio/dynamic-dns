### Dynamic netlify DNS

needs:
- bash
- curl
- jq

supposed to run in a cronjob with something like
`*/5 * * * * make -C /home/kon/dynamic-dns/`
