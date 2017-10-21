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

# Initialize the chroot environment
mkdir -p "$ARCH_PWD"
mount --bind . "$ARCH_PWD"
function arch-chroot {
	chroot "$ARCH_ROOT" su -l $1 /bin/bash -c "cd '$PWD'; $2"
}
cp .travis/mirrorlist "$ARCH_ROOT/etc/pacman.d/"
arch-chroot root "pacman-key --init && pacman-key --populate archlinux"
arch-chroot root "pacman -Syu --noconfirm base-devel git"

# Mount the web server's filesystem
MOUNT_POINT="$ARCH_PWD/repo"
echo "$DEPLOYKEY" | base64 -d > /root/.ssh/id_ed25519
chmod 600 /root/.ssh/id_ed25519
cp .travis/known_hosts /root/.ssh/
mkdir "$MOUNT_POINT"
sshfs -o allow_other \
	ddosolitary@web.sourceforge.net:/home/project-web/archlinux-repo/htdocs/packages \
	"$MOUNT_POINT"

# Prepare for building packages
arch-chroot root "useradd builder -m"
echo "builder ALL=(ALL) NOPASSWD: ALL" >> "$ARCH_ROOT/etc/sudoers"
echo "$GPGKEY" | base64 -d | arch-chroot builder "gpg --import"
cat >> "$ARCH_ROOT/etc/makepkg.conf" <<- EOF
	PKGDEST="$PWD/repo"
	PACKAGER="DDoSolitary <DDoSolitary@gmail.com>"
	GPG_KEY="6DC20782F6E9E2F3"
EOF

# Build packages
for i in */PKGBUILD; do
	pushd "$(dirname "$i")"
	chmod 777 .
	arch-chroot builder "makepkg -sr --sign" || true
	popd
done
cd repo
for i in *.pkg.*; do repo-add -n -R archlinux-ddosolitary.db.tar.gz "$i"; done

# Unmount the web server's filesystem
fusermount -u "$MOUNT_POINT"
