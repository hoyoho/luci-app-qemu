include $(TOPDIR)/rules.mk

LUCI_TITLE:=QEMU Virtual Machine Manager
LUCI_PKGARCH:=all

PKG_VERSION:=1.1
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-app-qemu/install
	$(INSTALL_DIR) $(1)/usr/lib/qemu
	$(INSTALL_BIN) ./root/usr/lib/qemu/actions $(1)/usr/lib/qemu/
	chmod +x $(1)/usr/lib/qemu/actions
endef

# call BuildPackage
