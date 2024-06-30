################################################################################
#
# mdio-tools
#
################################################################################

MDIO_TOOLS_VERSION = 1.2.0
MDIO_TOOLS_SITE = https://github.com/wkz/mdio-tools/releases/download/$(MDIO_TOOLS_VERSION)
MDIO_TOOLS_LICENSE = GPL-2.0
MDIO_TOOLS_LICENSE_FILES = COPYING
MDIO_TOOLS_DEPENDENCIES = host-pkgconf libmnl

$(eval $(autotools-package))
