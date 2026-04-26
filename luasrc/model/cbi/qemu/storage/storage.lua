local m, s1, s2, s3
local uci = require("luci.model.uci").cursor()
local TypedSection = require("luci.cbi").TypedSection
local _ = luci.i18n.translate

-- 主 Map
m = Map("qemu", translate("QEMU Disk Management"))
m.pageaction = true

-- 硬盘部分
s1 = m:section(TypedSection, "disk", translate("Hard Disks"))
s1.addremove = true
s1.anonymous = true
s1.template = "cbi/tblsection"
s1.extedit = luci.dispatcher.build_url("admin", "services", "qemu", "storage", "storage_edit", "%s")
s1.sortable = true

-- 修复创建函数：重定向到引导界面
s1.create = function(self, section)
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "storage_wizard") .. "?device_type=disk")
    return nil
end

s1:option(DummyValue, "vm", translate("VM Reference"))
s1:option(DummyValue, "id", translate("Disk ID"))
s1:option(DummyValue, "file", translate("Disk File"))
s1:option(DummyValue, "format", translate("Format"))
s1:option(DummyValue, "size", translate("Size (GB)"))
s1:option(DummyValue, "iface", translate("Interface"))

-- 光盘部分
s2 = m:section(TypedSection, "cdrom", translate("CD-ROMs"))
s2.addremove = true
s2.anonymous = true
s2.template = "cbi/tblsection"
s2.extedit = luci.dispatcher.build_url("admin", "services", "qemu", "storage", "storage_edit", "%s")
s2.sortable = true

-- 修复创建函数：重定向到引导界面
s2.create = function(self, section)
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "storage_wizard") .. "?device_type=cdrom")
    return nil
end

s2:option(DummyValue, "vm", translate("VM Reference"))
s2:option(DummyValue, "id", translate("CD-ROM ID"))
s2:option(DummyValue, "file", translate("ISO File"))
s2:option(DummyValue, "iface", translate("Interface"))

-- 返回主 Map
return m