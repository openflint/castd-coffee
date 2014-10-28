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

{ Platform } = rekuire "castaway/sys/Platform"

class SystemControlHandler

    # Handle Websocket request
    onWebSocketRequest: (req, client) ->
        console.log "System Control 控制链路已打开 ..."
        client.on "message", (message) =>
            command = JSON.parse message
            platform = Platform.getInstance()
            switch command.type
                when "GET_VOLUME"
                    client.send JSON.stringify
                        success: true
                        request_type: command.type
                        level: platform.getVolume()
                when "GET_MUTED"
                    client.send JSON.stringify
                        success: true
                        request_type: command.type
                        muted: platform.getMuted()
                when "SET_VOLUME"
                    platform.setVolume command.level
                when "SET_MUTED"
                    platform.setMuted command.muted
                else
                    console.error "Unhandled system command received"
                    console.error "#{command}"

module.exports.SystemControlHandler = SystemControlHandler