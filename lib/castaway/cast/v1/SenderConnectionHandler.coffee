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

url = require "url"
path = require "path"
events = require "events"

{ ApplicationManager } = rekuire "castaway/cast/ApplicationManager"

#
# Creates Websocket Channel. This is requested by 2nd screen application
# {"/connection/([^/]+)", ChannelFactory},
#
class SenderConnectionHandler extends events.EventEmitter

    # Handle http request
    onHttpRequest: (req, res) ->
        console.log "ChannelFactory #{req}"

        segs = url.parse(req.url)
        appName = path.basename segs.path

        app = ApplicationManager.getInstance().getCurrentApplication()

        if app.getId() isnt appName
            console.error "Tried to create remote channel for #{appName}, but it wasn't running"
            res.writeHead 404
            res.end()
            return

        res.writeHead 200,
            "Content-Type": "application/json"
            "Access-Control-Allow-Method": "POST, OPTIONS"
            "Access-Control-Expose-Headers": "Content-Type"

        requestId = app.getNextRequestId()

        json = "{\"URL\":\"ws://#{req.headers.host}/session?#{requestId}\",\"pingInterval\":10}"
        console.log json

        req.on "data", (message) ->
            console.log "message: #{message}" # {"channel":0}

            send = =>
                # 数据发往 RECEIVER 的控制链路
                channel = app.getControlChannel()
                if channel
                    console.log "控制链路存在，发送消息: #{message}"
                    channel.newRequest message, requestId
                else
                    console.log "控制链路不存在，等待 1s"
                    setTimeout send, 1000

            setTimeout send, 100

        res.end json

module.exports.SenderConnectionHandler = SenderConnectionHandler