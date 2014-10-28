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

util = require "util"

{ Log }                = rekuire "castaway/util/Log"
{ ApplicationManager } = rekuire "castaway/cast/ApplicationManager"

class ReceiverSession

    @sessionId = 1

    constructor: (@server, @wsconn) ->
        @sessionId = ReceiverSession.sessionId++
        @appMgr = ApplicationManager.getInstance()
        @wsconn.on "message", (message) =>
            @onWsMessage message
        @wsconn.on "close", =>
            Log.i "wsconn is closed".red
            clearTimeout @diedId if @diedId?
            clearTimeout @hbId if @hbId?
            app = @appMgr.getCurrentApplication()
            if app?.isProtocolVersionV2()
                app.stop()

    close: ->
        @wsconn.terminate()

    onWsMessage: (message) ->
        messageObj = JSON.parse message

        Log.i "ReceiverSession received:".green
        Log.i util.inspect(messageObj).green

        # *:* 广播
        # 4:com.google.android.gms.cast.samples.tictactoe-2 指定包
        senderId = messageObj.senderId

        if messageObj.namespace == "urn:x-cast:com.google.cast.system"
            # 系统名字空间，直接处理
            @onSystemMessage messageObj
        else if messageObj.namespace == "urn:x-cast:com.google.cast.tp.heartbeat"
            # 心跳
            @onHeartbeat messageObj
        else
            app = @appMgr.getCurrentApplication()

            if app?.isProtocolVersionV2()

                # 应用名字空间，找到对应的 SenderSession 发送
                @server.getSenderSession().map (session, index, array) =>
                    if senderId != "*:*"
                        Log.i "SessionUniqueId: #{session.uniqueId()}"
                        if senderId != session.uniqueId() then return

                    session.sendTextMessage
                        namespace: messageObj.namespace
                        sourceId: app.transportId,  # web - 5, web - 7, web - 9 奇数递增
                        destinationId: "*",
                        message: messageObj.data

    onSystemMessage: (messageObj) ->
        dataObj = JSON.parse messageObj.data
        if dataObj.type == "ready"
            @onReceiverReady dataObj
        else if dataObj.type == "startheartbeat"
            @onReceiverStartHeartbeat dataObj
        else if dataObj.type == "setappstate"
            @onReceiverSetAppState dataObj

    #
    # 表示 Receiver 已经正确启动
    #
    # Receiver 已经正确启动，通知 SenderSession
    # { namespace: 'urn:x-cast:com.google.cast.system',
    #   senderId: 'SystemSender',
    #   data: '{"type":"ready","activeNamespaces":["urn:x-cast:com.google.cast.media"],"version":"2.0.0","messagesVersion":"1.0"}' }
    #
    onReceiverReady: (dataObj) ->
        Log.i "ReceiverSession: \"READY\""
        app = @appMgr.getCurrentApplication()
        if app?.isProtocolVersionV2()
            app.notifyApplicationDidReady dataObj

            # 发送 READY 事件给 RECEIVER APP，完成整个 READY 事件的双向握手过程
            @sendMessage
                namespace: "urn:x-cast:com.google.cast.system"
                senderId: "SystemSender"
                data: JSON.stringify
                    sessionId: @sessionId
                    type: "ready"
                    userAgent: "iOS CastSDK,2.0.0,iPhone Simulator,iPhone OS,7.0.3"

    #
    # 启动 Receiver 监控心跳
    #
    onReceiverStartHeartbeat: (dataObj) ->
        if dataObj.fling?
            @maxInactivity = dataObj.maxInactivity
            @hbId = setTimeout (=> @sendHeartbeat "PING"), 3000
            Log.i "ReceiverSession: \"STARTHEARTBEAT\" timeout is #{@maxInactivity}".green
        else
            Log.i "ReceiverSession: not fling, ignore \"STARTHEARTBEAT\"".green

    onHeartbeat: (messageObj) ->
        dataObj = JSON.parse messageObj.data
        if dataObj.type = "PONG"
            clearTimeout @diedId if @diedId?
            @hbId = setTimeout (=> @sendHeartbeat "PING"), 3000
        else if dataObj.type = "PING"
            clearTimeout @diedId if @diedId?
            @hbId = setTimeout (=> @sendHeartbeat "PONG"), 3000
        else
            Log.i "HeartbeatSender receive unknow message: #{JSON.stringify messageObj}"

    sendHeartbeat: (hb) ->
        res = @sendMessage
                  namespace: "urn:x-cast:com.google.cast.tp.heartbeat"
                  senderId: "HeartbeatSender"
                  data: JSON.stringify
                      type: hb
        if res
            @diedId = setTimeout (=> @onReceiverDied "heartbeat timeout"), @maxInactivity*1000
        else
            @onReceiverDied "wsconn maybe closed"

    onReceiverDied: (reason) ->
        Log.i "ReceiverApplication is DIED, reason: #{reason}".red
        clearTimeout @diedId if @diedId?
        clearTimeout @hbId if @hbId?
        @close()
        app = @appMgr.getCurrentApplication()
        if app?.isProtocolVersionV2()
            app.stop()

    #
    # 接收 Receiver 状态变化事件
    #
    onReceiverSetAppState: (dataObj) ->
        Log.i "ReceiverSession: \"SETAPPSTATE\""
        app = @appMgr.getCurrentApplication()
        if not app then return
        app.updateStatusText dataObj.statusText

    sendMessage: (messageObj) ->
        Log.i "Send To Receiver:".yellow
        Log.i util.inspect(messageObj).yellow
        try
            @wsconn.send JSON.stringify messageObj
            return true
        catch ex
            console.error "wsconn send failed, ws maybe closed，#{ex.toString()}"
            return false

    onSenderMessage: (uniqueId, message) ->
        @sendMessage
            namespace: message.namespace
            senderId: uniqueId
            data: message.payloadUtf8

    onSenderConnected: (uniqueId) ->
        @sendMessage
            namespace: "urn:x-cast:com.google.cast.system"
            senderId: "SystemSender"
            data: JSON.stringify
                senderId: uniqueId
                type: "senderconnected"
                userAgent: "iOS CastSDK,2.0.0,iPhone Simulator,iPhone OS,7.0.3"

    onSenderDisconnected: (uniqueId) ->
        @sendMessage
            namespace: "urn:x-cast:com.google.cast.system"
            senderId: "SystemSender"
            data: JSON.stringify
                senderId: uniqueId
                type: "senderdisconnected"
                userAgent: "iOS CastSDK,2.0.0,iPhone Simulator,iPhone OS,7.0.3"

module.exports.ReceiverSession = ReceiverSession