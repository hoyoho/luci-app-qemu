require "luci.http"
require "luci.sys"
require "nixio.fs"
require "luci.dispatcher"
require "luci.model.uci"

m = Map("qemu", translate("QEMU Controller Devices"))
m.pageaction = true

-- 获取所有虚拟机名称
local vm_list = {}
local uci = require("luci.model.uci").cursor()
uci:foreach("qemu", "vm", function(s)
    table.insert(vm_list, {name = s.name or s['.name'], title = s.name or s['.name']})
end)

-- USB Controllers
s_usb = m:section(TypedSection, "controller_usb", translate("USB Controllers"), translate("Manage USB controller devices"))
s_usb.anonymous = true
s_usb.addremove = true
s_usb.template = "cbi/tblsection"

-- 过滤USB控制器
s_usb.filter = function(self, section)
    return true
end

-- 虚拟机选择
vm_usb = s_usb:option(ListValue, "vm", translate("VM"))
vm_usb:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    vm_usb:value(vm.name, vm.title)
end

-- USB Type
type_usb = s_usb:option(ListValue, "type", translate("USB Type"))
type_usb:value("qemu-xhci", translate("QEMU XHCI"))
type_usb:value("nec-usb-xhci", translate("NEC XHCI"))
type_usb:value("ich9-usb-ehci1", translate("ICH9 EHCI 1"))
type_usb:value("ich9-usb-ehci2", translate("ICH9 EHCI 2"))
type_usb:value("usb-ehci", translate("USB EHCI"))
type_usb:value("ich9-usb-uhci1", translate("ICH9 UHCI 1"))
type_usb:value("ich9-usb-uhci2", translate("ICH9 UHCI 2"))
type_usb:value("ich9-usb-uhci3", translate("ICH9 UHCI 3"))
type_usb:value("ich9-usb-uhci4", translate("ICH9 UHCI 4"))
type_usb:value("ich9-usb-uhci5", translate("ICH9 UHCI 5"))
type_usb:value("ich9-usb-uhci6", translate("ICH9 UHCI 6"))
type_usb:value("piix3-usb-uhci", translate("PIIX3 UHCI"))
type_usb:value("piix4-usb-uhci", translate("PIIX4 UHCI"))
type_usb:value("pci-ohci", translate("Apple USB Controller"))
type_usb.default = "qemu-xhci"

-- SCSI Controllers
s_scsi = m:section(TypedSection, "controller_scsi", translate("SCSI Controllers"), translate("Manage SCSI controller devices"))
s_scsi.anonymous = true
s_scsi.addremove = true
s_scsi.template = "cbi/tblsection"

-- 过滤SCSI控制器
s_scsi.filter = function(self, section)
    return true
end

-- 虚拟机选择
vm_scsi = s_scsi:option(ListValue, "vm", translate("VM"))
vm_scsi:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    vm_scsi:value(vm.name, vm.title)
end

-- SCSI Type
type_scsi = s_scsi:option(ListValue, "type", translate("SCSI Type"))
type_scsi:value("virtio-scsi", translate("VirtIO SCSI"))
type_scsi:value("lsi53c895a", translate("LSI 53C895A"))
type_scsi:value("megaraid", translate("MegaRAID"))
type_scsi:value("mptsas1068", translate("MPTSAS 1068"))
type_scsi.default = "virtio-scsi"

-- VirtIO Serial
s_virtio = m:section(TypedSection, "controller_virtio_serial", translate("VirtIO Serial"), translate("Manage VirtIO serial devices"))
s_virtio.anonymous = true
s_virtio.addremove = true
s_virtio.template = "cbi/tblsection"

-- 过滤VirtIO Serial
s_virtio.filter = function(self, section)
    return true
end

-- 虚拟机选择
vm_virtio = s_virtio:option(ListValue, "vm", translate("VM"))
vm_virtio:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    vm_virtio:value(vm.name, vm.title)
end

-- Serial Type
type_virtio = s_virtio:option(ListValue, "type", translate("Serial Type"))
type_virtio:value("virtio-serial", translate("VirtIO Serial"))
type_virtio.default = "virtio-serial"

-- CCID Controllers
s_ccid = m:section(TypedSection, "controller_ccid", translate("CCID Controllers"), translate("Manage CCID smart card devices"))
s_ccid.anonymous = true
s_ccid.addremove = true
s_ccid.template = "cbi/tblsection"

-- 过滤CCID控制器
s_ccid.filter = function(self, section)
    return true
end

-- 虚拟机选择
vm_ccid = s_ccid:option(ListValue, "vm", translate("VM"))
vm_ccid:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    vm_ccid:value(vm.name, vm.title)
end

-- CCID Type
type_ccid = s_ccid:option(ListValue, "type", translate("CCID Type"))
type_ccid:value("usb-ccid", translate("USB CCID"))
type_ccid.default = "usb-ccid"

return m