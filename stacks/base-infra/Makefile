SSH_KEY=modules/transit-opentest/ssh/id_rsa

$(SSH_KEY):
	mkdir -p modules/transit-opentest/ssh
	ssh-keygen -q -N "" -f $(SSH_KEY)
	chmod -c 0600 $(SSH_KEY)

_ssh_key: $(SSH_KEY)

_apply: _ssh_key
	terraform apply
