require "luci.http"
require "luci.sys"
require "nixio.fs"
require "luci.dispatcher"
require "luci.model.uci"

-- 获取参数
local section_id = arg[1]
local edit_type = ""

-- 尝试自动检测编辑类型
if section_id then
    local uci = require("luci.model.uci").cursor()
    -- 检查是否为display类型
    uci:foreach("qemu", "display", function(s)
        if s[".name"] == section_id then
            edit_type = "display"
            return false
        end
    end)
    -- 检查是否为video类型
    if edit_type == "" then
        uci:foreach("qemu", "video", function(s)
            if s[".name"] == section_id then
                edit_type = "video"
                return false
            end
        end)
    end
end

-- 如果无法检测到类型，默认使用display
if edit_type == "" then
    edit_type = "display"
end

-- 编辑模式
if edit_type == "display" then
    m = Map("qemu", translate("Edit Display Device"))
elseif edit_type == "video" then
    m = Map("qemu", translate("Edit Video Device"))
else
    -- 无效类型，重定向到列表
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "display"))
    return
end

m.redirect = luci.dispatcher.build_url("admin", "services", "qemu", "display")
m.pageaction = true
m.on_init = function(self)
    if section_id then
        local uci = require("luci.model.uci").cursor()
        local exists = false
        uci:foreach("qemu", edit_type, function(s)
            if s[".name"] == section_id then
                exists = true
                return false
            end
        end)
        if not exists then
            luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "display"))
        end
    end
end

-- 编辑现有设备
local s
if edit_type == "display" then
    s = m:section(NamedSection, section_id, "display")
    s.addremove = false
    s.anonymous = false
    
    -- 基础信息部分
    s:tab("general", translate("General Settings"))
    
    vm = s:taboption("general", ListValue, "vm", translate("Virtual Machine"))
    vm.rmempty = true
    
    -- 填充虚拟机列表
    local uci = require("luci.model.uci").cursor()
    uci:foreach("qemu", "vm", function(vm_section)
        vm:value(vm_section.name, vm_section.name)
    end)
    
    type = s:taboption("general", ListValue, "type", translate("Type"))
    type:value("none", translate("None (Headless)"))
    type:value("vnc", translate("VNC"))
    type.default = "none"
    
    -- 端口分配方式
    port_manual = s:taboption("general", Flag, "port_manual", translate("Manual Port"))
    port_manual.default = "0"
    port_manual:depends({type = "vnc"})
    
    -- 端口设置
    port = s:taboption("general", Value, "port", translate("Port"))
    port.default = "5900"
    port.datatype = "port"
    port:depends({type = "vnc", port_manual = "1"})
    
    -- 地址监听设置
    address_enabled = s:taboption("general", Flag, "address_enabled", translate("Enable Address Listen"))
    address_enabled.default = "1"
    address_enabled:depends({type = "vnc"})
    
    -- 监听地址选择
    address = s:taboption("general", ListValue, "address", translate("Listen Address"))
    address:value("127.0.0.1", translate("Local Only (127.0.0.1)"))
    address:value("0.0.0.0", translate("All Interfaces (0.0.0.0)"))
    local uci = require("luci.model.uci").cursor()
    uci:foreach("network", "interface", function(iface)
        if iface[".name"] == "wan" then
            address:value(iface.ipaddr or "", translate("WAN Interface"))
        elseif iface[".name"] == "lan" then
            address:value(iface.ipaddr or "", translate("LAN Interface"))
        end
    end)
    address.default = "0.0.0.0"
    address:depends({type = "vnc", address_enabled = "1"})
    
    -- 密码设置
    password_enabled = s:taboption("general", Flag, "password_enabled", translate("Enable Password"))
    password_enabled.default = "0"
    password_enabled:depends({type = "vnc"})
    
    password = s:taboption("general", Value, "password", translate("Password"))
    password:depends({type = "vnc", password_enabled = "1"})
    password.password = true
    password.rmempty = true

    function password.write(self, section, value)
        if value and value ~= "" then
            self.map:set(section, "password", "B64:" .. nixio.bin.b64encode(value))
        else
            self.map:set(section, "password", "")
        end
    end

    function password.cfgvalue(self, section)
        local raw = AbstractValue.cfgvalue(self, section)
        if not raw or raw == "" then
            return ""
        end
        if raw:sub(1, 4) == "B64:" then
            return nixio.bin.b64decode(raw:sub(5)) or raw
        end
        return raw
    end
    
    keyboard = s:taboption("general", Value, "keyboard", translate("Keyboard Layout"))
    keyboard.default = "en-us"
    keyboard:depends({type = "vnc"})

    m:section(SimpleSection).template = "qemu/display_vnc_check"
elseif edit_type == "video" then
    s = m:section(NamedSection, section_id, "video")
    s.addremove = false
    s.anonymous = false
    
    -- 基础信息部分
    s:tab("general", translate("General Settings"))
    
    vm = s:taboption("general", ListValue, "vm", translate("Virtual Machine"))
    vm.rmempty = true
    
    -- 填充虚拟机列表
    local uci = require("luci.model.uci").cursor()
    uci:foreach("qemu", "vm", function(vm_section)
        vm:value(vm_section.name, vm_section.name)
    end)
    
    -- 视频设备类型
    type = s:taboption("general", ListValue, "type", translate("Video Device Type"))
    type:value("virtio", translate("VirtIO"))
    type:value("std", translate("STD"))
    type:value("bochs", translate("Bochs"))
    type:value("ramfb", translate("Ramfb"))
    type.default = "std"
end

return m