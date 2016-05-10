include $(top_srcdir)/common.am

plugin_LTLIBRARIES = libdactl-usb1208fs.la
plugin_DATA = usb1208fs.plugin

gresource_file = usb1208fs.gresource.xml
resource_files = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies $(gresource_file))
resources.c: $(gresource_file) $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) --target=$@ --sourcedir=. --generate-source $<

BUILT_SOURCES = resources.c

libdactl_usb1208fs_la_SOURCES = \
	$(BUILT_SOURCES) \
	dactl-usb1208fs-plugin.vala \
	dactl-usb1208fs-factory.vala \
	dactl-usb1208fs-control.vala

libdactl_usb1208fs_la_VALAFLAGS = \
	$(VALAFLAGS) \
	--gresources $(gresource_file) \
	--vapidir=$(srcdir) \
	$(PLUGIN_MODULES_VALAFLAGS)

libdactl_usb1208fs_la_CFLAGS = \
	--include config.h \
	-DG_LOG_DOMAIN='"USB1208FS"' \
	$(PLUGIN_DEPS_CFLAGS)

libdactl_usb1208fs_la_LIBADD = \
	$(PLUGIN_DEPS_LIBS)

libdactl_usb1208fs_la_LDFLAGS = \
	$(PLUGIN_LINKER_FLAGS)

MAINTAINERCLEANFILES += $(libdactl_usb1208fs_la_SOURCES:.vala=.c)

EXTRA_DIST = \
	$(gresource_file) \
	$(resource_files) \
	usb1208fs.plugin.in
