require "luci.http"
require "luci.sys"
require "nixio.fs"
require "luci.dispatcher"
require "luci.model.uci"

math.randomseed(os.time())

local section_id = arg[1]
local util = require("luci.model.cbi.qemu.util")
local full_type = util.find_section_type(section_id, {"net_bridge", "net_user", "net_tap", "net_l2tpv3", "net_socket"})
local edit_type = full_type ~= "" and full_type:gsub("^net_", "") or "bridge"

m = Map("qemu", translate("Edit Network Interface"))
m.redirect = luci.dispatcher.build_url("admin", "services", "qemu", "networks")
m.pageaction = true
m.on_init = function(self)
    if section_id and not util.section_exists(section_id, "net_" .. edit_type) then
        luci.http.redirect(luci.dispatcher.build_url("admin", "services", "qemu", "networks"))
    end
end

local s = m:section(NamedSection, section_id, "net_" .. edit_type)
s.addremove = false
s.anonymous = false

s:tab("general", translate("General Settings"))

vm = s:taboption("general", ListValue, "vm", translate("Virtual Machine"))
vm.rmempty = true

local vm_list = require("luci.model.cbi.qemu.util").get_vm_list()
for _, vm_item in ipairs(vm_list) do
    vm:value(vm_item.name, vm_item.title)
end

o = s:taboption("general", Value, "id", translate("Interface ID"))
o.default = "0"
o.datatype = "uinteger"

o = s:taboption("general", Value, "mac", translate("MAC Address"))
o.default = "52:54:00:" .. string.format("%02x:%02x:%02x", math.random(0, 255), math.random(0, 255), math.random(0, 255))
o.description = translate("MAC address for the network interface")

o = s:taboption("general", ListValue, "model", translate("Model"))
o:value("virtio-net-pci", translate("VirtIO"))
o:value("e1000", translate("e1000"))
o:value("e1000e", translate("e1000e"))
o:value("rtl8139", translate("RTL8139"))
o:value("ne2k_pci", translate("NE2000 PCI"))
o:value("pcnet", translate("PCNet"))
o.default = "virtio-net-pci"
o.description = translate("Network device model")

if edit_type == "bridge" then
    o = s:taboption("general", Value, "bridge", translate("Bridge"))
    o.default = "br-lan"
    o.description = translate("Bridge interface name")

    o = s:taboption("general", Value, "helper", translate("Bridge Helper"))
    o.default = "/usr/lib/qemu-bridge-helper"
    o.description = translate("Path to bridge helper program")
elseif edit_type == "user" then
    o = s:taboption("general", Value, "hostfwd", translate("Port Forwarding"))
    o.description = translate("Port forwarding rules (e.g., tcp::2222-:22)")

    o = s:taboption("general", Value, "net", translate("Network"))
    o.default = "10.0.2.0/24"
    o.description = translate("Network address and subnet mask")

    o = s:taboption("general", Value, "dhcpstart", translate("DHCP Start"))
    o.default = "10.0.2.15"
    o.description = translate("Start address for DHCP server")

    o = s:taboption("general", Value, "dns", translate("DNS Server"))
    o.default = "10.0.2.3"
    o.description = translate("DNS server address")
elseif edit_type == "tap" then
    o = s:taboption("general", Value, "ifname", translate("TAP Device Name"))
    o.default = "tap0"
    o.description = translate("Name of the TAP interface")

    o = s:taboption("general", Value, "script", translate("Config Script"))
    o.default = "/etc/qemu-ifup"
    o.description = translate("Script to configure the TAP interface")

    o = s:taboption("general", Value, "downscript", translate("Down Script"))
    o.default = "/etc/qemu-ifdown"
    o.description = translate("Script to deconfigure the TAP interface")

    o = s:taboption("general", Value, "sndbuf", translate("Send Buffer Size"))
    o.default = "0"
    o.datatype = "uinteger"
    o.description = translate("Size of the send buffer in bytes (0 = disabled)")
elseif edit_type == "l2tpv3" then
    o = s:taboption("general", Value, "src", translate("Source Address"))
    o.description = translate("Source IP address for L2TPv3")

    o = s:taboption("general", Value, "dst", translate("Destination Address"))
    o.description = translate("Destination IP address for L2TPv3")

    o = s:taboption("general", Value, "txsession", translate("TX Session"))
    o.description = translate("TX session ID for L2TPv3")

    o = s:taboption("general", Value, "srcport", translate("Source Port"))
    o.description = translate("Source port for L2TPv3")

    o = s:taboption("general", Value, "dstport", translate("Destination Port"))
    o.description = translate("Destination port for L2TPv3")
elseif edit_type == "socket" then
    o = s:taboption("general", Value, "connect", translate("Connect"))
    o.description = translate("[Host:Port] to connect to")

    o = s:taboption("general", Value, "listen", translate("Listen"))
    o.description = translate("[Host:Port] to listen on")
end

return m