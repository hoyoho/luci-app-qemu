local m, s, o

m = Map("qemu", translate("QEMU Virtio VSOCK Devices"))

-- 获取所有虚拟机名称
local vm_list = {}
local uci = require("luci.model.uci").cursor()
uci:foreach("qemu", "vm", function(s)
    table.insert(vm_list, {name = s.name or s['.name'], title = s.name or s['.name']})
end)

-- VSOCK Auto CID
s_vsock_auto = m:section(TypedSection, "vsock_auto", translate("VSOCK - Auto CID"), translate("Auto assign Guest CID"))
s_vsock_auto.addremove = true
s_vsock_auto.anonymous = true
s_vsock_auto.template = "cbi/tblsection"

-- 虚拟机选择
o = s_vsock_auto:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- VSOCK Manual CID
s_vsock_manual = m:section(TypedSection, "vsock_manual", translate("VSOCK - Manual CID"), translate("Manually specify Guest CID"))
s_vsock_manual.addremove = true
s_vsock_manual.anonymous = true
s_vsock_manual.template = "cbi/tblsection"

-- 虚拟机选择
o = s_vsock_manual:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- Guest CID
o = s_vsock_manual:option(Value, "guest_cid", translate("Guest CID"))
o.default = "3"
o.datatype = "uinteger"

return m