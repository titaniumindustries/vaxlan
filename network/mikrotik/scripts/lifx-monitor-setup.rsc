# LIFX Bulb CAPsMAN Monitoring Setup
# RouterOS 6.x compatible
#
# This creates a script + scheduler that logs LIFX bulb WiFi status
# every 60 seconds to the system log. Useful for diagnosing intermittent
# LIFX WiFi disconnections.
#
# To apply: paste into RouterOS terminal or import via SSH
# To remove: /system script remove lifx-capsman-monitor
#            /system scheduler remove lifx-capsman-monitor

# Create the monitoring script
/system script
add name=lifx-capsman-monitor policy=read,test source={
  :local lifxCount 0
  :foreach i in=[/caps-man registration-table find] do={
    :local mac [/caps-man registration-table get $i mac-address]
    :local macPrefix [:pick $mac 0 8]
    :if ($macPrefix = "D0:73:D5") do={
      :local sig [/caps-man registration-table get $i rx-signal]
      :local up [/caps-man registration-table get $i uptime]
      :local iface [/caps-man registration-table get $i interface]
      :local ssid [/caps-man registration-table get $i ssid]
      :log info ("LIFX-MON: mac=" . $mac . " sig=" . $sig . " up=" . $up . " if=" . $iface . " ssid=" . $ssid)
      :set lifxCount ($lifxCount + 1)
    }
  }
  :log info ("LIFX-MON: total=" . $lifxCount . " bulbs registered")
}

# Create scheduler to run every 60 seconds
/system scheduler
add name=lifx-capsman-monitor interval=1m on-event=lifx-capsman-monitor policy=read,test comment="LIFX bulb WiFi monitoring - temporary diagnostic"
