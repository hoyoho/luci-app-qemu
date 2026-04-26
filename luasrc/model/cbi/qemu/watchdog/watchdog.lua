local m, s, o

m = Map("qemu", translate("QEMU Watchdog Devices"))

-- 获取所有虚拟机名称
local vm_list = {}
local uci = require("luci.model.uci").cursor()
uci:foreach("qemu", "vm", function(s)
    table.insert(vm_list, {name = s.name or s['.name'], title = s.name or s['.name']})
end)

-- 看门狗设备列表部分
s = m:section(TypedSection, "watchdog", translate("Watchdog Devices"))
s.addremove = true
s.anonymous = true
s.template = "cbi/tblsection"

-- 虚拟机选择
o = s:option(ListValue, "vm", translate("VM Reference"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- 设备类型
o = s:option(ListValue, "device", translate("Device Type"))
o:value("diag288", translate("DIAG288"))
o:value("i6300esb", translate("i6300ESB"))
o:value("ib700", translate("IB700"))
o.default = "i6300esb"



return m