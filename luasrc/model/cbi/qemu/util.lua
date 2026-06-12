local M = {}

function M.get_vm_list()
	local vm_list = {}
	local uci = require("luci.model.uci").cursor()
	uci:foreach("qemu", "vm", function(s)
		table.insert(vm_list, {name = s.name or s['.name'], title = s.name or s['.name']})
	end)
	return vm_list
end

function M.find_section_type(section_id, type_list)
	if not section_id then return "" end
	local uci = require("luci.model.uci").cursor()
	for _, t in ipairs(type_list) do
		local found = false
		uci:foreach("qemu", t, function(s)
			if s[".name"] == section_id then
				found = true
				return false
			end
		end)
		if found then return t end
	end
	return ""
end

function M.section_exists(section_id, type_name)
	if not section_id or not type_name then return false end
	local uci = require("luci.model.uci").cursor()
	local exists = false
	uci:foreach("qemu", type_name, function(s)
		if s[".name"] == section_id then
			exists = true
			return false
		end
	end)
	return exists
end

return M
