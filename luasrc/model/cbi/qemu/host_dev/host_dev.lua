local m, s, o

m = Map("qemu", translate("QEMU Host Devices"))

local vm_list = require("luci.model.cbi.qemu.util").get_vm_list()

local function cached_exec(cmd, cache_file, ttl)
	ttl = ttl or 3600
	local stat = nixio.fs.stat(cache_file)
	if stat and stat.mtime and os.time() - stat.mtime < ttl then
		local f = io.open(cache_file, "r")
		if f then
			local content = f:read("*a")
			f:close()
			return content
		end
	end
	local handle = io.popen(cmd .. " 2>/dev/null")
	if not handle then return "" end
	local output = handle:read("*a")
	handle:close()
	local f = io.open(cache_file, "w")
	if f then
		f:write(output)
		f:close()
	end
	return output
end

local function get_usb_devices()
	local usb_devices = {}
	local output = cached_exec("lsusb", "/tmp/qemu_usb_cache")
	for line in output:gmatch("[^\r\n]+") do
		local bus, dev, idstr, name = line:match("Bus (%d+) Device (%d+): ID ([%x:]+) (.+)")
		if bus and dev and idstr and name then
			table.insert(usb_devices, {id = bus .. "-" .. dev, idstr = idstr, name = name})
		end
	end
	return usb_devices
end

local function get_pci_devices()
	local pci_devices = {}
	local output = cached_exec("lspci -D", "/tmp/qemu_pci_cache")
	for line in output:gmatch("[^\r\n]+") do
		local slot, device_type, name = line:match("([0-9a-f:.]+) (.+): (.+)")
		if slot and device_type and name then
			name = name:gsub(" %(%w+ [^%)]+%)", "")
			table.insert(pci_devices, {id = slot, name = string.format("%s: %s", device_type, name)})
		end
	end
	return pci_devices
end

local function get_mdev_devices()
	local mdev_devices = {}
	local output1 = cached_exec("ls -1 /sys/devices/virtual/mdev_bus/", "/tmp/qemu_mdev_cache1")
	for line in output1:gmatch("[^\r\n]+") do
		if line ~= "" then
			table.insert(mdev_devices, {id = line, name = line})
		end
	end
	local output2 = cached_exec("ls -1 /sys/class/mdev_bus/", "/tmp/qemu_mdev_cache2")
	for line in output2:gmatch("[^\r\n]+") do
		if line ~= "" then
			local exists = false
			for _, dev in ipairs(mdev_devices) do
				if dev.id == line then exists = true; break end
			end
			if not exists then
				table.insert(mdev_devices, {id = line, name = line})
			end
		end
	end
	return mdev_devices
end

-- USB 主机设备
s_usb = m:section(TypedSection, "host_dev_usb", translate("USB Host Devices"), translate("USB passthrough devices"))
s_usb.addremove = true
s_usb.anonymous = true
s_usb.template = "cbi/tblsection"

-- 虚拟机选择
o = s_usb:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- USB设备选择
local usb_devices = get_usb_devices()
o = s_usb:option(ListValue, "host", translate("USB Device"))
o:value("", translate("-- Select USB Device --"))
for _, device in ipairs(usb_devices) do
    o:value(device.id, device.name)
end

-- PCI 主机设备
s_pci = m:section(TypedSection, "host_dev_pci", translate("PCI Host Devices"), translate("PCI passthrough devices, requires adding 'intel_iommu=on iommu=pt' to kernel command line"))
s_pci.addremove = true
s_pci.anonymous = true
s_pci.template = "cbi/tblsection"

-- 虚拟机选择
o = s_pci:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- PCI设备选择
local pci_devices = get_pci_devices()
o = s_pci:option(ListValue, "host", translate("PCI Device"))
o:value("", translate("-- Select PCI Device --"))
for _, device in ipairs(pci_devices) do
    o:value(device.id, device.name)
end

-- MDEV 主机设备
s_mdev = m:section(TypedSection, "host_dev_mdev", translate("MDEV Host Devices"), translate("Mediated device passthrough"))
s_mdev.addremove = true
s_mdev.anonymous = true
s_mdev.template = "cbi/tblsection"

-- 虚拟机选择
o = s_mdev:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- MDEV设备选择
local mdev_devices = get_mdev_devices()
o = s_mdev:option(ListValue, "host", translate("MDEV Device"))
o:value("", translate("-- Select MDEV Device --"))
for _, device in ipairs(mdev_devices) do
    o:value(device.id, device.name)
end

-- MDEV 类型
o = s_mdev:option(Value, "mdev_type", translate("MDEV Type"))
o.placeholder = translate("e.g., nvidia-11")

-- RNG 主机设备
s_rng = m:section(TypedSection, "host_dev_rng", translate("RNG Host Devices"), translate("Random number generator"))
s_rng.addremove = true
s_rng.anonymous = true
s_rng.template = "cbi/tblsection"

-- 虚拟机选择
o = s_rng:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- 主机设备
o = s_rng:option(Value, "host", translate("RNG Device"))
o.default = "/dev/urandom"
o:value("/dev/urandom", translate("/dev/urandom"))
o:value("/dev/hwrng", translate("/dev/hwrng"))

-- TPM 主机设备
s_tpm = m:section(TypedSection, "host_dev_tpm", translate("TPM Host Devices"), translate("TPM passthrough devices"))
s_tpm.addremove = true
s_tpm.anonymous = true
s_tpm.template = "cbi/tblsection"

-- 虚拟机选择
o = s_tpm:option(ListValue, "vm", translate("VM"))
o:value("", translate("-- Select VM --"))
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

-- 模型
o = s_tpm:option(ListValue, "model", translate("Model"))
o:value("crb", translate("CRB"))
o:value("tis", translate("TIS"))
o.default = "crb"

-- 设备路径
o = s_tpm:option(Value, "device_path", translate("Device Path"))
o.placeholder = translate("Enter device path (e.g., /dev/tpm0)")

return m