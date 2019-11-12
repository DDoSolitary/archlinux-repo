FROM archlinux/base
ARG GPGKEY_ID=688E1D093C3638F588890D4450268311C7AD3F62
RUN pacman -Syu --needed --noconfirm base base-devel openssh sshfs
RUN ssh-keygen -A && \
	echo StreamLocalBindUnlink yes >> /etc/ssh/sshd_config && \
	echo user_allow_other >> /etc/fuse.conf && \
	echo PKGDEST=/home/builder/repo >> /etc/makepkg.conf && \
	echo 'PACKAGER="DDoSolitary <DDoSolitary@gmail.com>"' >> /etc/makepkg.conf && \
	echo GPG_KEY=$GPGKEY_ID >> /etc/makepkg.conf && \
	echo [multilib] >> /etc/pacman.conf && \
	echo Include = /etc/pacman.d/mirrorlist >> /etc/pacman.conf && \
	pacman -Sy --needed --noconfirm multilib-devel && \
	echo [archlinux-ddosolitary] >> /etc/pacman.conf && \
	echo Server = file:///home/builder/repo >> /etc/pacman.conf && \
	echo SigLevel = Required >> /etc/pacman.conf && \
	pacman-key --keyserver hkps://keys.openpgp.org -r $GPGKEY_ID && \
	pacman-key --init && \
	pacman-key --lsign-key $GPGKEY_ID && \
	useradd -m -p "" builder && \
	echo builder ALL=\(ALL\) NOPASSWD: ALL >> /etc/sudoers
USER builder
RUN mkdir ~/.ssh ~/repo ~/src ~/build && \
	ssh-keyscan web.sourceforge.net > ~/.ssh/known_hosts && \
	chmod 600 ~/.ssh/known_hosts && \
	gpg --keyserver hkps://keys.openpgp.org --recv-keys $GPGKEY_ID
CMD sudo /usr/bin/sshd -D -o PasswordAuthentication=yes -o PermitEmptyPasswords=yes
