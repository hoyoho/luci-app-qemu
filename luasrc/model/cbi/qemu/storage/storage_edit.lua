local m, s, o
local fs = require "nixio.fs"
local sys = require "luci.sys"
local _ = luci.i18n.translate

local section_id = arg[1] or luci.dispatcher.context.requestpath[#luci.dispatcher.context.requestpath]
local uci = require("luci.model.uci").cursor()

local disk_type = ""

if section_id then
    uci:foreach("qemu", "disk", function(s)
        if s[".name"] == section_id then
            disk_type = "disk"
            return false
        end
    end)
    if disk_type == "" then
        uci:foreach("qemu", "cdrom", function(s)
            if s[".name"] == section_id then
                disk_type = "cdrom"
                return false
            end
        end)
    end
end

local page_title
if disk_type == "disk" then
    page_title = translate("Edit Hard Disk")
elseif disk_type == "cdrom" then
    page_title = translate("Edit CD-ROM")
else
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "storage"))
    return
end

m = Map("qemu", page_title)
m.redirect = luci.dispatcher.build_url("admin", "services", "qemu", "storage")

m.on_init = function(self)
    if section_id then
        local exists = false
        if disk_type ~= "" then
            uci:foreach("qemu", disk_type, function(s)
                if s[".name"] == section_id then
                    exists = true
                    return false
                end
            end)
        end
        if not exists then
            luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "storage"))
        end
    end
end

local vm_list = {}
uci:foreach("qemu", "vm", function(vm_section)
    table.insert(vm_list, {name = vm_section.name or vm_section['.name'], title = vm_section.name or vm_section['.name']})
end)

local section_title
if disk_type == "disk" then
    section_title = translate("Hard Disk Configuration")
elseif disk_type == "cdrom" then
    section_title = translate("CD-ROM Configuration")
end

s = m:section(NamedSection, section_id, disk_type, section_title)
s.addremove = false
s.anonymous = false

o = s:option(ListValue, "vm", translate("Virtual Machine"))
o.rmempty = false
for _, vm in ipairs(vm_list) do
    o:value(vm.name, vm.title)
end

local id_label
if disk_type == "disk" then
    id_label = translate("Disk ID")
elseif disk_type == "cdrom" then
    id_label = translate("CD-ROM ID")
end
o = s:option(Value, "id", id_label)
local id_example
if disk_type == "disk" then
    id_example = "hd0"
elseif disk_type == "cdrom" then
    id_example = "cd0"
else
    id_example = "fd0"
end
o.placeholder = translate("e.g., ") .. id_example
o.rmempty = false
o.validate = function(self, value, section)
    if value then
        local valid = false
        if disk_type == "disk" and value:match("^hd[0-9]+") then
            valid = true
        elseif disk_type == "cdrom" and value:match("^cd[0-9]+") then
            valid = true
        end
        
        if not valid then
            local expected_format = disk_type == "disk" and translate("hd0, hd1, etc.") or translate("cd0, cd1, etc.")
            return nil, translate("Invalid ID format. Please use format like ") .. expected_format
        end
    end
    return value
end

local file_label
if disk_type == "disk" then
    file_label = translate("Disk File Path")
elseif disk_type == "cdrom" then
    file_label = translate("ISO File Path")
end
o = s:option(Value, "file", file_label)
local storage_path = uci:get("qemu", "@global[0]", "storage_path") or "/storage/qemu"
local file_example
if disk_type == "disk" then
    file_example = "disk.img"
else
    file_example = "image.iso"
end
o.placeholder = translate("e.g., ") .. storage_path .. "/" .. file_example
o.description = translate("Specify the image file path")
if disk_type == "disk" then
    o.rmempty = false
end
o.validate = function(self, value, section)
    if value then
        if not value:match("^") then
            value = storage_path .. "/" .. value
        end
    end
    return value
end

if disk_type == "disk" then
    o = s:option(ListValue, "format", translate("Disk Format"))
    o:value("qcow2", "QCOW2")
    o:value("raw", "RAW")
    o.default = "qcow2"
    o.rmempty = false
end

o = s:option(ListValue, "iface", translate("Interface"))
o.rmempty = false
o:value("ide", "IDE")
o:value("virtio", "VirtIO")
o.default = "virtio"

o = s:option(Flag, "readonly", translate("Read-only"))
if disk_type == "cdrom" then
    o.default = "1"
    o.rmempty = false
else
    o.rmempty = true
end

o = s:option(Flag, "shareable", translate("Shareable"))
o.rmempty = true

o = s:option(Flag, "removable", translate("Removable"))
o:depends({iface = "usb"})
o.rmempty = true

o = s:option(Value, "serial", translate("Serial Number"))
o.rmempty = true

o = s:option(ListValue, "cache", translate("Cache Mode"))
o:value("", translate("Default"))
o:value("none", "none")
o:value("writethrough", "writethrough")
o:value("writeback", "writeback")
o:value("directsync", "directsync")
o:value("unsafe", "unsafe")
o.default = ""
o.rmempty = true

o = s:option(ListValue, "discard", translate("Discard Mode"))
o:value("", translate("Default"))
o:value("ignore", "ignore")
o:value("unmap", "unmap")
o.default = ""
o.rmempty = true

o = s:option(ListValue, "detect_zeroes", translate("Detect Zeroes"))
o:value("", translate("Default"))
o:value("off", "off")
o:value("on", "on")
o:value("unmap", "unmap")
o.default = ""
o.rmempty = true

return m
