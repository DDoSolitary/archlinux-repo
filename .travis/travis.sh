#!/bin/bash
set -ex

# Install an Arch Linux chroot environment
pushd /tmp
wget -nv https://mirrors.kernel.org/archlinux/iso/latest/archlinux-bootstrap-2017.10.01-x86_64.tar.gz
tar xzf archlinux-bootstrap-2017.10.01-x86_64.tar.gz
mount --bind root.x86_64 root.x86_64
cd root.x86_64
cp /etc/resolv.conf etc/
mount -t proc /proc proc
mount --rbind /sys sys
mount --rbind /dev dev
popd

ARCH_ROOT=/tmp/root.x86_64
ARCH_PWD="$ARCH_ROOT$PWD"

# Mount the web server's filesystem
set +x
echo "$DEPLOYKEY" | base64 -d > /root/.ssh/id_ed25519
set -x
chmod 600 /root/.ssh/id_ed25519
cp .travis/known_hosts /root/.ssh/
mkdir repo
sshfs -o allow_other \
	ddosolitary@web.sourceforge.net:/home/project-web/archlinux-repo/htdocs/packages \
	repo

# Initialize the chroot environment
mkdir -p "$ARCH_PWD"
mount --rbind . "$ARCH_PWD"
function arch-chroot {
	chroot "$ARCH_ROOT" su -l $1 /bin/bash -c "cd '$PWD'; $2"
}
echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' > "$ARCH_ROOT/etc/pacman.d/mirrorlist"
arch-chroot root "pacman-key --init && pacman-key --populate archlinux"
arch-chroot root "pacman -Syu --needed --noconfirm base-devel git"
echo "LANG=en_US.UTF-8" > "$ARCH_ROOT/etc/locale.conf"
echo "en_US.UTF-8 UTF-8" > "$ARCH_ROOT/etc/locale.gen"
arch-chroot root locale-gen

# Download PKGBUILDs from AUR
for i in $(cat aur-build-list); do
	curl -L "https://aur.archlinux.org/cgit/aur.git/snapshot/$i.tar.gz" | tar xz
done

# Prepare for building packages
arch-chroot root "useradd builder -m"
echo "builder ALL=(ALL) NOPASSWD: ALL" >> "$ARCH_ROOT/etc/sudoers"
set +x
echo "$GPGKEY" | base64 -d | arch-chroot builder "gpg --import"
set -x
cat >> "$ARCH_ROOT/etc/makepkg.conf" <<- EOF
	PKGDEST="$PWD/repo"
	PACKAGER="DDoSolitary <DDoSolitary@gmail.com>"
	GPG_KEY="6DC20782F6E9E2F3"
EOF
arch-chroot root "pacman-key --add .travis/pubkey && pacman-key --lsign-key 6DC20782F6E9E2F3"

# Build packages
mkdir provides
for i in */PKGBUILD; do
	PKG="$(dirname "$i")"
	for j in "$PKG" $(source "$PKG/PKGBUILD" && echo ${provides[@]}); do
		echo "$PKG" >> "provides/$j"
	done
done
function build {
	for i in $(source PKGBUILD && echo ${depends[@]} && echo ${makedepends[@]} && echo ${checkdepends[@]}); do
		PKG="$(echo "$i" | sed "s/[<>=].*//")"
		if [ -f "../provides/$PKG" ]; then
			for j in $(cat "../provides/$PKG"); do
				pushd "../$j"
				PKG_INSTALL=i build
				popd
			done
		fi
	done
	chmod -R 777 .
	arch-chroot builder "makepkg -sr$PKG_INSTALL --sign --needed --noconfirm" || true
}
for i in */PKGBUILD; do
	pushd "$(dirname "$i")"
	build
	popd
done
pushd repo
for i in *.pkg.tar.xz; do
	arch-chroot builder "repo-add -n -R -s archlinux-ddosolitary.db.tar.gz '$i'"
done
popd

# Unmount the web server's filesystem
fusermount -u repo
