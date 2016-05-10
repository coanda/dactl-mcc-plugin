dnl Process this file with autoconf to produce a configure script.
AC_PREREQ([2.64])
AC_INIT([dactl-usb1208fs], m4_esyscmd([build-aux/git-version-gen .tarball-version]))

AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_SRCDIR([src/dactl-usb1208fs-plugin.vala])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])

AC_PROG_CC
AM_PROG_CC_STDC
AM_PROG_VALAC([0.22.0])
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET
AC_HEADER_STDC

AC_SUBST(abs_top_builddir)
AC_SUBST(VERSION)

# Initialize automake
AM_INIT_AUTOMAKE([1.11.1 foreign no-dist-gzip dist-xz -Wno-portability])
AM_MAINTAINER_MODE([enable])

dnl Initialize libtool
dnl Disable the generation of static libraries
LT_PREREQ([2.2.6])
LT_INIT([dlopen disable-static])

dnl Enable silent rules is available
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

# GResource
AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)

AC_SET_DEFAULT_PATHS_SYSTEM

PREFIX=$prefix
AC_SUBST(PREFIX)

dnl Library checks
VALAFLAGS="--enable-deprecated --target-glib=2.38 $VALAFLAGS"
AC_SUBST(VALAFLAGS)

PLUGIN_MODULES="cld-0.3 dactl-core-0.3 dactl-ui-0.3 gtk+-3.0 clutter-1.0"
PLUGIN_MODULES_VALAFLAGS="--pkg cld-0.3 --pkg dactl-core-0.3 --pkg dactl-ui-0.3 --pkg gtk+-3.0 --pkg clutter-1.0"

PKG_CHECK_MODULES([PLUGIN_DEPS], [$PLUGIN_MODULES])
AC_SUBST(PLUGIN_MODULES_VALAFLAGS)

dnl Header checks
AC_CHECK_HEADERS(stdlib.h)
AC_CHECK_LIB(m, floor, PACKAGE_LIBS="$PACKAGE_LIBS -lm",)

dnl Build Options
AC_ARG_ENABLE(debug,
    AS_HELP_STRING([--enable-debug],[Enable debugging (default: disabled)]),,
        [enable_debug=no])
AS_IF([test "x$enable_debug" != "xno"],
      [AC_DEFINE(DEBUG, [1], ["Enable debugging support"])]
      [CFLAGS="$CFLAGS -O0 -g"]
      [DEBUG_VALAFLAGS="-g -D DEBUG"]
      [AS_IF([test "x$GCC" = xyes],
             [CC_CHECK_FLAG([-g])])])

AC_SUBST(DEBUG_VALAFLAGS)

dnl GOptions requires gettext for i18n
ALL_LINGUAS=""
GETTEXT_PACKAGE=dactl-usb1208fs
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE", [Gettext package.])

AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.40.0])

AC_SUBST([PLUGIN_LINKER_FLAGS],["-module -avoid-version -Wl,-z,defs"])
AC_SUBST([PLUGIN_DIR],[${libdir}/dactl-0.3/plugins])

dnl Configuration
AC_SUBST([pkgconfigdir])

AC_CONFIG_FILES([
    Makefile
    src/Makefile
    src/usb1208fs.plugin
    po/Makefile.in
])
AC_OUTPUT

dnl Generate build report
AC_MSG_NOTICE([

    $PACKAGE $VERSION
    ===========================

    Prefix:                         ${ac_default_prefix}
    Source code location:           ${srcdir}
    System configuration:           ${sysconfdir}
    Data directory:                 ${datadir}
    Plugin directory:               ${PLUGIN_DIR}
    Package directory:              ${pkgconfigdir}
    Compiler:                       ${CC}
    CFLAGS:                         ${CFLAGS}
    VALAFLAGS:                      ${VALAFLAGS}

    Debugging enabled:              ${enable_debug}

    $PACKAGE will be installed in ${PLUGIN_DIR}
])
