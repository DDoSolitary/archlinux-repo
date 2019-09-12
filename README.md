# archlinux-repo

![Build Status](https://github.com/DDoSolitary/archlinux-repo/workflows/.github/workflows/build.yml/badge.svg)

This is an unofficial repository for Arch Linux.

# How to use

To use the pre-built packages, follow these steps:

1. Trust my public key.

```
pacman-key --kerserver hkps://keys.openpgp.org -r 688E1D093C3638F588890D4450268311C7AD3F62
pacman-key --lsign-key 688E1D093C3638F588890D4450268311C7AD3F62
```

2. Add these lines to `/etc/pacman.conf`

```
[archlinux-ddosolitary]
Server = https://archlinux-repo.sourceforge.io/packages
SigLevel = Required
```

3. Update your local index.

```
pacman -Sy
```

4. **Enjoy it!**

# Limitations

- Downloading may be slow in some regions (e.g. China).
