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

os = require "os"
events = require "events"

class Platform extends events.EventEmitter

    constructor: ->
        @nextRequestID = 0

    generateRequestID: ->
        return ++@nextRequestID

    getDeviceUUID: ->
        throw "Not Implemented"

    getDeviceName: ->
        throw "Not Implemented"

    launchApplication: (appURL) ->
        throw "Not Implemented"

    launchBrowser: (appUrl) ->
        @launchApplication(appUrl)

    stopApplication: ->
        throw "Not Implemented"

    stopBrowser: ->
        @stopApplication()

    @getInstance: ->
        console.log "platform:", os.platform()
        if not @instance
            if os.platform() is "android"
                { PlatformFirefoxOS } = rekuire "castaway/sys/PlatformFirefoxOS"
                @instance = new PlatformFirefoxOS
            else if os.platform() is "darwin"
                { PlatformDarwin } = rekuire "castaway/sys/PlatformDarwin"
                @instance = new PlatformDarwin
            else if os.platform() is "linux"
                { PlatformLinux } = rekuire "castaway/sys/PlatformLinux"
                @instance = new PlatformLinux
            else
                console.log "unsupport platform:", os.platform()
                throw "!! Unknow Platform !!"
        return @instance

module.exports.Platform = Platform