m = Map("qemu")
m.title = translate("QEMU Virtual Machines")
m.description = translate("Manage your QEMU virtual machines")

m:section(SimpleSection).template  = "qemu/qemu_status"
s = m:section(TypedSection, "global")
s.addremove = false
s.anonymous = true

enabled = s:option(Flag, "enabled", translate("Enable QEMU Manager"))
enabled.default = "0"
enabled.rmempty = false

storage_path = s:option(Value, "storage_path", translate("Storage Path"))
storage_path.default = "/storage/qemu"
storage_path.rmempty = false

-- 添加保存后的回调函数
function m.on_after_commit(self)
    local uci = require("luci.model.uci").cursor()
    local enabled_value = false
    local sections = uci:get_all("qemu")
    if not sections then
        luci.sys.call("logger -t luci-qemu 'No sections found in qemu config'")
        return
    end

    -- 获取所有配置section，找到类型为global的section
    for section_name, section_data in pairs(sections) do
        if section_data[".type"] == "global" then
            enabled_value = uci:get_bool("qemu", section_name, "enabled")
            break
        end
    end

    if enabled_value then
        -- 启用并启动服务
        luci.sys.call("logger -t luci-qemu 'Enabling and starting qemu service'")
        luci.sys.call("/etc/init.d/qemu enable")
        luci.sys.call("/etc/init.d/qemu start")
    else
        -- 停止并禁用服务
        luci.sys.call("logger -t luci-qemu 'Stopping and disabling qemu service'")
        luci.sys.call("/etc/init.d/qemu stop")
        luci.sys.call("/etc/init.d/qemu disable")
    end
end

-- 添加日志显示
m:section(SimpleSection).template = "qemu/qemu_log"

return m