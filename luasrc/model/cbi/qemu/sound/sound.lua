local m, s, o

m = Map("qemu", translate("QEMU Sound Devices"))

-- 动态检测 QEMU 支持的音频后端
local audio_backends = {}
local qemu_bin = "/usr/bin/qemu-system-x86_64"
if nixio.fs.access(qemu_bin) then
	local output = luci.sys.exec(qemu_bin .. " -audiodev help 2>/dev/null")
	local skip_first = true
	for line in output:gmatch("[^\r\n]+") do
		if skip_first then
			skip_first = false
		else
			local d = line:match("^%s*(%S+)")
			if d and d ~= "" then
				audio_backends[d] = true
			end
		end
	end
end
audio_backends["none"] = true

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

-- 音频驱动
o = s:option(ListValue, "driver", translate("Audio Driver"))
o.default = "none"
for d in pairs(audio_backends) do
	o:value(d, d == "none" and translate("None (no audio output)") or d)
end

return m
