#!/bin/bash -e

if [ "$CI" == "true" ]; then
	echo "$GPGKEY" | base64 -d | gpg --import
	mkdir -p ~/.ssh
	echo "$DEPLOYKEY" | base64 -d > ~/.ssh/id_ed25519 
	chmod 600 ~/.ssh/id_ed25519
	eval $(ssh-agent)
	ssh-add ~/.ssh/id_ed25519
	unset GPGKEY DEPLOYKEY
fi

modprobe fuse
docker run -d \
	-p 2200:22 \
	-v "$PWD":/home/builder/src \
	--privileged \
	quay.io/ddosolitary/archlinux-builder

gpg_socket=$(gpgconf --list-dirs | grep agent-socket | cut -d : -f 2)
ssh -p 2200 \
	-o UserKnownHostsFile=/dev/null \
	-o StrictHostKeyChecking=no \
	-o ForwardAgent=yes \
	-o RemoteForward="/home/builder/.gnupg/S.gpg-agent $gpg_socket" \
	builder@127.0.0.1 \
	./src/build.sh
