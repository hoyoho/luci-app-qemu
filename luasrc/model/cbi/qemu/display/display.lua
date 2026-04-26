require "luci.http"
require "luci.sys"
require "nixio.fs"
require "luci.dispatcher"
require "luci.model.uci"

m = Map("qemu", translate("Display Devices"))
m.pageaction = true

-- Display Devices 表格
s_display = m:section(TypedSection, "display", translate("Monitor Devices"))
s_display.anonymous = true
s_display.addremove = true
s_display.template = "cbi/tblsection"
s_display.sortable = true

-- 显示虚拟机名称列
vm_display = s_display:option(DummyValue, "vm", translate("VM"))
vm_display.rmempty = true

-- 显示类型列
type_display = s_display:option(DummyValue, "type", translate("Type"))
type_display.rmempty = true

-- 显示地址列
address_display = s_display:option(DummyValue, "address", translate("Address"))
function address_display.cfgvalue(self, section)
    local address_enabled = self.map:get(section, "address_enabled")
    if address_enabled == "0" then
        return translate("Disabled")
    end
    return self.map:get(section, "address") or "0.0.0.0"
end

-- 显示端口列
port_display = s_display:option(DummyValue, "port", translate("Port"))
function port_display.cfgvalue(self, section)
    local port_mannual = self.map:get(section, "port_mannual")
    if port_mannual ~= "1" then
        return translate("Auto")
    end
    return self.map:get(section, "port") or "5900"
end

-- 显示密码状态
password_display = s_display:option(DummyValue, "password", translate("Password"))
function password_display.cfgvalue(self, section)
    local password_enabled = self.map:get(section, "password_enabled")
    if password_enabled == "1" then
        return translate("Enabled")
    end
    return translate("Disabled")
end

-- 编辑按钮
s_display.extedit = luci.dispatcher.build_url("admin", "services", "qemu", "display", "edit", "%s")

-- 修复创建函数：跳转到编辑页面
s_display.create = function(self, section)
    local new_section = TypedSection.create(self, section)
    -- 跳转到编辑页面
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "display", "edit", new_section) .. "?edit_type=display")
    return new_section
end

-- Video Devices 表格
s_video = m:section(TypedSection, "video", translate("Video Devices"))
s_video.anonymous = true
s_video.addremove = true
s_video.template = "cbi/tblsection"
s_video.sortable = true

-- 显示虚拟机名称列
vm_video = s_video:option(DummyValue, "vm", translate("VM"))
vm_video.rmempty = true

-- 显示视频设备类型列
type_video = s_video:option(DummyValue, "type", translate("Type"))
type_video.rmempty = true


-- 编辑按钮
s_video.extedit = luci.dispatcher.build_url("admin", "services", "qemu", "display", "edit", "%s")

-- 修复创建函数：跳转到编辑页面
s_video.create = function(self, section)
    local new_section = TypedSection.create(self, section)
    -- 跳转到编辑页面
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "display", "edit", new_section) .. "?edit_type=video")
    return new_section
end

return m
