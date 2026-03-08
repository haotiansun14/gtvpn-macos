SHELL := /bin/bash

check:
	bash -n install.sh bin/gtvpn lib/common.sh scripts/*.sh

lint:
	shellcheck install.sh bin/gtvpn lib/common.sh scripts/*.sh
