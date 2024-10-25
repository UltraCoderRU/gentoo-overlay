# Copyright 2024 Kirill Kirilenko
# Distributed under the terms of the GNU General Public License v3

EAPI=8

inherit unpacker cmake xdg

DESCRIPTION="Remote GUI for transmission-daemon"
HOMEPAGE="https://github.com/equeim/tremotesf2"
SRC_URI="https://github.com/equeim/tremotesf2/releases/download/${PV}/${P}.tar.zst"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="qt6 test"
RESTRICT="!test? ( test )"

readonly _shared_libraries="
    !qt6? (
        dev-qt/qtcore:5
        dev-qt/qtnetwork:5[ssl]
        dev-qt/qtgui:5
        dev-qt/qtwidgets:5
        dev-qt/qtdbus:5
        kde-frameworks/kwidgetsaddons:5
        kde-frameworks/kwindowsystem:5
    )
    qt6? (
        dev-qt/qtbase:6[dbus,gui,network,ssl,widgets]
        kde-frameworks/kwidgetsaddons:6
        kde-frameworks/kwindowsystem:6
    )
    dev-libs/libfmt
    net-libs/libpsl
"

BDEPEND="
    !qt6? (
        dev-qt/qtcore:5
        dev-qt/qtdbus:5
    )
    qt6? (
        dev-qt/qtbase:6[dbus]
    )
    sys-devel/gettext
    virtual/pkgconfig
    app-arch/zstd
"

DEPEND="
    ${_shared_libraries}
    !qt6? ( dev-qt/qtconcurrent:5 )
    qt6? ( dev-qt/qtbase:6[concurrent] )
    >=dev-libs/cxxopts-3.2.1
    test? (
        !qt6? ( dev-qt/qttest:5 )
        dev-cpp/cpp-httplib[ssl]
    )
"

RDEPEND="
    ${_shared_libraries}
    !qt6? ( <kde-plasma/kwayland-integration-6.0.0 )
    qt6? ( >=kde-plasma/kwayland-integration-6.0.0 )
"

src_configure() {
    local mycmakeargs=("-DTREMOTESF_QT6=$(usex qt6)" "-DBUILD_TESTING=$(usex test)")
    cmake_src_configure
}
