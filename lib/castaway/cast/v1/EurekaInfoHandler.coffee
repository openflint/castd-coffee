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

{ Platform } = rekuire "castaway/sys/Platform"

#
# InfoHandler
#
class EurekaInfoHandler extends events.EventEmitter

    # Handle http request
    onHttpRequest: (req, res) ->
        host = req.headers.host
        uuid = Platform.getInstance().getDeviceUUID()
        eurekaInfo =
            build_version: "1.1406070052"
            connected: true
            detail:
                locale:
                    display_string: "English (United States)"
                timezone:
                    display_string: "America/Los Angeles"
                    offset: -480
            has_update: false
            hdmi_control: true
            hotspot_bssid: "FA:8F:CA:3A:0C:D0"
            locale: "en_US"
            mac_address: "00:00:00:00:00:00"
            name: ""
            noise_level: -90
            opt_in:
                crash: true
                device_id: false
                stats: true
            public_key: "MIIBCgKCAQEAyoaWlKNT6W5+/cJXEpIfeGvogtJ1DghEUs2PmHkX3n4bByfmMRDYjuhcb97vd8N3HFe5sld6QSc+FJz7TSGp/700e6nrkbGj9abwvobey/IrLbHTPLtPy/ceUnwmAXczkhay32auKTaM5ZYjwcHZkaU9XuOQVIPpyLF1yQerFChugCpQ+bvIoJnTkoZAuV1A1Vp4qf3nn4Ll9Bi0R4HJrGNmOKUEjKP7H1aCLSqj13FgJ2s2g20CCD8307Otq8n5fR+9/c01dtKgQacupysA+4LVyk4npFn5cXlzkkNPadcKskARtb9COTP2jBWcowDwjKSBokAgi/es/5gDhZm4dwIDAQAB"
            release_track: "stable-channel"
            setup_state: 60
            signal_level: -50
            ssdp_udn: uuid
            ssid: ""
            timezone: "America/Los_Angeles"
            uptime: 0.0
            version: 4
            wpa_configured: true
            wpa_state: 10

        respText = JSON.stringify eurekaInfo
        res.writeHead 200,
            "Content-Type": "application/json"
            "Content-Length": respText.length
        res.end respText

module.exports.EurekaInfoHandler = EurekaInfoHandler