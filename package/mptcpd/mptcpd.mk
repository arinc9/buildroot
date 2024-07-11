#
# Copyright (C) 2024 Arınç ÜNAL <arinc.unal@arinc9.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

MPTCPD_VERSION = v0.12
MPTCPD_SITE = https://github.com/multipath-tcp/mptcpd
MPTCPD_SITE_METHOD = git
MPTCPD_INSTALL_STAGING = YES
MPTCPD_DEPENDENCIES = host-autoconf-archive host-pkgconf libell
MPTCPD_AUTORECONF = YES
MPTCPD_AUTORECONF_OPTS = --include=$(HOST_DIR)/share/autoconf-archive

MPTCPD_CONF_OPTS += \
	--disable-doxygen-doc \
	--disable-logging \
	--with-kernel=upstream

MPTCPD_CFLAGS += -Wno-unused-result -Wno-format-nonliteral

$(eval $(autotools-package))
