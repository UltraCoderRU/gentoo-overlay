# Copyright 2026 Kirill Kirilenko

EAPI=8

inherit desktop unpacker xdg

DESCRIPTION="Discover, download, and run LLMs locally
  Use the chat UI or local server to experiment and develop with local LLMs."
HOMEPAGE="https://lmstudio.ai"
SRC_URI="https://installers.lmstudio.ai/linux/x64/${PV}-1/LM-Studio-${PV}-1-x64.deb"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip"

IUSE="cuda vulkan"

RDEPEND="
    virtual/libcrypt
"
IDEPEND="
	dev-util/desktop-file-utils
	dev-util/gtk-update-icon-cache
"

REQUIRES_EXCLUDE="\$ORIGIN/../lib/libpython3.11.so.1.0"
QA_DESKTOP_FILE="usr/share/applications/lm-studio.desktop"

src_install() {
	if ! use cuda; then
	    rm -r "opt/LM Studio/resources/app/.webpack/bin/extensions/backends/llama.cpp-linux-x86_64-nvidia-cuda-avx2-2.5.0"
		rm -r "opt/LM Studio/resources/app/.webpack/bin/extensions/backends/vendor/linux-llama-cuda-vendor-v1"
	fi

	if ! use vulkan; then
	    rm -r "opt/LM Studio/resources/app/.webpack/bin/extensions/backends/llama.cpp-linux-x86_64-vulkan-avx2-2.5.0"
		rm -r "opt/LM Studio/resources/app/.webpack/bin/extensions/backends/vendor/linux-llama-vulkan-vendor-v1"
	fi

	insinto /opt
	doins -r "opt/LM Studio"

	fperms 755 "/opt/LM Studio/resources/app/.webpack/bin/extensions/backends/vendor/_amphibian/cpython3.11-linux-x86@3/bin/python3.11"
    fperms 755 "/opt/LM Studio/resources/app/.webpack/bin/extensions/frameworks/lmlink-connector-linux-x86_64-avx2-0.0.5/lmlink-connector"
    fperms 755 "/opt/LM Studio/resources/app/.webpack/bin/esbuild"
    fperms 755 "/opt/LM Studio/resources/app/.webpack/bin/deno"
    fperms 755 "/opt/LM Studio/resources/app/.webpack/bin/node"
    fperms 755 "/opt/LM Studio/resources/app/.webpack/lms"
    fperms 4755 "/opt/LM Studio/chrome-sandbox"
    fperms 755 "/opt/LM Studio/chrome_crashpad_handler"
    fperms 755 "/opt/LM Studio/lm-studio"
    find . -type f \( -name "*.so" -o -name "*.so.*" \) -printf "/%P\0" | xargs -0 fperms 755

	dosym "/opt/LM Studio/lm-studio" usr/bin/lm-studio
	dosym "/opt/LM Studio/resources/app/.webpack/lms" usr/bin/lms
	doicon -s scalable usr/share/icons/hicolor/0x0/apps/lm-studio.png
	domenu usr/share/applications/lm-studio.desktop
}

pkg_postinst() {
    xdg_pkg_postinst
}

pkg_postrm() {
	xdg_pkg_postrm
}
