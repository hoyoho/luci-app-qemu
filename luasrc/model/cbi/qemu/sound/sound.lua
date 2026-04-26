local m, s, o

m = Map("qemu", translate("QEMU Sound Devices"))

-- 获取所有虚拟机名称
local vm_list = {}
local uci = require("luci.model.uci").cursor()
uci:foreach("qemu", "vm", function(s)
    table.insert(vm_list, {name = s.name or s['.name'], title = s.name or s['.name']})
end)

-- 声音设备列表部分
s = m:section(TypedSection, "sound", translate("Sound Devices"))
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
o:value("ac97", translate("AC97"))
o:value("hdaich6", translate("HDA (ICH6)"))
o:value("hdaich9", translate("HDA (ICH9)"))
o.default = "ac97"

return m