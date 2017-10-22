# archlinux-repo

[![Build Status](https://travis-ci.org/DDoSolitary/archlinux-repo.svg)](https://travis-ci.org/DDoSolitary/archlinux-repo)

This is an unofficial repository for Arch Linux.

# How to use

To use the pre-built packages, follow these steps:

1. Trust my public key.

```
pacman-key -r 688E1D093C3638F588890D4450268311C7AD3F62
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

- No CDN, downloading may be slow in some regions (e.g. China).