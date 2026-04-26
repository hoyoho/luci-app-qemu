local m, s, o

m = Map("qemu", translate("QEMU Interface Devices"))

-- 获取所有虚拟机名称
local vm_list = {}
local uci = require("luci.model.uci").cursor()
uci:foreach("qemu", "vm", function(s)
    table.insert(vm_list, {name = s.name or s['.name'], title = s.name or s['.name']})
end)

-- File Interface
s_file = m:section(TypedSection, "interface_file", translate("File Interface"), translate("Output to file"))
s_file.addremove = true
s_file.anonymous = true
s_file.template = "cbi/tblsection"

-- 虚拟机选择
o = s_file:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- 类型
o = s_file:option(ListValue, "type", translate("Type"))
o:value("serial", translate("Serial"))
o:value("parallel", translate("Parallel"))
o.default = "serial"

-- Path
o = s_file:option(Value, "path", translate("Path"))
o.placeholder = translate("Enter path")

-- Pseudo TTY Interface
s_pty = m:section(TypedSection, "interface_pty", translate("Pseudo TTY Interface"), translate("Pseudo TTY"))
s_pty.addremove = true
s_pty.anonymous = true
s_pty.template = "cbi/tblsection"

-- 虚拟机选择
o = s_pty:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- 类型
o = s_pty:option(ListValue, "type", translate("Type"))
o:value("serial", translate("Serial"))
o:value("parallel", translate("Parallel"))
o.default = "serial"

-- UNIX Socket Interface
s_unix = m:section(TypedSection, "interface_unix", translate("UNIX Socket Interface"), translate("UNIX socket"))
s_unix.addremove = true
s_unix.anonymous = true
s_unix.template = "cbi/tblsection"

-- 虚拟机选择
o = s_unix:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- 类型
o = s_unix:option(ListValue, "type", translate("Type"))
o:value("serial", translate("Serial"))
o:value("parallel", translate("Parallel"))
o.default = "serial"

-- Path
o = s_unix:option(Value, "path", translate("Path"))
o.placeholder = translate("Enter path")

-- 控制台设备
s = m:section(TypedSection, "console", translate("Console"))
s.addremove = true
s.anonymous = true
s.template = "cbi/tblsection"

-- 虚拟机选择
o = s:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- 类型（仅Virtio）
o = s:option(ListValue, "type", translate("Type"))
o:value("virtio", translate("Virtio"))
o.default = "virtio"

return m