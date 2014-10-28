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

{ ApplicationManager } = rekuire "castaway/cast/ApplicationManager"

class SessionHandler

    constructor: ->
        @pingTimerId = null
        @pingInterval = 3000

    # Handle Websocket request
    onWebSocketRequest: (req, client) ->
        host = req.headers.host

        if host is "localhost:8008" or host is "127.0.0.1:8008"
            # RECEIVER 端连接
            # console.log "RECEIVER 端连接 ...."
            @onReceiverRequest(req, client)
        else
            # SENDER 端连接
            # console.log "SENDER 端连接 ...."
            @onSenderRequest(req, client)

    onReceiverRequest: (req, client) ->
        app = ApplicationManager.getInstance().getCurrentApplication()

        segs = url.parse req.url
        appName = path.basename segs.path

        console.log "RECEIVER 通道打开 : #{appName} #{segs.query}"

        @wsConn = client
        @chanNo = segs.query

        app.addReceiver @chanNo, this

        # RECEIVER 端连接已经建立，将 BUFFER 中缓存的 SENDER 端消息发送
        client.on "message", (message) =>
            messageObj = JSON.parse message

            if messageObj[0] == "cm"
                # console.log "从 RECEIVER 收到 CM 消息 : #{message}"
                switch messageObj[1].type
                    when "ping"
                        if @wsConn then @wsConn.send JSON.stringify ["cm", {type: "pong"}]
                    when "pong"
                        {}# ignore
            else
                message = JSON.stringify messageObj
                # console.log "从 RECEIVER 收到消息，转发给 SENDER" # : #{message}"
                app.receiverToSender @chanNo, message

        client.on "close", =>
            @clearPing()
            console.log "RECEIVER 通道关闭 : close"
            app.removeReceiver @chanNo

        @startPing()

    onSenderRequest: (req, client) ->
        app = ApplicationManager.getInstance().getCurrentApplication()

        segs = url.parse req.url
        appName = path.basename segs.path

        console.log "SENDER 通道打开 : #{appName} #{segs.query}"

        @wsConn = client
        @chanNo = segs.query

        app.on "close", => @wsConn?.close()

        app.addSender @chanNo, this

        client.on "message", (message) =>
            messageObj = JSON.parse message

            if messageObj[0] == "cm"
                # console.log "从 SENDER 收到 CM 消息 : #{message}"
                switch messageObj[1].type
                    when "ping"
                        if @wsConn then @wsConn.send JSON.stringify ["cm", {type: "pong"}]
                    when "pong"
                        {}# ignore
            else
                message = JSON.stringify messageObj
                # console.log "从 SENDER 收到消息，转发给 RECEIVER" # : #{message}"
                app.senderToReceiver @chanNo, message

        client.on "close", =>
            @clearPing()
            console.log "SENDER 通道关闭, 如果对等连接存在，关闭对等 RECEIVER 连接 #{@chanNo}"
            app.removeSender @chanNo

        @startPing()

    close: ->
        @clearPing()
        @wsConn.close()
        @wsConn = null

    send: (message) ->
        try
            @wsConn.send message
        # @deferPing()
        catch ex
            console.error "wsConn 消息发送失败，#{ex.toString()}"
            app = ApplicationManager.getInstance().getCurrentApplication()
            app.removeSender @chanNo

    startPing: ->
        ping = =>
            if @wsConn then @wsConn.send JSON.stringify ["cm", {type: "ping"}]
            @startPing()
        @pingTimerId = setTimeout ping, @pingInterval

    clearPing: ->
        if @pingTimerId
            clearTimeout @pingTimerId
            @pingTimerId = null

    deferPing: ->
        @clearPing()
        @startPing()

module.exports.SessionHandler = SessionHandler
