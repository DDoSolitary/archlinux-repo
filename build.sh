#!/bin/bash -ex

export LANG=en_US.UTF-8
cd ~/src

gpg --keyserver hkps://keys.openpgp.org --refresh-keys
sudo pacman-key --keyserver hkps://keys.openpgp.org --refresh-keys DDoSolitary@gmail.com

# Mount the web server's filesystem
sshfs -o allow_root \
	ddosolitary@web.sourceforge.net:/home/project-web/archlinux-repo/htdocs/packages \
	~/repo
sudo pacman -Syu --noconfirm

# Download PKGBUILDs from AUR
for i in $(cat aur-build-list); do
	if [ ! -e ~/build/"$i" ]; then
		curl -fsSL "https://aur.archlinux.org/cgit/aur.git/snapshot/$i.tar.gz" | tar xzC ~/build
	fi
done

# Download public keys
curl -fsSL https://github.com/web-flow.gpg | gpg --import
for i in $(cat gpg-keyids); do
	set +e
	for j in $(seq 10); do
		gpg --keyserver keyserver.ubuntu.com --recv-keys "$i" \
			|| gpg --keyserver pool.sks-keyservers.net --recv-keys "$i" \
			&& break
		if [ "$j" == "10" ]; then exit 1; fi
		sleep 1
	done
	set -e
done

# Resolve dependencies
tmp1="$(mktemp)"
tmp2="$(mktemp)"
tmp3="$(mktemp)"
source build-deps.sh
for i in ${!deps[@]}; do
	for j in ${deps["$i"]}; do
		echo "$j" "$i" >> "$tmp1"
	done
done
cat "$tmp1" | tsort  > "$tmp2"
cat aur-build-list | sort > "$tmp3"
pkglist="$(cat "$tmp2") $(cat "$tmp2" | sort | comm -3 - "$tmp3")"

# Build packages
build_err=0
tmp_res="$(mktemp)"
for i in $pkglist; do
	pushd ~/build/"$i"
	patch_path=~/src/patches/"$i".patch
	if [ -f "$patch_path" ]; then
		if ! patch -Np1 -i "$patch_path"; then
			echo "$i patch failed" >> "$tmp_res"
			build_err=1
			popd
			continue
		fi
	fi
	set +e
	CARCH=x86_64 makepkg -sr --sign --needed --noconfirm
	makepkg_err=$?
	set -e
	sudo rm -rf src pkg
	echo "$i $makepkg_err" >> "$tmp_res"
	case $makepkg_err in
	0)
		for j in $(makepkg --packagelist); do
			pushd ~/repo
			repo-add -n -R -s archlinux-ddosolitary.db.tar.gz "$j"
			popd
		done
		sudo pacman -Sy
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
fusermount3 -u ~/repo
cat "$tmp_res"
exit $build_err
