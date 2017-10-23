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
mount --rbind /run run
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
arch-chroot root "pacman-key --init && pacman-key --populate archlinux"
echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' > "$ARCH_ROOT/etc/pacman.d/mirrorlist"
arch-chroot root "pacman -Syu --needed --noconfirm base base-devel"
echo "LANG=en_US.UTF-8" > "$ARCH_ROOT/etc/locale.conf"
echo "en_US.UTF-8 UTF-8" > "$ARCH_ROOT/etc/locale.gen"
arch-chroot root locale-gen

# Prepare for building packages
arch-chroot root "useradd builder -m"
echo "builder ALL=(ALL) NOPASSWD: ALL" >> "$ARCH_ROOT/etc/sudoers"
set +x
echo "$GPGKEY" | base64 -d | arch-chroot builder "gpg --import"
set -x
GPGKEY_ID=688E1D093C3638F588890D4450268311C7AD3F62
cat >> "$ARCH_ROOT/etc/makepkg.conf" <<- EOF
	PKGDEST="$PWD/repo"
	PACKAGER="DDoSolitary <DDoSolitary@gmail.com>"
	GPG_KEY="$GPGKEY_ID"
EOF
cat >> "$ARCH_ROOT/etc/pacman.conf" <<- EOF
	[archlinux-ddosolitary]
	Server = file://$PWD/repo
	SigLevel = Required
EOF
arch-chroot root "pacman-key --keyserver pgp.mit.edu -r '$GPGKEY_ID'"
arch-chroot root "pacman-key --lsign-key '$GPGKEY_ID'"
arch-chroot root "pacman -Sy"
patch "$ARCH_ROOT/usr/bin/makepkg" .travis/makepkg.patch

# Download PKGBUILDs from AUR
for i in $(cat aur-build-list); do
	curl -L "https://aur.archlinux.org/cgit/aur.git/snapshot/$i.tar.gz" | tar xz
done

# Resolve dependencies
TMP1="$(mktemp)"
TMP2="$(mktemp)"
find -path "*/PKGBUILD" | xargs -l dirname | xargs -l basename | sort > "$TMP1"
tsort build-deps > "$TMP2"
PKGLIST="$(cat "$TMP2") $(cat "$TMP2" | sort | comm -3 - "$TMP1")"

# Build packages
PKGEXT=$(source "$ARCH_ROOT/etc/makepkg.conf" && echo "$PKGEXT")
BUILD_ERR=0
for i in $PKGLIST; do
	pushd "$i"
	chmod -R 777 .
	set +e
	arch-chroot builder "CARCH=x86_64 makepkg -sr --skippgpcheck --sign --needed --noconfirm"
	if [ "$?" == "0" ]; then
		set -e
		for j in *"$PKGEXT"; do
			if [ "$j" == "*$PKGEXT" ]; then break; fi
			pushd ../repo
			arch-chroot builder "repo-add -n -R -s archlinux-ddosolitary.db.tar.gz '$j'"
			arch-chroot root "pacman -Sy"
			popd
		done
	else
		set -e
		BUILD_ERR=1
	fi
	popd
done

# Unmount the web server's filesystem
fusermount -u repo

exit "$BUILD_ERR"
