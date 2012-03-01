# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/gobject-introspection/gobject-introspection-0.10.8.ebuild,v 1.10 2011/05/02 04:39:55 jer Exp $

EAPI="4"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"
PYTHON_DEPEND="2:2.5"

inherit python gnome2
if [[ ${PV} = 9999 ]]; then
	inherit gnome2-live
fi

DESCRIPTION="Introspection infrastructure for generating gobject library bindings for various languages"
HOMEPAGE="http://live.gnome.org/GObjectIntrospection/"

LICENSE="LGPL-2 GPL-2"
SLOT="0"
if [[ ${PV} = 9999 ]]; then
	KEYWORDS=""
else
	KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
fi

IUSE="doc test"

RDEPEND=">=dev-libs/glib-2.29.7:2
	virtual/libffi"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	sys-devel/bison
	sys-devel/flex
	doc? ( >=dev-util/gtk-doc-1.15 )
	test? ( x11-libs/cairo )"
# PDEPEND to avoid circular dependencies, bug #391213
PDEPEND="x11-libs/cairo[glib]"

pkg_setup() {
	DOCS="AUTHORS CONTRIBUTORS ChangeLog NEWS README TODO"
	G2CONF="${G2CONF}
		--disable-static
		YACC=$(type -p yacc)
		$(use_enable test tests)"

	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	# FIXME: Parallel compilation failure with USE=doc
	use doc && MAKEOPTS="-j1"

	# https://bugzilla.gnome.org/show_bug.cgi?id=659824
	sed -i -e '/^TAGS/s/[{}]//g' "${S}/giscanner/docbookdescription.py" || die

	gnome2_src_prepare

	# Don't pre-compile .py
	echo > py-compile
	echo > build-aux/py-compile

	gi_skip_tests=
	if ! has_version "x11-libs/cairo[glib]"; then
		# Bug #391213: enable cairo-gobject support even if it's not installed
		# We only PDEPEND on cairo to avoid circular dependencies
		export CAIRO_LIBS="-lcairo"
		export CAIRO_CFLAGS="-I${EPREFIX}/usr/include/cairo"
		export CAIRO_GOBJECT_LIBS="-lcairo-gobject"
		export CAIRO_GOBJECT_CFLAGS="-I${EPREFIX}/usr/include/cairo"
		if use test; then
			G2CONF="${G2CONF} --disable-tests"
			gi_skip_tests=yes
			ewarn "Tests will be skipped because x11-libs/cairo[glib] is not present"
			ewarn "on your system. Consider installing it to get tests to run."
		fi
	fi
}

src_test() {
	[[ -z ${gi_skip_tests} ]] && default
}

src_install() {
	gnome2_src_install
	python_convert_shebangs 2 "${ED}"usr/bin/g-ir-{annotation-tool,doc-tool,scanner}
}

pkg_postinst() {
	python_mod_optimize /usr/$(get_libdir)/${PN}/giscanner
	python_need_rebuild
}

pkg_postrm() {
	python_mod_cleanup /usr/lib*/${PN}/giscanner
}