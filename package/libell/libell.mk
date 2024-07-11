#
# Copyright (C) 2024 Arınç ÜNAL <arinc.unal@arinc9.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

LIBELL_VERSION = 0.66
LIBELL_SOURCE = ell-$(LIBELL_VERSION).tar.xz
LIBELL_SITE = https://cdn.kernel.org/pub/linux/libs/ell
LIBELL_INSTALL_STAGING = YES

$(eval $(autotools-package))
