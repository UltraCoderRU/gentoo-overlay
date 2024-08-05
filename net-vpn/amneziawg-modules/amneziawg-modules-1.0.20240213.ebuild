# Copyright 2024 Kirill Kirilenko
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1

DESCRIPTION="Simple yet fast and modern VPN that utilizes state-of-the-art cryptography"
HOMEPAGE="https://github.com/amnezia-vpn/amneziawg-linux-kernel-module"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git"
else
	SRC_URI="https://github.com/amnezia-vpn/amneziawg-linux-kernel-module/archive/refs/tags/v${PV}.tar.gz"
	S="${WORKDIR}/amneziawg-linux-kernel-module-${PV}"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="debug"

CONFIG_CHECK="NET INET NET_UDP_TUNNEL CRYPTO_ALGAPI"

# On modern kernels AmneziaWG needs Wireguard sources from kernel to generate
# own sources from. On a typical Gentoo installation 'sys-kernel/*-sources'
# package contains needed kernel sources. But installations based on
# distribution kernel (sys-kernel/*-kernel) have no kernel sources installed.
# That is why this ebuild has a build dependency on gentoo-sources or vanilla-sources.
BDEPEND="|| ( sys-kernel/gentoo-sources sys-kernel/vanilla-sources )"

pkg_setup() {
	linux-mod-r1_pkg_setup
	if kernel_is -lt 3 10 0; then
		die "This version of ${PN} requires Linux >= 3.10."
	fi
}

src_prepare() {
	default

	if kernel_is -ge 5 6 0; then
		# We need to select a directory with kernel sources.
		# Usually, /usr/src/linux is the right choise, so we check it first.
		# If /usr/src/linux contains no sources (distribution kernel), we check
		# other subdirectories in /usr/src sorted by version in reverse order.
		echo "Searching for kernel sources..."
		dirs=$(find /usr/src -maxdepth 1 -name 'linux-*' -type d | sort --reverse --version-sort --field-separator=- --key=2,2)
		dirs="/usr/src/linux ${dirs}"
		for kernel_dir in ${dirs}; do
			[ -d "$kernel_dir" ] || continue
			if [[ -f ${kernel_dir}/drivers/net/wireguard/main.c ]]; then
				echo "- ${kernel_dir} -> found"
				KERNEL_SOURCES_DIR=${KERNEL_SOURCES_DIR:-${kernel_dir}}
			else
				echo "- ${kernel_dir} -> not found"
			fi
		done

		if [[ -d ${KERNEL_SOURCES_DIR} ]]; then
			einfo "Using kernel sources in ${KERNEL_SOURCES_DIR}"
		else
			die "Kernel sources not found, but required for building."
		fi

		ln -s ${KERNEL_SOURCES_DIR} src/kernel
		emake -C ${S}/src apply-patches
	fi
}

src_compile() {
	local modlist=( amneziawg=net:src::module )
	local modargs=(
		KERNELDIR=${KV_OUT_DIR}
	)
	use debug && modargs+=( CONFIG_AMNEZIAWG_DEBUG=y )
	linux-mod-r1_src_compile
}

src_install() {
	linux-mod-r1_src_install
}

pkg_postinst() {
	linux-mod-r1_pkg_postinst
	local old new
	if [[ $(uname -r) != "${KV_FULL}" ]]; then
		ewarn
		ewarn "You have just built AmneziaWG for kernel ${KV_FULL}, yet the currently running"
		ewarn "kernel is $(uname -r). If you intend to use this AmneziaWG module on the currently"
		ewarn "running machine, you will first need to reboot it into the kernel ${KV_FULL}, for"
		ewarn "which this module was built."
		ewarn
	elif [[ -f /sys/module/amneziawg/version ]] && \
			old="$(< /sys/module/amneziawg/version)" && \
			new="$(modinfo -F version "${ROOT}/lib/modules/${KV_FULL}/net/amneziawg.ko" 2>/dev/null)" && \
			[[ $old != "$new" ]]; then
		ewarn
		ewarn "You appear to have just upgraded AmneziaWG from version v$old to v$new."
		ewarn "However, the old version is still running on your system. In order to use the"
		ewarn "new version, you will need to remove the old module and load the new one. As"
		ewarn "root, you can accomplish this with the following commands:"
		ewarn
		ewarn "    # rmmod amneziawg"
		ewarn "    # modprobe amneziawg"
		ewarn
		ewarn "Do note that doing this will remove current AmneziaWG interfaces, so you may want"
		ewarn "to gracefully remove them yourself prior."
		ewarn
	fi
}
