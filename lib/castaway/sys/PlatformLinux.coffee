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

fs = rekuire("fs")
colors = rekuire("colors")
uuid = rekuire("uuid")
child_process = rekuire("child_process")

{ Platform } = rekuire "castaway/sys/Platform"
{ UUID } = rekuire "castaway/util/UUID"

class PlatformLinux extends Platform

    constructor: ->
        deviceUUID = @getDeviceUUID()
        @name = "MatchStick_Linux_" + String(deviceUUID).replace(/-/g, '').substr(-4)
        console.log "PlatformLinux: #{@name}"
        timerCb = ->
            @emit "deviceNameChanged", @name
        setTimeout(timerCb.bind(this), 2000)

    getDeviceName: ->
        @name

    generateDeviceUUID: ->
        UUID.randomUUID().toString()

    getDeviceUUID: ->
        filePath = "deviceUUID"
        try data = fs.readFileSync filePath
        if not data
            data = @generateDeviceUUID()
            try fs.writeFileSync filePath, data
        return data

    launchApplication: (appURL) ->
        console.log(('PlatformLinux.launchApplication: ' + appURL).red)
        chrome = "/opt/google/chrome/google-chrome"
        console.log "Google Chrome Browser location: [#{chrome}]?!"

#        timerCb = ->
#            MDNSServer.getInstance().startServer(@name)
#        setTimeout timerCb, 1000

        @chromeProcess = child_process.spawn chrome, [
            "--no-default-browser-check",
            "--enable-logging",
            "--no-first-run",
            "--disable-application-cache",
            "--disable-cache",
            "--enable-kiosk-mode",
            "--kiosk",
            "--start-maximized",
            "--window-size=1280,720",
            "--single-process",
            "--app=" + appURL,
            "--user-data-dir=/tmp/" + uuid.v1()
        ]

        @chromeProcess.stdout.on 'data', (chunk) ->
            console.log(chunk)
        @chromeProcess.stderr.on 'data', (chunk) ->
            console.log(chunk)
        @chromeProcess.on 'exit', () ->
            @running = false

    # 停止应用
    stopApplication: ->
        console.log(("PlatformLinux.stopApplication").red)
        if @chromeProcess
            @chromeProcess.kill('SIGTERM')

    getVolume: ->
        1.0

    setVolume: (volumeLevel, requestId) ->

    getMuted: ->
        false

    setMuted: (muted, requestId) ->

module.exports.PlatformLinux = PlatformLinux
