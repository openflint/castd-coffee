#
# Copyright (C) 2013-2014, Infthink (Beijing) Technology Co., Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#    limitations under the License.
#

events = require "events"
uuid = require "uuid"
url = require "url"
path = require "path"

{ Platform } = rekuire "castaway/sys/Platform"

# device desc template
device_desc = """
<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
    <specVersion>
        <major>1</major>
        <minor>0</minor>
    </specVersion>
    <URLBase>http://{{ serviceURL }}</URLBase>
    <device>
        <deviceType>urn:dial-multiscreen-org:device:dial:1</deviceType>
        <friendlyName>{{ friendlyName }}</friendlyName>
        <manufacturer>{{ manufacturer }}</manufacturer>
        <modelName>{{ modelName }}</modelName>
        <UDN>uuid:{{ uuid }}</UDN>
        <serviceList>
            <service>
                <serviceType>urn:dial-multiscreen-org:service:dial:1</serviceType>
                <serviceId>urn:dial-multiscreen-org:serviceId:dial</serviceId>
                <controlURL>/ssdp/notfound</controlURL>
                <eventSubURL>/ssdp/notfound</eventSubURL>
                <SCPDURL>/ssdp/notfound</SCPDURL>
            </service>
        </serviceList>
    </device>
</root>
"""

#
# DeviceDescHandler
#
class DeviceDescHandler

    # Handle http request
    onHttpRequest: (req, res) ->
        desc = device_desc
        host = req.headers.host
        name = Platform.getInstance().getDeviceName()
        uuid = Platform.getInstance().getDeviceUUID()

        name = name.replace "<", ""
        name = name.replace ">", ""
        name = name.replace "&", ""

        desc = desc.replace "{{ serviceURL }}", host
        desc = desc.replace "{{ friendlyName }}", name
        desc = desc.replace "{{ manufacturer }}", "Google Inc."
        desc = desc.replace "{{ modelName }}", "Eureka Dongle"
        desc = desc.replace "{{ uuid }}", uuid

        buff = new Buffer desc
        res.writeHead 200,
            "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
            "Access-Control-Expose-Headers": "Application-URL",
            "Application-URL": "http://" + host + "/apps",
            "Access-Control-Allow-Origin": "https://www.google.com",
            "Content-Type": "application/xml",
            "Content-Length": buff.length
        res.end buff

module.exports.DeviceDescHandler = DeviceDescHandler
