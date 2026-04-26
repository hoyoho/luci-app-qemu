local m, s, o

m = Map("qemu", translate("QEMU Channel Devices"))

-- 获取所有虚拟机名称
local vm_list = {}
local uci = require("luci.model.uci").cursor()
uci:foreach("qemu", "vm", function(s)
    table.insert(vm_list, {name = s.name or s['.name'], title = s.name or s['.name']})
end)

-- File Channel
s_file = m:section(TypedSection, "channel_file", translate("File Channels"), translate("Output to a file"))
s_file.addremove = true
s_file.anonymous = true
s_file.template = "cbi/tblsection"

-- 虚拟机选择
o = s_file:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- Name
o = s_file:option(ListValue, "name", translate("Name"))
o:value("com.redhat.spice.0", translate("com.redhat.spice.0"))
o:value("org.libguestfs.channel.0", translate("org.libguestfs.channel.0"))
o:value("org.qemu.guest_agent.0", translate("org.qemu.guest_agent.0"))
o:value("org.spice-space.webdav.0", translate("org.spice-space.webdav.0"))
o.default = "com.redhat.spice.0"

-- Path
o = s_file:option(Value, "path", translate("Path"))
o.placeholder = translate("Enter path")

-- Pseudo TTY Channel
s_pty = m:section(TypedSection, "channel_pty", translate("Pseudo TTY Channels"), translate("Pseudo TTY"))
s_pty.addremove = true
s_pty.anonymous = true
s_pty.template = "cbi/tblsection"

-- 虚拟机选择
o = s_pty:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- Name
o = s_pty:option(ListValue, "name", translate("Name"))
o:value("com.redhat.spice.0", translate("com.redhat.spice.0"))
o:value("org.libguestfs.channel.0", translate("org.libguestfs.channel.0"))
o:value("org.qemu.guest_agent.0", translate("org.qemu.guest_agent.0"))
o:value("org.spice-space.webdav.0", translate("org.spice-space.webdav.0"))
o.default = "com.redhat.spice.0"

-- Spice Agent Channel
s_spicevmc = m:section(TypedSection, "channel_spicevmc", translate("Spice Agent Channels"), translate("Spice agent"))
s_spicevmc.addremove = true
s_spicevmc.anonymous = true
s_spicevmc.template = "cbi/tblsection"

-- 虚拟机选择
o = s_spicevmc:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- Name
o = s_spicevmc:option(ListValue, "name", translate("Name"))
o:value("com.redhat.spice.0", translate("com.redhat.spice.0"))
o:value("org.libguestfs.channel.0", translate("org.libguestfs.channel.0"))
o:value("org.qemu.guest_agent.0", translate("org.qemu.guest_agent.0"))
o:value("org.spice-space.webdav.0", translate("org.spice-space.webdav.0"))
o.default = "com.redhat.spice.0"

-- Spice Port Channel
s_spiceport = m:section(TypedSection, "channel_spiceport", translate("Spice Port Channels"), translate("Spice port"))
s_spiceport.addremove = true
s_spiceport.anonymous = true
s_spiceport.template = "cbi/tblsection"

-- 虚拟机选择
o = s_spiceport:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- Name
o = s_spiceport:option(ListValue, "name", translate("Name"))
o:value("com.redhat.spice.0", translate("com.redhat.spice.0"))
o:value("org.libguestfs.channel.0", translate("org.libguestfs.channel.0"))
o:value("org.qemu.guest_agent.0", translate("org.qemu.guest_agent.0"))
o:value("org.spice-space.webdav.0", translate("org.spice-space.webdav.0"))
o.default = "com.redhat.spice.0"

-- Channel
o = s_spiceport:option(Value, "channel", translate("Channel"))
o.default = "org.spice-space.webdav.0"
o.placeholder = translate("Enter channel")

-- UNIX Socket Channel - Auto Socket
s_unix_auto = m:section(TypedSection, "channel_unix_auto", translate("UNIX Socket - Auto"), translate("Auto generate socket path"))
s_unix_auto.addremove = true
s_unix_auto.anonymous = true
s_unix_auto.template = "cbi/tblsection"

-- 虚拟机选择
o = s_unix_auto:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- Name
o = s_unix_auto:option(ListValue, "name", translate("Name"))
o:value("com.redhat.spice.0", translate("com.redhat.spice.0"))
o:value("org.libguestfs.channel.0", translate("org.libguestfs.channel.0"))
o:value("org.qemu.guest_agent.0", translate("org.qemu.guest_agent.0"))
o:value("org.spice-space.webdav.0", translate("org.spice-space.webdav.0"))
o.default = "com.redhat.spice.0"

-- UNIX Socket Channel - Manual Path
s_unix_manual = m:section(TypedSection, "channel_unix_manual", translate("UNIX Socket - Manual"), translate("Manually specify socket path"))
s_unix_manual.addremove = true
s_unix_manual.anonymous = true
s_unix_manual.template = "cbi/tblsection"

-- 虚拟机选择
o = s_unix_manual:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- Name
o = s_unix_manual:option(ListValue, "name", translate("Name"))
o:value("com.redhat.spice.0", translate("com.redhat.spice.0"))
o:value("org.libguestfs.channel.0", translate("org.libguestfs.channel.0"))
o:value("org.qemu.guest_agent.0", translate("org.qemu.guest_agent.0"))
o:value("org.spice-space.webdav.0", translate("org.spice-space.webdav.0"))
o.default = "com.redhat.spice.0"

-- Path
o = s_unix_manual:option(Value, "path", translate("Path"))
o.placeholder = translate("Enter path")

return m