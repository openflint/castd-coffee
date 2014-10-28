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

{ ApplicationManager } = rekuire "castaway/cast/ApplicationManager"

#
# /connection
#
# 从 RECEIVER 发起的控制链路
#
class ReceiverConnectionHandler

    # Handle Websocket request
    onWebSocketRequest: (req, client) ->
        console.log "RECEIVER 控制链路已打开 ..."
        @wsConn = client

        @wsConn.on "message", (message) =>
            console.log "ReceiverConnectionHandler : message : #{message}"
            data = JSON.parse message

            # 接受 RECEIVER 控制链路注册
            if data?.type is "REGISTER"
                #
                #  { "type"         : "REGISTER",
                #    "version"      : 2,
                #    "name"         : "InfNetCast",
                #    "protocols"    : ["ramp"],
                #    "pingInterval" : 5,
                #    "eventChannel" : 0,
                #    "appContext"   : null }
                #
                name = data?.name

                currApp = ApplicationManager.getInstance().getCurrentApplication()

                if currApp.getId() is name
                    @app = currApp
                    @app.setProtocols(data?.protocols)
                    @app.setControlChannel this
                else
                    console.error "Some app tried to register when different app was running !"
                    @wsConn.close()

            else if data?.type is "CHANNELRESPONSE"
                #
                #  { "type"      : "CHANNELRESPONSE",
                #    "requestId" : 7,
                #    "action"    : 0 }
                #
                @newChannel(data?.requestId)
            else
                console.error "Unknown message received from receiver application"

        @wsConn.on "close", =>
            console.log "RECEIVER 控制链路已关闭 ..."
            @app?.stop()

    reply: (msg) ->
        msg = JSON.stringify(msg)
        # 如果 ws 连接存在，直接发送
        console.log "#{msg}".green
        if @wsConn
            @wsConn.send msg
        else
            console.log "ReceiverConnectionHandler:reply 连接不存在 !!"

    newChannel: (chanNo) ->
        console.log "NEWCHANNEL for app #{@app.getId()} #{chanNo}"

        # { "URL"       : "ws://localhost:8008/session?7",
        #   "channel"   : 0,
        #   "requestId" : 7,
        #   "type"      : "NEWCHANNEL" }

        @reply
            "type": "NEWCHANNEL"
            "channel": @channel
            "requestId": chanNo
            "URL": "ws://localhost:8008/session?#{chanNo}"

    newRequest: (data, requestId) ->
        console.log "CHANNELREQUEST for app #{@app.getId()}"
        console.log data
        if data
            data = JSON.parse(data)
            console.log data
            @channel = data?.channel
            console.log @channel
            if @channel == null
                @channel = @app.getAppsCount()
        else
            @channel = @app.getAppsCount()

        # {"channel":0,"requestId":7,"type":"CHANNELREQUEST"}
        @reply
            "type": "CHANNELREQUEST"
            "channel": @channel
            "requestId": requestId

    close: ->
        @wsConn.close()

module.exports.ReceiverConnectionHandler = ReceiverConnectionHandler
