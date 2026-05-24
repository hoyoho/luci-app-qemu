module("luci.controller.qemu", package.seeall)

local QEMU_LOGFILE = "/var/log/qemu.log"
local QEMU_ACTIONS = "/usr/lib/qemu/actions"
local translate = require "luci.i18n".translate

local function qemu_log(msg)
	local f = io.open(QEMU_LOGFILE, "a")
	if f then
		f:write(string.format("%s qemu-lua: %s\n", os.date("%Y-%m-%d %H:%M:%S"), msg))
		f:close()
	end
end

local function get_uci()
	return require("luci.model.uci").cursor()
end

local function require_fields(fields, redirect_url)
	for _, field in ipairs(fields) do
		local value = luci.http.formvalue(field)
		if not value or value == "" then
			luci.http.redirect(redirect_url .. "?error=missing_" .. field)
			return false
		end
	end
	return true
end

local function create_disk_bg(format, path, size)
	if size and size ~= "" and format and path then
		os.execute(string.format("%s create_disk_bg %s '%s' %s", QEMU_ACTIONS, format, path, size))
	end
end

local function safe_rename_file(src, dst)
	if not nixio.fs.access(src) then
		return false
	end
	if nixio.fs.access(dst) then
		return false
	end
	local ok = os.rename(src, dst)
	if ok then
		return true
	end
	local ret = os.execute(string.format("cp '%s' '%s' 2>/dev/null", src, dst))
	if ret ~= 0 or not nixio.fs.access(dst) then
		return false
	end
	os.remove(src)
	return true
end

local function replace_in_path(path, old_name, new_name)
	local esc_old = old_name:gsub("([^%w])", "%%%1")
	local result = path:gsub("([/])" .. esc_old .. "([/._-])", "%1" .. new_name .. "%2")
	if result ~= path then
		return result
	end
	result = path:gsub("([/])" .. esc_old .. "$", "%1" .. new_name)
	if result ~= path then
		return result
	end
	local dir, basename = path:match("^(.-)([^/]+)$")
	if dir and basename then
		result = basename:gsub("^" .. esc_old .. "([._-])", new_name .. "%1")
		if result ~= basename then
			return dir .. result
		end
		if basename == old_name then
			return dir .. new_name
		end
	end
	return path
end

function index()
	if not nixio.fs.access("/etc/config/qemu") then
		return
	end

	entry({"admin", "services", "qemu"}, alias("admin", "services", "qemu", "basic"), _("QEMU Virtual Machines"), 100).dependent = true
	entry({"admin", "services", "qemu", "basic"}, cbi("qemu/basic"), _("Basic Settings"), 1).leaf = true
	entry({"admin", "services", "qemu", "machines"}, cbi("qemu/machines/machines"), _("Virtual Machines"), 2).leaf = true
	entry({"admin", "services", "qemu", "machines", ":section"}, cbi("qemu/machines/machines")).leaf = true
	entry({"admin", "services", "qemu", "storage"}, cbi("qemu/storage/storage"), _("Storage"), 3).leaf = true
	entry({"admin", "services", "qemu", "storage", "storage_edit"}, cbi("qemu/storage/storage_edit")).leaf = true
	entry({"admin", "services", "qemu", "storage", "storage_edit", ":section"}, cbi("qemu/storage/storage_edit")).leaf = true
	entry({"admin", "services", "qemu", "storage_wizard"}, call("storage_wizard")).leaf = true
	entry({"admin", "services", "qemu", "networks"}, cbi("qemu/network/networks"), _("Networks"), 5).leaf = true
	entry({"admin", "services", "qemu", "networks", "network_edit"}, cbi("qemu/network/network_edit")).leaf = true
	entry({"admin", "services", "qemu", "networks", "network_edit", ":section"}, cbi("qemu/network/network_edit")).leaf = true
	entry({"admin", "services", "qemu", "display"}, cbi("qemu/display/display"), _("Display"), 4).leaf = true
	entry({"admin", "services", "qemu", "display", "edit"}, cbi("qemu/display/display_edit")).leaf = true
	entry({"admin", "services", "qemu", "display", "edit", ":section"}, cbi("qemu/display/display_edit")).leaf = true
	entry({"admin", "services", "qemu", "input"}, cbi("qemu/input/input"), _("Input"), 6).leaf = true
	entry({"admin", "services", "qemu", "interface"}, cbi("qemu/interface/interface"), _("Interface"), 7).leaf = true
	entry({"admin", "services", "qemu", "sound"}, cbi("qemu/sound/sound"), _("Sound"), 8).leaf = true
	entry({"admin", "services", "qemu", "controller"}, cbi("qemu/controller/controller"), _("Controller"), 9).leaf = true
	entry({"admin", "services", "qemu", "host_dev"}, cbi("qemu/host_dev/host_dev"), _("Host Devices"), 10).leaf = true
	entry({"admin", "services", "qemu", "watchdog"}, cbi("qemu/watchdog/watchdog"), _("Watchdog"), 11).leaf = true

	entry({"admin", "services", "qemu", "wizard"}, call("wizard")).leaf = true
	entry({"admin", "services", "qemu", "status"}, call("act_status")).leaf = true
	entry({"admin", "services", "qemu", "get_log"}, call("get_log")).leaf = true
	entry({"admin", "services", "qemu", "clear_log"}, call("clear_log")).leaf = true
	entry({"admin", "services", "qemu", "delete_vm_info"}, call("delete_vm_info")).leaf = true
	entry({"admin", "services", "qemu", "delete_vm"}, call("delete_vm")).leaf = true
	entry({"admin", "services", "qemu", "clone_vm"}, call("clone_vm")).leaf = true
	entry({"admin", "services", "qemu", "rename_vm"}, call("rename_vm")).leaf = true
	entry({"admin", "services", "qemu", "freeze_vm"}, call("freeze_vm")).leaf = true
	entry({"admin", "services", "qemu", "vm_state"}, call("vm_state")).leaf = true
	entry({"admin", "services", "qemu", "check_vnc_port"}, call("check_vnc_port")).leaf = true
	entry({"admin", "services", "qemu", "check_vm_name"}, call("check_vm_name")).leaf = true
end

function act_status()
	local e = {}
	e.running = luci.sys.call("/etc/init.d/qemu enabled >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function get_log()
	local content = ""
	local f = io.open(QEMU_LOGFILE, "r")
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
	local f = io.open(QEMU_LOGFILE, "w")
	if f then f:close() end
	luci.http.prepare_content("text/plain")
end

function delete_vm_info()
	local section = luci.http.formvalue("section")
	luci.http.prepare_content("application/json")

	if not section or section == "" then
		luci.http.status(400)
		luci.http.write_json({success = false, message = "Missing section"})
		return
	end

	local uci = get_uci()
	local vm_name = uci:get("qemu", section, "name")

	if not vm_name then
		luci.http.status(404)
		luci.http.write_json({success = false, message = "VM not found"})
		return
	end

	local config_items = {}
	local storage_items = {}

	local all_sections = uci:get_all("qemu")
	if all_sections then
		for s_name, s_data in pairs(all_sections) do
			local s_type = s_data[".type"]
			if s_type and s_type ~= "vm" and s_type ~= "global" and s_data.vm == vm_name then
				local label = s_type
				if s_data.id then
					label = s_type .. ": " .. s_data.id
				end

				table.insert(config_items, {
					section = s_name,
					type = s_type,
					label = label
				})

				if s_data.file and s_data.file ~= "" then
					local file_size = nil
					local stat = nixio.fs.stat(s_data.file)
					if stat then
						file_size = stat.size
					end

					table.insert(storage_items, {
						section = s_name,
						type = s_type,
						label = label,
						file = s_data.file,
						size = file_size
					})
				end
			end
		end
	end

	local uefi_enabled = uci:get("qemu", section, "uefi")
	if uefi_enabled == "1" then
		local global_storage_path = uci:get("qemu", "@global[0]", "storage_path") or "/storage/qemu"
		local code_file = global_storage_path .. "/" .. vm_name .. "_code.fd"
		local vars_file = global_storage_path .. "/" .. vm_name .. "_vars.fd"

		if nixio.fs.stat(code_file) then
			local file_size = nixio.fs.stat(code_file).size
			table.insert(storage_items, {
				section = "__uefi_code__",
				type = "uefi",
				label = "UEFI Firmware Code",
				file = code_file,
				size = file_size
			})
		end

		if nixio.fs.stat(vars_file) then
			local file_size = nixio.fs.stat(vars_file).size
			table.insert(storage_items, {
				section = "__uefi_vars__",
				type = "uefi",
				label = "UEFI Firmware Variables",
				file = vars_file,
				size = file_size
			})
		end
	end

	luci.http.write_json({
		success = true,
		vm_name = vm_name,
		config_items = config_items,
		storage_items = storage_items
	})
end

function delete_vm()
	local section = luci.http.formvalue("section")
	local delete_configs = luci.http.formvalue("delete_configs") or ""
	local delete_files = luci.http.formvalue("delete_files") or ""

	luci.http.prepare_content("application/json")

	if not section or section == "" then
		luci.http.status(400)
		luci.http.write_json({success = false, message = "Missing section"})
		return
	end

	local uci = get_uci()
	local vm_name = uci:get("qemu", section, "name")

	if not vm_name then
		luci.http.status(404)
		luci.http.write_json({success = false, message = "VM not found"})
		return
	end

	qemu_log("delete_vm: deleting " .. vm_name)

	local config_set = {}
	for s_name in delete_configs:gmatch("[^,]+") do
		if s_name ~= "" then
			config_set[s_name] = true
		end
	end

	local file_set = {}
	for s_name in delete_files:gmatch("[^,]+") do
		if s_name ~= "" then
			file_set[s_name] = true
		end
	end

	local files_to_remove = {}

	local all_sections = uci:get_all("qemu")
	if all_sections then
		for s_name, s_data in pairs(all_sections) do
			local s_type = s_data[".type"]
			if s_type and s_type ~= "vm" and s_type ~= "global" and s_data.vm == vm_name then
				if config_set[s_name] then
					uci:delete("qemu", s_name)
				end
				if file_set[s_name] and s_data.file and s_data.file ~= "" then
					table.insert(files_to_remove, s_data.file)
				end
			end
		end
	end

	local uefi_enabled = uci:get("qemu", section, "uefi")
	if uefi_enabled == "1" then
		local global_storage_path = uci:get("qemu", "@global[0]", "storage_path") or "/storage/qemu"
		if file_set["__uefi_code__"] then
			table.insert(files_to_remove, global_storage_path .. "/" .. vm_name .. "_code.fd")
		end
		if file_set["__uefi_vars__"] then
			table.insert(files_to_remove, global_storage_path .. "/" .. vm_name .. "_vars.fd")
		end
	end

	uci:delete("qemu", section)
	uci:commit("qemu")

	if #files_to_remove > 0 then
		local args = ""
		for _, f in ipairs(files_to_remove) do
			args = args .. " '" .. f:gsub("'", "'\\''") .. "'"
		end
		os.execute(QEMU_ACTIONS .. " delete_files" .. args .. " >/dev/null 2>&1")
	end

	qemu_log("delete_vm: deleted " .. vm_name)
	luci.http.write_json({success = true})
end

local function create_storage_device(device_type)
	local uci = get_uci()
	local storage_path = uci:get("qemu", "@global[0]", "storage_path") or "/storage/qemu"

	local vm_name       = luci.http.formvalue("vm")
	local device_id     = luci.http.formvalue("id")
	local file_path     = luci.http.formvalue("file")
	local disk_size     = luci.http.formvalue("size")
	local disk_format   = luci.http.formvalue("format")
	local iface         = luci.http.formvalue("iface")
	local readonly      = luci.http.formvalue("readonly") or "0"
	local shareable     = luci.http.formvalue("shareable") or "0"
	local removable     = luci.http.formvalue("removable") or "0"
	local serial        = luci.http.formvalue("serial") or ""
	local cache         = luci.http.formvalue("cache") or ""
	local discard       = luci.http.formvalue("discard") or ""
	local detect_zeroes = luci.http.formvalue("detect_zeroes") or ""
	local mode          = luci.http.formvalue("mode") or "create"

	if not file_path:match("^/") then
		file_path = storage_path .. "/" .. file_path
	end

	local section = uci:add("qemu", device_type)
	uci:set("qemu", section, "vm", vm_name)
	uci:set("qemu", section, "id", device_id)
	uci:set("qemu", section, "file", file_path)
	uci:set("qemu", section, "iface", iface)
	uci:set("qemu", section, "readonly", readonly)
	uci:set("qemu", section, "shareable", shareable)
	uci:set("qemu", section, "removable", removable)
	uci:set("qemu", section, "serial", serial)
	uci:set("qemu", section, "cache", cache)
	uci:set("qemu", section, "discard", discard)
	uci:set("qemu", section, "detect_zeroes", detect_zeroes)

	if device_type == "disk" then
		uci:set("qemu", section, "format", disk_format)
		uci:set("qemu", section, "size", disk_size)
	elseif device_type == "cdrom" then
		uci:set("qemu", section, "media", "cdrom")
	end

	uci:commit("qemu")

	if device_type == "disk" and mode == "create" then
		create_disk_bg(disk_format, file_path, disk_size)
	end
end

function storage_wizard()
	local step = tonumber(luci.http.formvalue("step")) or 1
	local device_type = luci.http.formvalue("device_type") or "disk"

	if luci.http.formvalue("prev") then
		step = step - 1
		if step < 1 then step = 1 end
	elseif luci.http.formvalue("next") then
		step = step + 1
		if step > 3 then step = 3 end
	elseif luci.http.formvalue("create") then
		if not require_fields({"vm", "id", "file", "iface"},
			luci.dispatcher.build_url("admin", "services", "qemu", "storage_wizard")) then
			return
		end

		create_storage_device(device_type)
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "storage"))
		return
	end

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

local function create_vm_from_wizard()
	local uci = get_uci()

	local vm_name           = luci.http.formvalue("name")
	local vm_desc           = luci.http.formvalue("description")
	local vm_autostart      = luci.http.formvalue("autostart") or "0"
	local vm_cpus           = luci.http.formvalue("cpus")
	local vm_memory         = luci.http.formvalue("memory")
	local vm_disk_size      = luci.http.formvalue("disk_size")
	local vm_disk_format    = "qcow2"
	local vm_boot_type      = luci.http.formvalue("boot_type")
	local vm_display        = luci.http.formvalue("display")
	local vm_vnc_port       = luci.http.formvalue("vnc_port")
	local vm_vnc_port_manual = luci.http.formvalue("vnc_port_manual") or "0"
	local vm_cdrom_image    = luci.http.formvalue("cdrom_image")
	local vm_disk_path      = luci.http.formvalue("disk_path")
	local vm_video_type     = luci.http.formvalue("video_type") or "std"

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
	uci:set("qemu", vm_section, "balloon", "1")
	uci:set("qemu", vm_section, "boot", "order=cdn")
	uci:set("qemu", vm_section, "uefi", vm_boot_type == "uefi" and "1" or "0")

	local disk_section = uci:add("qemu", "disk")
	uci:set("qemu", disk_section, "vm", vm_name)
	uci:set("qemu", disk_section, "id", "hd0")
	uci:set("qemu", disk_section, "file", vm_disk_path)
	uci:set("qemu", disk_section, "format", vm_disk_format)
	uci:set("qemu", disk_section, "iface", "virtio")
	uci:set("qemu", disk_section, "media", "disk")
	uci:set("qemu", disk_section, "size", vm_disk_size)
	uci:set("qemu", disk_section, "cache", "")

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

	if vm_display == "vnc" then
		local display_section = uci:add("qemu", "display")
		uci:set("qemu", display_section, "vm", vm_name)
		uci:set("qemu", display_section, "type", "vnc")
		uci:set("qemu", display_section, "port_manual", vm_vnc_port_manual)
		uci:set("qemu", display_section, "address", "0.0.0.0")

		if vm_vnc_port_manual == "1" then
			uci:set("qemu", display_section, "port", vm_vnc_port)
		end

		local video_section = uci:add("qemu", "video")
		uci:set("qemu", video_section, "vm", vm_name)
		uci:set("qemu", video_section, "type", vm_video_type)
	end

	uci:commit("qemu")
	create_disk_bg(vm_disk_format, vm_disk_path, vm_disk_size)
end

function wizard()
	local step = tonumber(luci.http.formvalue("step")) or 1

	if luci.http.formvalue("prev") then
		step = step - 1
		if step < 1 then step = 1 end
	elseif luci.http.formvalue("next") then
		step = step + 1
		if step > 5 then step = 5 end
	elseif luci.http.formvalue("create") then
		if not require_fields({"name", "cpus", "memory", "disk_size", "disk_path"},
			luci.dispatcher.build_url("admin", "services", "qemu", "wizard")) then
			return
		end

		local disk_path = luci.http.formvalue("disk_path")
		if luci.sys.call(QEMU_ACTIONS .. " disk_file_exists '" .. disk_path:gsub("'", "'\\''") .. "'") == 0 then
			luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "wizard") .. "?step=1&error=disk_exists")
			return
		end

		create_vm_from_wizard()
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "machines"))
		return
	end

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

function vm_state()
	local section = luci.http.formvalue("section")
	luci.http.prepare_content("application/json")

	if not section or section == "" then
		luci.http.status(400)
		luci.http.write_json({success = false, message = "Missing section"})
		return
	end

	local uci = get_uci()
	local vm_name = uci:get("qemu", section, "name")
	if not vm_name then
		luci.http.status(404)
		luci.http.write_json({success = false, message = "VM not found"})
		return
	end

	local storage_path = uci:get("qemu", "@global[0]", "storage_path") or "/storage/qemu"
	local state_file = storage_path .. "/" .. vm_name .. ".state.gz"
	local pid = luci.sys.exec("ps | grep -E 'qemu-system.*[[:space:]]-name[[:space:]]+\"?" .. vm_name .. "\"?[[:space:]]' | grep -v grep | awk '{print $1}'"):trim()
	local running = pid ~= ""
	local frozen = uci:get("qemu", section, "frozen") == "1"
	local freezing = uci:get("qemu", section, "freezing") == "1"
	local cloning = uci:get("qemu", section, "cloning") == "1"
	local clone_failed = uci:get("qemu", section, "clone_failed") == "1"
	local has_state = nixio.fs.access(state_file) and frozen

	local freeze_progress = 0
	if freezing and nixio.fs.access(state_file) then
		local stat = nixio.fs.stat(state_file)
		if stat and stat.size then
			freeze_progress = stat.size
		end
	end

	local clone_progress = 0
	if cloning then
		uci:foreach("qemu", "disk", function(s)
			if s.vm == vm_name and s.file then
				local fstat = nixio.fs.stat(s.file)
				if fstat and fstat.size then
					clone_progress = clone_progress + fstat.size
				end
			end
		end)
		local uefi_code = storage_path .. "/" .. vm_name .. "_code.fd"
		local uefi_vars = storage_path .. "/" .. vm_name .. "_vars.fd"
		local code_stat = nixio.fs.stat(uefi_code)
		if code_stat and code_stat.size then
			clone_progress = clone_progress + code_stat.size
		end
		local vars_stat = nixio.fs.stat(uefi_vars)
		if vars_stat and vars_stat.size then
			clone_progress = clone_progress + vars_stat.size
		end
	end

	luci.http.write_json({
		success = true,
		vm_name = vm_name,
		running = running,
		has_state = has_state,
		freezing = freezing,
		cloning = cloning,
		clone_failed = clone_failed,
		freeze_progress = freeze_progress,
		clone_progress = clone_progress
	})
end

function clone_vm()
	local section = luci.http.formvalue("section")
	local new_name = luci.http.formvalue("new_name")
	luci.http.prepare_content("application/json")

	if not section or section == "" then
		luci.http.status(400)
		luci.http.write_json({success = false, message = "Missing section"})
		return
	end

	local uci = get_uci()
	local old_name = uci:get("qemu", section, "name")
	if not old_name then
		luci.http.status(404)
		luci.http.write_json({success = false, message = "VM not found"})
		return
	end

	qemu_log("clone_vm: start clone " .. old_name .. " -> " .. (new_name or old_name .. "-clone"))

	if not new_name or new_name == "" then
		new_name = old_name .. "-clone"
	end

	local pid = luci.sys.exec("ps | grep -E 'qemu-system.*[[:space:]]-name[[:space:]]+\"?" .. old_name .. "\"?[[:space:]]' | grep -v grep | awk '{print $1}'"):trim()
	if pid ~= "" then
		luci.http.write_json({success = false, message = "Cannot clone a running VM. Please stop it first."})
		return
	end

	local all_existing = uci:get_all("qemu") or {}
	for s_name, s_data in pairs(all_existing) do
		if s_data[".type"] == "vm" and s_data.name == new_name then
			luci.http.write_json({success = false, message = "A VM with this name already exists."})
			return
		end
	end

	local tmpfile = "/tmp/qemu_clone." .. section
	local cmd = string.format("%s clone_vm '%s' '%s' > '%s' 2>/dev/null",
		QEMU_ACTIONS,
		section:gsub("'", "'\\''"),
		new_name:gsub("'", "'\\''"),
		tmpfile)
	local ret = os.execute(cmd)

	local new_vm_section = ""
	local f = io.open(tmpfile)
	if f then
		new_vm_section = f:read("*a"):trim()
		f:close()
	end
	os.execute("rm -f " .. tmpfile)

	if ret ~= 0 or new_vm_section == "" then
		if ret == 4 then
			qemu_log("clone_vm: clone already in progress for " .. old_name)
			luci.http.write_json({success = false, message = translate("A clone operation is already in progress for this VM.")})
		elseif ret == 3 then
			qemu_log("clone_vm: clone failed (insufficient disk space) for " .. old_name)
			luci.http.write_json({success = false, message = translate("Clone failed: insufficient disk space on target storage.")})
		elseif ret == 2 then
			qemu_log("clone_vm: clone failed (name conflict) for " .. old_name)
			luci.http.write_json({success = false, message = translate("A VM with this name already exists.")})
		else
			qemu_log("clone_vm: clone failed for " .. old_name)
			luci.http.write_json({success = false, message = "Clone failed."})
		end
		return
	end

	qemu_log("clone_vm: clone succeeded, new section=" .. new_vm_section)

	local uci2 = get_uci()
	local has_cloning = uci2:get("qemu", new_vm_section, "cloning") == "1"
	local new_name_final = uci2:get("qemu", new_vm_section, "name") or new_name

	luci.http.write_json({
		success = true,
		new_section = new_vm_section,
		new_name = new_name_final,
		cloning = has_cloning
	})
end

function freeze_vm()
	local section = luci.http.formvalue("section")
	luci.http.prepare_content("application/json")

	if not section or section == "" then
		luci.http.status(400)
		luci.http.write_json({success = false, message = "Missing section"})
		return
	end

	local uci = get_uci()
	local vm_name = uci:get("qemu", section, "name")
	if not vm_name then
		luci.http.status(404)
		luci.http.write_json({success = false, message = "VM not found"})
		return
	end

	qemu_log("freeze_vm: freezing " .. vm_name)

	local pid = luci.sys.exec("ps | grep -E 'qemu-system.*[[:space:]]-name[[:space:]]+\"?" .. vm_name .. "\"?[[:space:]]' | grep -v grep | awk '{print $1}'"):trim()
	if pid == "" then
		luci.http.write_json({success = false, message = "VM is not running"})
		return
	end

	local storage_path = uci:get("qemu", "@global[0]", "storage_path") or "/storage/qemu"
	local state_file = storage_path .. "/" .. vm_name .. ".state.gz"

	if nixio.fs.access(state_file) then
		luci.http.write_json({success = false, message = "VM already has a frozen state. Resume it first."})
		return
	end

	uci:set("qemu", section, "freezing", "1")
	uci:commit("qemu")

	local cmd = string.format(
		"( %s freeze_vm '%s' '%s' && " ..
		"uci set qemu.%s.frozen=1 && uci delete qemu.%s.freezing && uci commit qemu && " ..
		"rm -f /var/run/qemu-freeze-%s.pid ) || " ..
		"( uci delete qemu.%s.freezing && uci commit qemu && rm -f /var/run/qemu-freeze-%s.pid )",
		QEMU_ACTIONS, vm_name, state_file, section, section, section, section, section
	)
	os.execute(string.format("( %s ) & echo $! > /var/run/qemu-freeze-%s.pid", cmd, section))

	luci.http.write_json({success = true, freezing = true})
end

function rename_vm()
	local section = luci.http.formvalue("section")
	local new_name = luci.http.formvalue("new_name")
	luci.http.prepare_content("application/json")

	if not section or section == "" then
		luci.http.status(400)
		luci.http.write_json({success = false, message = "Missing section"})
		return
	end
	if not new_name or new_name == "" then
		luci.http.status(400)
		luci.http.write_json({success = false, message = "Missing new VM name"})
		return
	end

	local uci = get_uci()
	local old_name = uci:get("qemu", section, "name")
	if not old_name then
		luci.http.status(404)
		luci.http.write_json({success = false, message = "VM not found"})
		return
	end

	qemu_log("rename_vm: renaming " .. old_name .. " -> " .. new_name)

	if old_name == new_name then
		luci.http.write_json({success = true})
		return
	end

	local pid = luci.sys.exec("ps | grep -E 'qemu-system.*[[:space:]]-name[[:space:]]+\"?" .. old_name .. "\"?[[:space:]]' | grep -v grep | awk '{print $1}'"):trim()
	if pid ~= "" then
		luci.http.write_json({success = false, message = "Cannot rename a running VM. Please stop it first."})
		return
	end

	local all_existing = uci:get_all("qemu") or {}
	for s_name, s_data in pairs(all_existing) do
		if s_data[".type"] == "vm" and s_data.name == new_name then
			luci.http.write_json({success = false, message = "A VM with this name already exists."})
			return
		end
	end

	local storage_path = uci:get("qemu", "@global[0]", "storage_path") or "/storage/qemu"

	uci:set("qemu", section, "name", new_name)

	local rename_tasks = {}

	local all_sections = uci:get_all("qemu") or {}
	for s_name, s_data in pairs(all_sections) do
		local s_type = s_data[".type"]
		if s_type and s_type ~= "vm" and s_type ~= "global" and s_data.vm == old_name then
			uci:set("qemu", s_name, "vm", new_name)

			local file_val = uci:get("qemu", s_name, "file")
			if file_val and file_val ~= "" then
				local new_file = replace_in_path(file_val, old_name, new_name)
				uci:set("qemu", s_name, "file", new_file)
				if nixio.fs.access(file_val) and not nixio.fs.access(new_file) then
					table.insert(rename_tasks, {src = file_val, dst = new_file})
				end
			end

			if s_type == "interface_file" then
				local path_val = uci:get("qemu", s_name, "path")
				if path_val and path_val ~= "" then
					local new_path = replace_in_path(path_val, old_name, new_name)
					uci:set("qemu", s_name, "path", new_path)
				end
			end
		end
	end

	local old_data = uci:get_all("qemu")[section]
	if old_data and old_data.uefi == "1" then
		local uefi_code_old = storage_path .. "/" .. old_name .. "_code.fd"
		local uefi_vars_old = storage_path .. "/" .. old_name .. "_vars.fd"
		local uefi_code_new = storage_path .. "/" .. new_name .. "_code.fd"
		local uefi_vars_new = storage_path .. "/" .. new_name .. "_vars.fd"
		if nixio.fs.access(uefi_code_old) and not nixio.fs.access(uefi_code_new) then
			table.insert(rename_tasks, {src = uefi_code_old, dst = uefi_code_new})
		end
		if nixio.fs.access(uefi_vars_old) and not nixio.fs.access(uefi_vars_new) then
			table.insert(rename_tasks, {src = uefi_vars_old, dst = uefi_vars_new})
		end
	end

	local old_state = storage_path .. "/" .. old_name .. ".state.gz"
	local new_state = storage_path .. "/" .. new_name .. ".state.gz"
	if nixio.fs.access(old_state) and not nixio.fs.access(new_state) then
		table.insert(rename_tasks, {src = old_state, dst = new_state})
	end

	uci:commit("qemu")

	for _, task in ipairs(rename_tasks) do
		safe_rename_file(task.src, task.dst)
	end

	qemu_log("rename_vm: rename completed " .. old_name .. " -> " .. new_name)
	luci.http.write_json({success = true, new_name = new_name})
end

function check_vnc_port()
	local port = luci.http.formvalue("port")
	local exclude_vm = luci.http.formvalue("exclude_vm")
	luci.http.prepare_content("application/json")

	if not port or port == "" then
		luci.http.status(400)
		luci.http.write_json({conflict = false, message = "Missing port"})
		return
	end

	local uci = get_uci()
	local ret = {conflict = false}

	uci:foreach("qemu", "display", function(s)
		if s.port_manual == "1" and s.port == port then
			if not exclude_vm or exclude_vm == "" or s.vm ~= exclude_vm then
				ret.conflict = true
				ret.vm_name = s.vm
				ret.port = port
				return false
			end
		end
	end)

	luci.http.write_json(ret)
end

function check_vm_name()
	local name = luci.http.formvalue("name")
	luci.http.prepare_content("application/json")

	if not name or name == "" then
		luci.http.status(400)
		luci.http.write_json({available = false, message = "Missing name"})
		return
	end

	local uci = get_uci()
	local all_existing = uci:get_all("qemu") or {}
	for s_name, s_data in pairs(all_existing) do
		if s_data[".type"] == "vm" and s_data.name == name then
			luci.http.write_json({available = false, message = translate("A VM with this name already exists.")})
			return
		end
	end

	luci.http.write_json({available = true})
end