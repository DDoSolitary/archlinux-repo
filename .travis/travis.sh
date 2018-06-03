#!/bin/bash
set -ex

# Install an Arch Linux chroot environment
pushd /tmp
download_path=https://mirrors.kernel.org/archlinux/iso/latest
rootfs_file=$(curl -L $download_path/md5sums.txt | awk '$2 ~ /^archlinux-bootstrap/ { print $2 }')
curl -L $download_path/$rootfs_file | tar xz
mount --bind root.x86_64 root.x86_64
cd root.x86_64
cp /etc/resolv.conf etc/
mount -t proc /proc proc
mount --rbind /sys sys
mount --rbind /dev dev
mount --rbind /run run
popd

arch_root=/tmp/root.x86_64
arch_pwd="$arch_root$PWD"

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
mkdir -p "$arch_pwd"
mount --rbind . "$arch_pwd"
function arch-chroot {
	chroot "$arch_root" su -l $1 /bin/bash -c "cd '$PWD'; $2"
}
arch-chroot root "pacman-key --init && pacman-key --populate archlinux"
sed -i "s/pool\.sks-keyservers\.net/ipv4.\0/" "$arch_root/etc/pacman.d/gnupg/gpg.conf"
echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' > "$arch_root/etc/pacman.d/mirrorlist"
arch-chroot root "pacman -Syu --needed --noconfirm base base-devel"
echo "LANG=en_US.UTF-8" > "$arch_root/etc/locale.conf"
echo "en_US.UTF-8 UTF-8" > "$arch_root/etc/locale.gen"
arch-chroot root locale-gen

# Prepare for building packages
arch-chroot root "useradd builder -m"
echo "builder ALL=(ALL) NOPASSWD: ALL" >> "$arch_root/etc/sudoers"
builder_uid=$(arch-chroot builder "id -u")
builder_gid=$(arch-chroot builder "id -g")
set +x
echo "$GPGKEY" | base64 -d | arch-chroot builder "gpg --import"
set -x
GPGKEY_ID=688E1D093C3638F588890D4450268311C7AD3F62
cat >> "$arch_root/etc/makepkg.conf" <<- EOF
	PKGDEST="$PWD/repo"
	PACKAGER="DDoSolitary <DDoSolitary@gmail.com>"
	GPG_KEY="$GPGKEY_ID"
EOF
cat >> "$arch_root/etc/pacman.conf" <<- EOF
	[archlinux-ddosolitary]
	Server = file://$PWD/repo
	SigLevel = Required
EOF
arch-chroot root "pacman-key --keyserver ipv4.pool.sks-keyservers.net -r '$GPGKEY_ID'"
arch-chroot root "pacman-key --lsign-key '$GPGKEY_ID'"
arch-chroot root "pacman -Sy"

# Download PKGBUILDs from AUR
for i in $(cat aur-build-list); do
	curl -L "https://aur.archlinux.org/cgit/aur.git/snapshot/$i.tar.gz" | tar xz
done

# Download public keys
for i in $(cat gpg-keyids); do
	arch-chroot builder "gpg --keyserver ipv4.pool.sks-keyservers.net --recv-keys '$i'"
done

# Resolve dependencies
tmp1="$(mktemp)"
tmp2="$(mktemp)"
source build-deps.sh
for i in ${!deps[@]}; do
	for j in ${deps["$i"]}; do
		echo "$j" "$i" >> "$tmp1"
	done
done
cat "$tmp1" | tsort  > "$tmp2"
find -path "*/PKGBUILD" | xargs -l dirname | xargs -l basename | sort > "$tmp1"
pkglist="$(cat "$tmp2") $(cat "$tmp2" | sort | comm -3 - "$tmp1")"

# Build packages
build_err=0
tmp_res="$(mktemp)"
for i in $pkglist; do
	pushd "$i"
	chown $builder_uid:$builder_gid .
	set +e
	arch-chroot builder "CARCH=x86_64 makepkg -sr --sign --needed --noconfirm"
	makepkg_err=$?
	set -e
	echo "$i $makepkg_err" >> "$tmp_res"
	case $makepkg_err in
	0)
		pkgfile="$(arch-chroot builder "makepkg --packagelist")"
		pushd ../repo
		arch-chroot builder "repo-add -n -R -s archlinux-ddosolitary.db.tar.gz $pkgfile"
		arch-chroot root "pacman -Sy"
		popd
		;;
	13)
		;;
	*)
		build_err=1
		;;
	esac
	popd
done

# Exit
fusermount -u repo
cat "$tmp_res"
exit $build_err
