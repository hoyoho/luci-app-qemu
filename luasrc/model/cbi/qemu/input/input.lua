local m, s, o

m = Map("qemu", translate("QEMU Input Management"))
m.pageaction = true

-- 获取所有虚拟机名称
local vm_list = {}
local uci = require("luci.model.uci").cursor()
uci:foreach("qemu", "vm", function(s)
    table.insert(vm_list, {name = s.name or s['.name'], title = s.name or s['.name']})
end)

-- 输入设备列表部分
s = m:section(TypedSection, "input", translate("Input Devices"))
s.addremove = true
s.anonymous = true
s.template = "cbi/tblsection"

-- 虚拟机选择
o = s:option(ListValue, "vm", translate("VM Reference"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- 类型
o = s:option(ListValue, "type", translate("Type"))
o:value("usb-mouse", translate("USB Mouse"))
o:value("usb-tablet", translate("USB Tablet"))
o:value("virtio-keyboard-pci", translate("VirtIO Keyboard"))
o:value("virtio-mouse-pci", translate("VirtIO Mouse"))
o:value("virtio-tablet-pci", translate("VirtIO Tablet"))
o.default = "usb-tablet"

return m
