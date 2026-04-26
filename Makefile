include $(TOPDIR)/rules.mk

LUCI_TITLE:=QEMU Virtual Machine Manager
LUCI_DEPENDS:=+kmod-tun +qemu-bridge-helper +qemu-x86_64-softmmu +qemu-img +edk2-ovmf +qemu-firmware-seabios +kmod-kvm-amd +kmod-kvm-intel
LUCI_PKGARCH:=all

PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage