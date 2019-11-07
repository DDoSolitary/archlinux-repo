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
)
