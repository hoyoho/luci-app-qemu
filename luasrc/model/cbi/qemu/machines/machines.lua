require "luci.http"
require "luci.sys"
require "nixio.fs"
require "luci.dispatcher"
require "luci.model.uci"

-- 根据是否有section参数决定显示列表还是编辑表单
if arg[1] then
    -- 编辑模式
    m = Map("qemu", translate("Edit Virtual Machine"))
    m.redirect = luci.dispatcher.build_url("admin", "services", "qemu", "machines")
    
    -- 编辑现有虚拟机
    s = m:section(NamedSection, arg[1], "vm")
    s.addremove = false
    s.anonymous = false
    
    -- 基础信息部分
    s:tab("general", translate("General Settings"))
    
    name = s:taboption("general", Value, "name", translate("VM Name"))
    name.rmempty = true
    name.description = translate("Unique name for this virtual machine")
    
    description = s:taboption("general", Value, "description", translate("Description"))
    
    autostart = s:taboption("general", Flag, "autostart", translate("Auto Start"))
    autostart.rmempty = false
    autostart.default = "0"

    snapshot = s:taboption("general", Flag, "snapshot", translate("Snapshot Mode"))
    snapshot.default = "0"

    mem_prealloc = s:taboption("general", Flag, "mem_prealloc", translate("Preallocate Memory"))
    mem_prealloc.default = "0"

    mem_merge = s:taboption("general", Flag, "mem_merge", translate("Memory Merging"))
    mem_merge.default = "0"

    nodefaults = s:taboption("general", Flag, "nodefaults", translate("No Default Devices"))
    nodefaults.default = "1"

    -- 机器配置部分
    s:tab("machine", translate("Machine Settings"))
    
    machine = s:taboption("machine", ListValue, "machine", translate("Machine Type"))
    -- 标准PC (i440FX + PIIX, 1996)
    machine:value("pc", translate("Standard PC (i440FX + PIIX, 1996)"))
    machine:value("pc-i440fx-10.1", translate("Standard PC (i440FX + PIIX, 1996) (default)"))
    machine:value("pc-i440fx-10.0", translate("Standard PC (i440FX + PIIX, 1996)"))
    machine:value("pc-i440fx-9.2", translate("Standard PC (i440FX + PIIX, 1996)"))
    machine:value("pc-i440fx-9.1", translate("Standard PC (i440FX + PIIX, 1996)"))
    machine:value("pc-i440fx-9.0", translate("Standard PC (i440FX + PIIX, 1996)"))
    machine:value("pc-i440fx-8.2", translate("Standard PC (i440FX + PIIX, 1996)"))
    machine:value("pc-i440fx-8.1", translate("Standard PC (i440FX + PIIX, 1996)"))
    machine:value("pc-i440fx-8.0", translate("Standard PC (i440FX + PIIX, 1996)"))
    -- Standard PC (Q35 + ICH9, 2009)
    machine:value("q35", translate("Standard PC (Q35 + ICH9, 2009)"))
    machine:value("pc-q35-10.1", translate("Standard PC (Q35 + ICH9, 2009)"))
    machine:value("pc-q35-10.0", translate("Standard PC (Q35 + ICH9, 2009)"))
    machine:value("pc-q35-9.2", translate("Standard PC (Q35 + ICH9, 2009)"))
    machine:value("pc-q35-9.1", translate("Standard PC (Q35 + ICH9, 2009)"))
    machine:value("pc-q35-9.0", translate("Standard PC (Q35 + ICH9, 2009)"))
    machine:value("pc-q35-8.2", translate("Standard PC (Q35 + ICH9, 2009)"))
    machine:value("pc-q35-8.1", translate("Standard PC (Q35 + ICH9, 2009)"))
    machine:value("pc-q35-8.0", translate("Standard PC (Q35 + ICH9, 2009)"))
    -- 其他机器类型
    machine:value("microvm", translate("microvm (i386)"))
    machine:value("isapc", translate("ISA-only PC"))
    machine:value("none", translate("empty machine"))
    machine:value("x-remote", translate("Experimental remote machine"))
    machine.default = "pc"

    accel = s:taboption("machine", ListValue, "accel", translate("Acceleration"))
    accel:value("kvm", translate("KVM"))
    accel:value("tcg", translate("TCG"))
    accel.default = "kvm"

    cpu_model = s:taboption("machine", ListValue, "cpu_model", translate("CPU Model"))
    -- 通用模型
    cpu_model:value("host", translate("Host"))
    cpu_model:value("qemu64", translate("QEMU 64-bit"))
    cpu_model:value("qemu32", translate("QEMU 32-bit"))
    cpu_model:value("kvm64", translate("KVM 64-bit"))
    cpu_model:value("kvm32", translate("KVM 32-bit"))
    cpu_model:value("max", translate("Max Support"))
    -- Intel处理器
    cpu_model:value("Conroe", translate("Intel Conroe"))
    cpu_model:value("Penryn", translate("Intel Penryn"))
    cpu_model:value("Snowridge", translate("Intel Snowridge"))
    cpu_model:value("KnightsMill", translate("Intel KnightsMill"))
    cpu_model:value("Denverton", translate("Intel Denverton"))
    cpu_model:value("core2duo", translate("Intel Core 2 Duo"))
    cpu_model:value("coreduo", translate("Intel Core Duo"))
    cpu_model:value("pentium", translate("Intel Pentium"))
    cpu_model:value("pentium2", translate("Intel Pentium 2"))
    cpu_model:value("pentium3", translate("Intel Pentium 3"))
    cpu_model:value("n270", translate("Intel Atom N270"))
    cpu_model:value("Nehalem", translate("Intel Nehalem"))
    cpu_model:value("Westmere", translate("Intel Westmere"))
    cpu_model:value("SandyBridge", translate("Intel Sandy Bridge"))
    cpu_model:value("IvyBridge", translate("Intel Ivy Bridge"))
    cpu_model:value("Haswell", translate("Intel Haswell"))
    cpu_model:value("Broadwell", translate("Intel Broadwell"))
    cpu_model:value("Skylake-Client", translate("Intel Skylake Client"))
    cpu_model:value("Skylake-Server", translate("Intel Skylake Server"))
    cpu_model:value("Icelake-Server", translate("Intel Icelake Server"))
    cpu_model:value("Cascadelake-Server", translate("Intel Cascadelake Server"))
    cpu_model:value("Cooperlake", translate("Intel Cooperlake"))
    cpu_model:value("SapphireRapids", translate("Intel Sapphire Rapids"))
    cpu_model:value("GraniteRapids", translate("Intel Granite Rapids"))
    cpu_model:value("SierraForest", translate("Intel Sierra Forest"))
    cpu_model:value("ClearwaterForest", translate("Intel Clearwater Forest"))
    -- AMD处理器
    cpu_model:value("athlon", translate("AMD Athlon"))
    cpu_model:value("phenom", translate("AMD Phenom"))
    cpu_model:value("Opteron_G1", translate("AMD Opteron G1"))
    cpu_model:value("Opteron_G2", translate("AMD Opteron G2"))
    cpu_model:value("Opteron_G3", translate("AMD Opteron G3"))
    cpu_model:value("Opteron_G4", translate("AMD Opteron G4"))
    cpu_model:value("Opteron_G5", translate("AMD Opteron G5"))
    cpu_model:value("EPYC", translate("AMD EPYC"))
    cpu_model:value("EPYC-Rome", translate("AMD EPYC Rome"))
    cpu_model:value("EPYC-Milan", translate("AMD EPYC Milan"))
    cpu_model:value("EPYC-Genoa", translate("AMD EPYC Genoa"))
    cpu_model:value("EPYC-Turin", translate("AMD EPYC Turin"))
    -- 其他处理器
    cpu_model:value("Dhyana", translate("Hygon Dhyana"))
    cpu_model:value("YongFeng", translate("Zhaoxin YongFeng"))
    cpu_model.default = "host"

    cpu_flags = s:taboption("machine", Value, "cpu_flags", translate("CPU Flags"))
    cpu_flags.description = translate("Additional CPU flags (query with 'qemu-system-x86_64 -cpu help')")

    smp_sockets = s:taboption("machine", Value, "smp_sockets", translate("Sockets"))
    smp_sockets.default = "1"
    smp_sockets.rmempty = false
    smp_sockets.datatype = "uinteger"

    smp_cores = s:taboption("machine", Value, "smp_cores", translate("Cores per Socket"))
    smp_cores.default = "1"
    smp_cores.rmempty = false
    smp_cores.datatype = "uinteger"

    smp_threads = s:taboption("machine", Value, "smp_threads", translate("Threads per Core"))
    smp_threads.default = "1"
    smp_threads.rmempty = false
    smp_threads.datatype = "uinteger"

    mem_size = s:taboption("machine", Value, "mem_size", translate("Memory (MB)"))
    mem_size.placeholder = "e.g., 512"
    mem_size.datatype = "uinteger"
    mem_size.rmempty = false

    -- 启动配置部分
    s:tab("boot", translate("Boot Settings"))
    
    boot = s:taboption("boot", ListValue, "boot", translate("Boot Order"))
    boot:value("order=c,cd,net", translate("Hard Disk first, then CD-ROM, then Network"))
    boot:value("order=c,net,cd", translate("Hard Disk first, then Network, then CD-ROM"))
    boot:value("order=cd,c,net", translate("CD-ROM first, then Hard Disk, then Network"))
    boot:value("order=cd,net,cd", translate("CD-ROM first, then Network, then Hard Disk"))
    boot:value("order=net,c,cd", translate("Network first, then Hard Disk, then CD-ROM"))
    boot:value("order=net,cd,c", translate("Network first, then CD-ROM, then Hard Disk"))
    boot.default = "order=c,net,cd"
    boot.description = translate("Select the boot device order for the VM")

    boot_menu = s:taboption("boot", ListValue, "boot_menu", translate("Boot Menu"))
    boot_menu:value("on", translate("On"))
    boot_menu:value("off", translate("Off"))
    boot_menu.default = "on"

    uefi = s:taboption("boot", Flag, "uefi", translate("UEFI Boot"))
    uefi.default = "0"

    bios = s:taboption("boot", Value, "bios", translate("BIOS File"))
    bios.description = translate("Path to custom BIOS/UEFI firmware")
    bios.default = "/usr/share/OVMF/OVMF_CODE.fd"
    bios:depends("uefi", "1")

    -- 时钟配置部分
    s:tab("clock", translate("Clock Settings"))
    
    rtc_base = s:taboption("clock", ListValue, "rtc_base", translate("RTC Base"))
    rtc_base:value("localtime", translate("Local Time"))
    rtc_base:value("utc", translate("UTC"))
    rtc_base.default = "localtime"

    rtc_clock = s:taboption("clock", ListValue, "rtc_clock", translate("RTC Clock"))
    rtc_clock:value("host", translate("Host"))
    rtc_clock:value("vm", translate("VM"))
    rtc_clock:value("rt", translate("Real Time"))
    rtc_clock.default = "host"

    rtc_driftfix = s:taboption("clock", ListValue, "rtc_driftfix", translate("RTC Drift Fix"))
    rtc_driftfix:value("none", translate("None"))
    rtc_driftfix:value("slew", translate("Slew"))
    rtc_driftfix.default = "none"
    rtc_driftfix.description = translate("Method to fix time drift in the VM")

    -- 额外参数部分
    s:tab("extra", translate("Extra Arguments"))

    extra_args = s:taboption("extra", Value, "extra_args", translate("Additional Arguments"))
    extra_args.description = translate("Additional QEMU command line arguments")
    
    return m
else
    -- 列表模式
    m = Map("qemu", translate("Virtual Machines"))
    
    -- 虚拟机列表部分
    s = m:section(TypedSection, "vm")
    s.anonymous = true
    s.addremove = true
    s.template = "cbi/tblsection"
    s.sortable = true
    
    -- 自定义create函数，跳转到引导界面
    function s.create(self, section)
        luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "wizard"))
        return
    end
    
    -- 显示虚拟机名称列
    name = s:option(DummyValue, "name", translate("Name"))
    name.rmempty = true
    
    -- 显示虚拟机描述列
    description = s:option(DummyValue, "description", translate("Description"))
    
    -- 显示虚拟机状态列（自定义状态显示）
    status = s:option(DummyValue, "_status", translate("Status"))
    -- 自定义状态值获取函数
    function status.cfgvalue(self, section)
        local vm_name = self.map:get(section, "name") or section
        local pid = luci.sys.exec("ps | grep -E 'qemu-system.*[[:space:]]-name[[:space:]]+\"?" .. vm_name .. "\"?[[:space:]]' | grep -v grep | awk '{print $1}'"):trim()
        if pid ~= "" then
            return translate("Running")
        else
            return translate("Stopped")
        end
    end
    
    -- 显示CPU配置列
    cpus = s:option(DummyValue, "_cpus", translate("CPUs"))
    function cpus.cfgvalue(self, section)
        local sockets = self.map:get(section, "smp_sockets") or "1"
        local cores = self.map:get(section, "smp_cores") or "1"
        local threads = self.map:get(section, "smp_threads") or "1"
        return sockets .. "x" .. cores .. "x" .. threads
    end
    
    -- 显示内存大小列
    mem = s:option(DummyValue, "mem_size", translate("Memory"))
    function mem.cfgvalue(self, section)
        return self.map:get(section, "mem_size") .. " MB"
    end
    
    -- 添加启动按钮
    start = s:option(Button, "_start", translate("Start"))
    start.inputstyle = "apply"
    function start.write(self, section)
        luci.sys.call("/etc/init.d/qemu start " .. section)
        luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "machines"))
    end
    
    -- 添加停止按钮
    stop = s:option(Button, "_stop", translate("Stop"))
    stop.inputstyle = "reset"
    function stop.write(self, section)
        luci.sys.call("/etc/init.d/qemu stop " .. section)
        luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "machines"))
    end
    
    -- 添加复位按钮
    reset = s:option(Button, "_reset", translate("Reset"))
    reset.inputstyle = "reload"
    function reset.write(self, section)
        local uci = require("luci.model.uci").cursor()
        local name = uci:get("qemu", section, "name") or section
        local qmp_socket = "/var/run/qemu-" .. name .. "-qmp.sock"
        local cmd = "(echo '{\"execute\": \"qmp_capabilities\"}'; echo '{\"execute\": \"system_reset\"}') | socat - unix-connect:" .. qmp_socket
        luci.sys.exec(cmd)
        luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "machines"))
    end
    
    -- 使用extedit实现编辑功能
    s.extedit = luci.dispatcher.build_url("admin", "services", "qemu", "machines", "%s")
    
    -- 处理删除请求
    if luci.http.formvalue("delete") then
        local section = luci.http.formvalue("section")
        local delete_disks = luci.http.formvalue("delete_disks")
        -- TODO 不仅仅是删除下面这些资源，包括好多
        if section then
            -- 获取虚拟机关联的磁盘文件
            local uci = require("luci.model.uci").cursor()
            local disks = {}
            uci:foreach("qemu", "disk", function(disk)
                if disk.vm == "@" .. section then
                    table.insert(disks, disk.file)
                end
            end)
            
            -- 删除磁盘文件
            if delete_disks == "1" then
                for _, disk_file in ipairs(disks) do
                    luci.sys.call("rm -f " .. disk_file)
                end
            end
            
            -- 删除虚拟机配置
            luci.sys.call("uci delete qemu." .. section)
            
            -- 删除关联的磁盘、网络、显示配置
            uci:foreach("qemu", "disk", function(disk)
                if disk.vm == "@" .. section then
                    luci.sys.call("uci delete qemu." .. disk[".name"])
                end
            end)
            
            uci:foreach("qemu", "net", function(net)
                if net.vm == "@" .. section then
                    luci.sys.call("uci delete qemu." .. net[".name"])
                end
            end)
            
            uci:foreach("qemu", "display", function(display)
                if display.vm == "@" .. section then
                    luci.sys.call("uci delete qemu." .. display[".name"])
                end
            end)
            
            luci.sys.call("uci commit qemu")
            luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "machines"))
        end
    end
    
    return m
end
