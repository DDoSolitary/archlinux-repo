declare -xA deps
deps=(
	[yaourt]="package-query"
	[ruby-travis]="ruby-backports ruby-gh ruby-highline-1.6 ruby-launchy ruby-pusher-client ruby-typhoeus-0.6"
	[ruby-gh]="ruby-backports ruby-net-http-persistent ruby-net-http-pipeline"
	[ruby-net-http-persistent]="ruby-connection_pool"
	[ruby-pusher-client]="ruby-json ruby-websocket"
	[ruby-typhoeus-0.6]="ruby-ethon"
	[i2p]="java-service-wrapper"
	[i2p-dev]="java-service-wrapper"
	[qemu-user-static]="glib2-static pcre-static"
	[pulseaudio-modules-bt-git]="libldac"
	[libselinux]="libsepol"
	[blueproximity]="bluez-utils-compat"
	[vmware-workstation]="vmware-keymaps uefitool-git"
	[gdm-plymouth]="plymouth"
	[plymouth-zfs]="plymouth"
	[plymouth-theme-arch-beat]="plymouth"
	[plymouth-theme-arch-breeze-git]="plymouth"
	[plymouth-theme-arch-charge]="plymouth"
	[plymouth-theme-arch-charge-big]="plymouth"
	[plymouth-theme-arch-charge-gdm]="plymouth"
	[plymouth-theme-arch-glow]="plymouth"
	[plymouth-theme-arch-logo]="plymouth"
	[plymouth-theme-arch-logo-gnomish]="plymouth"
	[plymouth-theme-arch-logo-new]="plymouth"
	[plymouth-theme-arch-solarized-git]="plymouth"
	[plymouth-theme-dark-arch]="plymouth"
	[plymouth-theme-gdm-arch]="plymouth"
	[plymouth-theme-minimal-dark-git]="plymouth"
	[plymouth-theme-monoarch]="plymouth"
	[plymouth-theme-paw-arch]="plymouth"
	[lib32-gst-plugins-bad]="lib32-aom lib32-bluez-libs lib32-chromaprint lib32-faac lib32-faad2 lib32-libbs2b lib32-libdc1394 lib32-libdca lib32-libde265 lib32-libdvdnav lib32-libdvdread lib32-libexif lib32-libfdk-aac lib32-libgme lib32-libkate lib32-liblrdf lib32-libmms lib32-libmpcdec lib32-libmpeg2 lib32-libnice lib32-libofa lib32-libsrtp lib32-lilv lib32-mjpegtools lib32-neon lib32-openexr lib32-openjpeg2 lib32-rtmpdump lib32-sbc lib32-spandsp lib32-srt lib32-webrtc-audio-processing lib32-wildmidi lib32-x265 lib32-zbar lib32-zvbi lib32-libtiger"
	[lib32-chromaprint]="lib32-ffmpeg"
	[lib32-libdvdnav]="lib32-libdvdread"
	[lib32-libdvdread]="lib32-libdvdcss"
	[lib32-libtiger]="lib32-libkate"
	[lib32-liblrdf]="lib32-raptor"
	[lib32-libmpcdec]="lib32-libcue lib32-libreplaygain"
	[lib32-libnice]="lib32-gupnp-igd"
	[lib32-libofa]="lib32-fftw"
	[lib32-lilv]="lib32-sratom"
	[lib32-openexr]="lib32-fltk"
	[lib32-x265]="lib32-numactl"
	[lib32-zbar]="lib32-imagemagick lib32-python2"
	[lib32-gupnp-igd]="lib32-gupnp"
	[lib32-gupnp]="lib32-gssdp"
	[lib32-sratom]="lib32-sord lib32-lv2"
	[lib32-sord]="lib32-serd"
	[lib32-imagemagick]="lib32-libheif lib32-liblqr lib32-libraqm lib32-libraw lib32-libwmf lib32-openexr lib32-openjpeg2 lib32-jbigkit"
	[lib32-libheif]="lib32-libde265 lib32-x265"
	[lib32-libraw]="lib32-jasper"
	[lib32-python2]="lib32-gdbm lib32-tk"
	[lib32-ffmpeg]="lib32-aom lib32-dav1d lib32-gsm lib32-lame lib32-libass lib32-libbluray lib32-libomxil-bellagio lib32-opencore-amr lib32-openjpeg2 lib32-x265 lib32-xvidcore lib32-x264"
	[lib32-dav1d]="lib32-libplacebo"
	[lib32-libplacebo]="lib32-glslang lib32-shaderc"
	[lib32-glslang]="lib32-spirv-tools"
	[lib32-shaderc]="lib32-glslang lib32-spirv-tools"
	[lib32-gst-plugins-ugly]="lib32-a52dec lib32-libcdio lib32-libdvdread lib32-libmpeg2 lib32-libsidplay lib32-opencore-amr lib32-x264"
	[protondb-tags]="python-vdf"
)
