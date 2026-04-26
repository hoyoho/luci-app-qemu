local m, s, o

m = Map("qemu", translate("QEMU Host Devices"))

-- 获取所有虚拟机名称
local vm_list = {}
local uci = require("luci.model.uci").cursor()
uci:foreach("qemu", "vm", function(s)
    table.insert(vm_list, {name = s.name or s['.name'], title = s.name or s['.name']})
end)

-- 枚举USB设备
local function get_usb_devices()
    local usb_devices = {}
    local handle = io.popen("lsusb 2>/dev/null")
    if handle then
        local line
        for line in handle:lines() do
            local bus, dev, idstr, name = line:match("Bus (%d+) Device (%d+): ID ([%x:]+) (.+)")
            if bus and dev and idstr and name then
                local device_id = bus .. "-" .. dev
                table.insert(usb_devices, {id = device_id, idstr = idstr, name = name})
            end
        end
        handle:close()
    end
    return usb_devices
end

-- 枚举PCI设备
local function get_pci_devices()
    local pci_devices = {}
    local handle = io.popen("lspci 2>/dev/null")
    if handle then
        local line
        for line in handle:lines() do
            local slot, device_type, name = line:match("([0-9a-f:.]+) (.+): (.+)")
            if slot and device_type and name then
                -- 移除版本信息
                name = name:gsub(" %(%w+ [^%)]+%)", "")
                table.insert(pci_devices, {id = slot, name = string.format("%s: %s", device_type, name)})
            end
        end
        handle:close()
    end
    return pci_devices
end

-- 枚举MDEV设备
local function get_mdev_devices()
    local mdev_devices = {}
    local handle = io.popen("ls -la /sys/devices/virtual/mdev_bus/ 2>/dev/null")
    if handle then
        local line
        for line in handle:lines() do
            local name = line:match("d.* ([^%s]+)")
            if name and name ~= "." and name ~= ".." then
                table.insert(mdev_devices, {id = name, name = name})
            end
        end
        handle:close()
    end
    -- 也检查 /sys/class/mdev_bus/
    handle = io.popen("ls /sys/class/mdev_bus/ 2>/dev/null")
    if handle then
        local line
        for line in handle:lines() do
            if line and line ~= "" and line ~= "." and line ~= ".." then
                local exists = false
                for _, dev in ipairs(mdev_devices) do
                    if dev.id == line then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(mdev_devices, {id = line, name = line})
                end
            end
        end
        handle:close()
    end
    return mdev_devices
end

-- USB Host Device
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

-- PCI Host Device
s_pci = m:section(TypedSection, "host_dev_pci", translate("PCI Host Devices"), translate("PCI passthrough devices"))
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

-- MDEV Host Device
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

-- MDEV Type
o = s_mdev:option(Value, "mdev_type", translate("MDEV Type"))
o.placeholder = translate("e.g., nvidia-11")

-- RNG Host Device
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

-- Host Device
o = s_rng:option(Value, "host", translate("RNG Device"))
o.default = "/dev/urandom"
o:value("/dev/urandom", translate("/dev/urandom"))
o:value("/dev/hwrng", translate("/dev/hwrng"))

-- TPM Host Device
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

-- Model
o = s_tpm:option(ListValue, "model", translate("Model"))
o:value("crb", translate("CRB"))
o:value("tis", translate("TIS"))
o.default = "crb"

-- Device Path
o = s_tpm:option(Value, "device_path", translate("Device Path"))
o.placeholder = translate("Enter device path (e.g., /dev/tpm0)")

return m