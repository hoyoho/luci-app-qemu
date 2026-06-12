local m, s, o

m = Map("qemu", translate("QEMU Sound Devices"))

-- 动态检测 QEMU 支持的音频后端（缓存结果，避免每次加载都执行 QEMU）
local audio_backends = {}
audio_backends["none"] = true
local qemu_bin = "/usr/bin/qemu-system-x86_64"
local cache_file = "/tmp/qemu_audio_cache"
if nixio.fs.access(qemu_bin) then
	local use_cache = false
	local cache_stat = nixio.fs.stat(cache_file)
	if cache_stat and cache_stat.mtime then
		if os.time() - cache_stat.mtime < 3600 then
			use_cache = true
		end
	end
	if use_cache then
		local f = io.open(cache_file, "r")
		if f then
			for line in f:lines() do
				audio_backends[line] = true
			end
			f:close()
		end
	else
		local output = luci.sys.exec(qemu_bin .. " -audiodev help 2>/dev/null")
		local skip_first = true
		local backends = {}
		for line in output:gmatch("[^\r\n]+") do
			if skip_first then
				skip_first = false
			else
				local d = line:match("^%s*(%S+)")
				if d and d ~= "" then
					audio_backends[d] = true
					table.insert(backends, d)
				end
			end
		end
		local f = io.open(cache_file, "w")
		if f then
			f:write(table.concat(backends, "\n"))
			f:close()
		end
	end
end

local vm_list = require("luci.model.cbi.qemu.util").get_vm_list()

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
