local m, s, o
local uci = require("luci.model.uci").cursor()
local TypedSection = require("luci.cbi").TypedSection
local _ = luci.i18n.translate

-- 主 Map
m = Map("qemu", translate("QEMU Network Management"))
m.pageaction = true

-- 获取所有虚拟机列表
local vm_list = {}
uci:foreach("qemu", "vm", function(s)
    table.insert(vm_list, {name = s[".name"], title = s.name or s[".name"]})
end)

-- Bridge网络
local s1 = m:section(TypedSection, "net_bridge", translate("Bridge Networks"))
s1.addremove = true
s1.anonymous = true
s1.template = "cbi/tblsection"
s1.sortable = true
s1.extedit = luci.dispatcher.build_url("admin", "services", "qemu", "networks", "network_edit", "%s", "bridge")

-- 修复创建函数：跳转到编辑页面
s1.create = function(self, section)
    local new_section = TypedSection.create(self, section)
    -- 跳转到编辑页面
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "networks", "network_edit", new_section) .. "?network_type=bridge")
    return new_section
end

-- 虚拟机选择
o = s1:option(DummyValue, "vm", translate("VM Reference"))

-- 接口ID
o = s1:option(DummyValue, "id", translate("Interface ID"))

-- MAC地址
o = s1:option(DummyValue, "mac", translate("MAC Address"))

-- 模型
o = s1:option(DummyValue, "model", translate("Model"))

-- User网络
local s2 = m:section(TypedSection, "net_user", translate("User (NAT) Networks"))
s2.addremove = true
s2.anonymous = true
s2.template = "cbi/tblsection"
s2.sortable = true
s2.extedit = luci.dispatcher.build_url("admin", "services", "qemu", "networks", "network_edit", "%s", "user")

-- 修复创建函数：跳转到编辑页面
s2.create = function(self, section)
    local new_section = TypedSection.create(self, section)
    -- 跳转到编辑页面
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "networks", "network_edit", new_section) .. "?network_type=user")
    return new_section
end

-- 虚拟机选择
o = s2:option(DummyValue, "vm", translate("VM Reference"))

-- 接口ID
o = s2:option(DummyValue, "id", translate("Interface ID"))

-- MAC地址
o = s2:option(DummyValue, "mac", translate("MAC Address"))

-- 模型
o = s2:option(DummyValue, "model", translate("Model"))

-- TAP网络
local s3 = m:section(TypedSection, "net_tap", translate("TAP Networks"))
s3.addremove = true
s3.anonymous = true
s3.template = "cbi/tblsection"
s3.sortable = true
s3.extedit = luci.dispatcher.build_url("admin", "services", "qemu", "networks", "network_edit", "%s", "tap")

-- 修复创建函数：跳转到编辑页面
s3.create = function(self, section)
    local new_section = TypedSection.create(self, section)
    -- 跳转到编辑页面
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "networks", "network_edit", new_section) .. "?network_type=tap")
    return new_section
end

-- 虚拟机选择
o = s3:option(DummyValue, "vm", translate("VM Reference"))

-- 接口ID
o = s3:option(DummyValue, "id", translate("Interface ID"))

-- MAC地址
o = s3:option(DummyValue, "mac", translate("MAC Address"))

-- 模型
o = s3:option(DummyValue, "model", translate("Model"))

-- L2TPv3网络
local s4 = m:section(TypedSection, "net_l2tpv3", translate("L2TPv3 Networks"))
s4.addremove = true
s4.anonymous = true
s4.template = "cbi/tblsection"
s4.sortable = true
s4.extedit = luci.dispatcher.build_url("admin", "services", "qemu", "networks", "network_edit", "%s", "l2tpv3")

-- 修复创建函数：跳转到编辑页面
s4.create = function(self, section)
    local new_section = TypedSection.create(self, section)
    -- 跳转到编辑页面
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "networks", "network_edit", new_section) .. "?network_type=l2tpv3")
    return new_section
end

-- 虚拟机选择
o = s4:option(DummyValue, "vm", translate("VM Reference"))

-- 接口ID
o = s4:option(DummyValue, "id", translate("Interface ID"))

-- MAC地址
o = s4:option(DummyValue, "mac", translate("MAC Address"))

-- 模型
o = s4:option(DummyValue, "model", translate("Model"))

-- Socket网络
local s5 = m:section(TypedSection, "net_socket", translate("Socket Networks"))
s5.addremove = true
s5.anonymous = true
s5.template = "cbi/tblsection"
s5.sortable = true
s5.extedit = luci.dispatcher.build_url("admin", "services", "qemu", "networks", "network_edit", "%s", "socket")

-- 修复创建函数：跳转到编辑页面
s5.create = function(self, section)
    local new_section = TypedSection.create(self, section)
    -- 跳转到编辑页面
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "networks", "network_edit", new_section) .. "?network_type=socket")
    return new_section
end

-- 虚拟机选择
o = s5:option(DummyValue, "vm", translate("VM Reference"))

-- 接口ID
o = s5:option(DummyValue, "id", translate("Interface ID"))

-- MAC地址
o = s5:option(DummyValue, "mac", translate("MAC Address"))

-- 模型
o = s5:option(DummyValue, "model", translate("Model"))

-- Connect
o = s5:option(DummyValue, "connect", translate("Connect"))

-- Listen
o = s5:option(DummyValue, "listen", translate("Listen"))

-- 返回主 Map
return m
