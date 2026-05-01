module("luci.controller.qemu", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/qemu") then
		return
	end

	entry({"admin", "services", "qemu"}, alias("admin", "services", "qemu", "basic"), _("QEMU Virtual Machines"), 100).dependent = true
	entry({"admin", "services", "qemu", "basic"}, cbi("qemu/basic"), _("Basic Settings"), 1).leaf = true
	entry({"admin", "services", "qemu", "machines"}, cbi("qemu/machines/machines"), _("Virtual Machines"), 1).leaf = true
	entry({"admin", "services", "qemu", "machines", ":section"}, cbi("qemu/machines/machines")).leaf = true
	entry({"admin", "services", "qemu", "storage"}, cbi("qemu/storage/storage"), _("Storage"), 3).leaf = true
	entry({"admin", "services", "qemu", "storage", "storage_edit"}, cbi("qemu/storage/storage_edit")).leaf = true
	entry({"admin", "services", "qemu", "storage", "storage_edit", ":section"}, cbi("qemu/storage/storage_edit")).leaf = true
	entry({"admin", "services", "qemu", "storage_wizard"}, call("storage_wizard")).leaf = true
	entry({"admin", "services", "qemu", "networks"}, cbi("qemu/network/networks"), _("Networks"), 6).leaf = true
	entry({"admin", "services", "qemu", "networks", "network_edit"}, cbi("qemu/network/network_edit")).leaf = true
	entry({"admin", "services", "qemu", "networks", "network_edit", ":section"}, cbi("qemu/network/network_edit")).leaf = true
	entry({"admin", "services", "qemu", "display"}, cbi("qemu/display/display"), _("Display"), 5).leaf = true
	entry({"admin", "services", "qemu", "display", "edit"}, cbi("qemu/display/display_edit")).leaf = true
	entry({"admin", "services", "qemu", "display", "edit", ":section"}, cbi("qemu/display/display_edit")).leaf = true
	entry({"admin", "services", "qemu", "input"}, cbi("qemu/input/input"), _("Input"), 7).leaf = true
	entry({"admin", "services", "qemu", "interface"}, cbi("qemu/interface/interface"), _("Interface")).leaf = true
	entry({"admin", "services", "qemu", "sound"}, cbi("qemu/sound/sound"), _("Sound")).leaf = true
	entry({"admin", "services", "qemu", "controller"}, cbi("qemu/controller/controller"), _("Controller")).leaf = true
	entry({"admin", "services", "qemu", "host_dev"}, cbi("qemu/host_dev/host_dev"), _("Host Devices")).leaf = true
	entry({"admin", "services", "qemu", "watchdog"}, cbi("qemu/watchdog/watchdog"), _("Watchdog")).leaf = true

	entry({"admin", "services", "qemu", "channel"}, cbi("qemu/channel/channel"), _("Channel")).leaf = true
	entry({"admin", "services", "qemu", "vsock"}, cbi("qemu/vsock/vsock"), _("Virtio VSOCK")).leaf = true
	entry({"admin", "services", "qemu", "wizard"}, call("wizard")).leaf = true
	entry({"admin", "services", "qemu", "status"}, call("act_status")).leaf = true
	entry({"admin", "services", "qemu", "get_log"}, call("get_log")).leaf = true
	entry({"admin", "services", "qemu", "clear_log"}, call("clear_log")).leaf = true
end

function act_status()
	local e = {}
	e.running = luci.sys.call("/etc/init.d/qemu enabled >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function get_log()
	-- 使用系统日志，通过logread命令获取qemu相关日志
	local content = ""
	local cmd = "logread | grep -i qemu"
	local f = io.popen(cmd)
	if f then
		content = f:read("*a")
		f:close()
	end
	
	if content == "" then
		content = "No qemu logs found"
	end
	
	luci.http.prepare_content("text/plain")
	luci.http.write(content)
end

function clear_log()
	-- 通过重启log服务来清理日志
	luci.sys.call("/etc/init.d/log restart")
	luci.http.prepare_content("text/plain")
end

function storage_wizard()
	local step = tonumber(luci.http.formvalue("step")) or 1
	local device_type = luci.http.formvalue("device_type") or "disk"
	
	if luci.http.formvalue("prev") then
		step = step - 1
		if step < 1 then
			step = 1
		end
		luci.sys.call('logger -t qemu "prev clicked, new step: ' .. step .. '"')
	elseif luci.http.formvalue("next") then
		step = step + 1
		if step > 3 then
			step = 3
		end
		luci.sys.call('logger -t qemu "next clicked, new step: ' .. step .. '"')
	elseif luci.http.formvalue("create") then
		luci.sys.call('logger -t qemu "create clicked"')
		
		-- 创建存储设备配置
		local uci = require("luci.model.uci").cursor()
		local vm_name = luci.http.formvalue("vm")
		local device_id = luci.http.formvalue("id")
		local file_path = luci.http.formvalue("file")
		local disk_size = luci.http.formvalue("size")
		local disk_format = luci.http.formvalue("format")
		local iface = luci.http.formvalue("iface")
		local readonly = luci.http.formvalue("readonly") or "0"
		local shareable = luci.http.formvalue("shareable") or "0"
		local removable = luci.http.formvalue("removable") or "0"
		local serial = luci.http.formvalue("serial") or ""
		local cache = luci.http.formvalue("cache") or ""
		local discard = luci.http.formvalue("discard") or ""
		local detect_zeroes = luci.http.formvalue("detect_zeroes") or ""
		
		-- 记录表单数据
		luci.sys.call('logger -t qemu "vm: ' .. (vm_name or "nil") .. '"')
		luci.sys.call('logger -t qemu "id: ' .. (device_id or "nil") .. '"')
		luci.sys.call('logger -t qemu "file: ' .. (file_path or "nil") .. '"')
		luci.sys.call('logger -t qemu "size: ' .. (disk_size or "nil") .. '"')
		luci.sys.call('logger -t qemu "format: ' .. (disk_format or "nil") .. '"')
		luci.sys.call('logger -t qemu "iface: ' .. (iface or "nil") .. '"')
		
		-- 获取全局存储路径
		local storage_path = uci:get("qemu", "@global[0]", "storage_path") or "/storage/qemu"
		
		-- 处理文件路径
		if not file_path:match("^/") then
			file_path = storage_path .. "/" .. file_path
		end
		
		-- 创建设备配置
		local device_section = uci:add("qemu", device_type)
		uci:set("qemu", device_section, "vm", vm_name)
		uci:set("qemu", device_section, "id", device_id)
		uci:set("qemu", device_section, "file", file_path)
		uci:set("qemu", device_section, "iface", iface)
		uci:set("qemu", device_section, "readonly", readonly)
		uci:set("qemu", device_section, "shareable", shareable)
		uci:set("qemu", device_section, "removable", removable)
		uci:set("qemu", device_section, "serial", serial)
		uci:set("qemu", device_section, "cache", cache)
		uci:set("qemu", device_section, "discard", discard)
		uci:set("qemu", device_section, "detect_zeroes", detect_zeroes)
		
		-- 获取模式参数
		local mode = luci.http.formvalue("mode") or "create"
		luci.sys.call('logger -t qemu "mode: ' .. mode .. '"')
		
		if device_type == "disk" then
			uci:set("qemu", device_section, "format", disk_format)
			uci:set("qemu", device_section, "size", disk_size)
		elseif device_type == "cdrom" then
			uci:set("qemu", device_section, "media", "cdrom")
		end
		
		-- 保存配置
		uci:commit("qemu")
		luci.sys.call('logger -t qemu "configuration saved"')
		
		-- 准备后台执行的命令（仅对磁盘且模式为create）
		local disk_cmd
		if device_type == "disk" and mode == "create" then
			disk_cmd = string.format("(qemu-img create -f %s %s %sG >/dev/null 2>&1) &", disk_format, file_path, disk_size)
			luci.sys.call('logger -t qemu "preparing to execute in background: ' .. disk_cmd .. '"')
		elseif device_type == "disk" and mode == "import" then
			luci.sys.call('logger -t qemu "importing existing disk, skipping qemu-img create"')
		end
		
		-- 重定向到存储设备列表
		luci.sys.call('logger -t qemu "redirecting to storage list"')
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "storage"))
		
		-- 在重定向后执行磁盘创建命令（不会阻塞响应）
		if disk_cmd then
			os.execute(disk_cmd)
			luci.sys.call('logger -t qemu "qemu-img create started in background"')
		end
		
		return
	end
	
	-- 传递所有表单数据到模板
	luci.template.render("qemu/storage_wizard", {
		step = step,
		device_type = device_type,
		vm = luci.http.formvalue("vm"),
		id = luci.http.formvalue("id"),
		file = luci.http.formvalue("file"),
		size = luci.http.formvalue("size"),
		format = luci.http.formvalue("format"),
		iface = luci.http.formvalue("iface"),
		readonly = luci.http.formvalue("readonly"),
		shareable = luci.http.formvalue("shareable"),
		removable = luci.http.formvalue("removable"),
		serial = luci.http.formvalue("serial"),
		cache = luci.http.formvalue("cache"),
		discard = luci.http.formvalue("discard"),
		detect_zeroes = luci.http.formvalue("detect_zeroes")
	})
end

function wizard()
	local step = tonumber(luci.http.formvalue("step")) or 1
	
	if luci.http.formvalue("prev") then
		step = step - 1
		if step < 1 then
			step = 1
		end
		luci.sys.call('logger -t qemu "prev clicked, new step: ' .. step .. '"')
	elseif luci.http.formvalue("next") then
		step = step + 1
		if step > 6 then
			step = 6
		end
		luci.sys.call('logger -t qemu "next clicked, new step: ' .. step .. '"')
	elseif luci.http.formvalue("create") then
		-- 创建虚拟机配置
		local uci = require("luci.model.uci").cursor()
		local vm_name = luci.http.formvalue("name")
		local vm_desc = luci.http.formvalue("description")
		local vm_autostart = luci.http.formvalue("autostart") or "0"
		local vm_cpus = luci.http.formvalue("cpus")
		local vm_memory = luci.http.formvalue("memory")
		local vm_disk_size = luci.http.formvalue("disk_size")
		-- 固定使用 qcow2 格式
		local vm_disk_format = "qcow2"
		local vm_bridge = luci.http.formvalue("bridge")
		local vm_boot_type = luci.http.formvalue("boot_type")
		local vm_display = luci.http.formvalue("display")
		local vm_vnc_port = luci.http.formvalue("vnc_port")
		local vm_vnc_port_mannual = luci.http.formvalue("vnc_port_mannual") or "0"
		local vm_cdrom_image = luci.http.formvalue("cdrom_image")
		local vm_disk_path = luci.http.formvalue("disk_path")
		local vm_video_type = luci.http.formvalue("video_type") or "vga"
		
		-- 检查磁盘文件是否已存在
		local file = io.open(vm_disk_path, "r")
		if file then
			file:close()
			-- 文件已存在，重定向回向导页面并显示警告
			luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "wizard") .. "?step=1&error=disk_exists")
			return
		end
		
		-- 创建虚拟机配置
		local vm_section = uci:add("qemu", "vm")
		uci:set("qemu", vm_section, "name", vm_name)
		uci:set("qemu", vm_section, "description", vm_desc)
		uci:set("qemu", vm_section, "autostart", vm_autostart)
		uci:set("qemu", vm_section, "machine", "q35")
		uci:set("qemu", vm_section, "accel", "kvm")
		uci:set("qemu", vm_section, "cpu_model", "host")
		uci:set("qemu", vm_section, "smp_sockets", "1")
		uci:set("qemu", vm_section, "smp_cores", vm_cpus)
		uci:set("qemu", vm_section, "smp_threads", "1")
		uci:set("qemu", vm_section, "mem_size", vm_memory)
		uci:set("qemu", vm_section, "boot", "order=cdn")
		uci:set("qemu", vm_section, "uefi", vm_boot_type == "uefi" and "1" or "0")

		-- 创建磁盘配置
		local disk_section = uci:add("qemu", "disk")
		uci:set("qemu", disk_section, "vm", vm_name)
		uci:set("qemu", disk_section, "id", "hd0")
		uci:set("qemu", disk_section, "file", vm_disk_path)
		uci:set("qemu", disk_section, "format", vm_disk_format)
		uci:set("qemu", disk_section, "iface", "virtio")
		uci:set("qemu", disk_section, "media", "disk")
		uci:set("qemu", disk_section, "size", vm_disk_size)
		uci:set("qemu", disk_section, "cache", "")
		
		-- 创建光驱配置（如果提供了ISO镜像路径）
		if vm_cdrom_image and vm_cdrom_image ~= "" then
			local cdrom_section = uci:add("qemu", "cdrom")
			uci:set("qemu", cdrom_section, "vm", vm_name)
			uci:set("qemu", cdrom_section, "id", "cd0")
			uci:set("qemu", cdrom_section, "file", vm_cdrom_image)
			uci:set("qemu", cdrom_section, "format", "raw")
			uci:set("qemu", cdrom_section, "iface", "ide")
			uci:set("qemu", cdrom_section, "media", "cdrom")
			uci:set("qemu", cdrom_section, "readonly", "1")
		end
		
		-- 创建显示配置
		if vm_display == "vnc" then
			local display_section = uci:add("qemu", "display")
			uci:set("qemu", display_section, "vm", vm_name)
			uci:set("qemu", display_section, "type", "vnc")
			uci:set("qemu", display_section, "port_mannual", vm_vnc_port_mannual)
			uci:set("qemu", display_section, "address", "0.0.0.0")

			-- 只有当使用手动端口时才写入端口配置
			if vm_vnc_port_mannual == "1" then
				uci:set("qemu", display_section, "port", vm_vnc_port)
			end

			-- 创建视频设备配置
			local video_section = uci:add("qemu", "video")
			uci:set("qemu", video_section, "vm", vm_name)
			uci:set("qemu", video_section, "type", vm_video_type)
		end
		
		-- 保存配置
		uci:commit("qemu")
		
		-- 准备磁盘创建命令
		local disk_cmd = string.format("(qemu-img create -f %s %s %sG >/dev/null 2>&1) &", vm_disk_format, vm_disk_path, vm_disk_size)
		luci.sys.call('logger -t qemu "preparing disk create command: ' .. disk_cmd .. '"')
		
		-- 重定向到虚拟机列表
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "machines"))
		
		-- 在重定向后执行磁盘创建命令（不会阻塞响应）
		os.execute(disk_cmd)
		luci.sys.call('logger -t qemu "qemu-img create started in background"')
		
		return
	end

	-- 传递所有表单数据到模板
	luci.template.render("qemu/machine_wizard", {
		step = step,
		name = luci.http.formvalue("name"),
		description = luci.http.formvalue("description"),
		autostart = luci.http.formvalue("autostart"),
		cpus = luci.http.formvalue("cpus"),
		memory = luci.http.formvalue("memory"),
		disk_size = luci.http.formvalue("disk_size"),
		disk_format = luci.http.formvalue("disk_format"),
		cdrom_image = luci.http.formvalue("cdrom_image"),
		bridge = luci.http.formvalue("bridge"),
		boot_type = luci.http.formvalue("boot_type"),
		display = luci.http.formvalue("display"),
		vnc_port = luci.http.formvalue("vnc_port")
	})
end