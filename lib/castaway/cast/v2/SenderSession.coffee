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

{ Log }                      = rekuire "castaway/util/Log"
{ DeviceAuthChannel }        = rekuire "castaway/cast/v2/DeviceAuthChannel"
{ ReceiverControlChannel }   = rekuire "castaway/cast/v2/ReceiverControlChannel"
{ ConnectionControlChannel } = rekuire "castaway/cast/v2/ConnectionControlChannel"
{ HeartbeatChannel }         = rekuire "castaway/cast/v2/HeartbeatChannel"
{ ApplicationManager }       = rekuire "castaway/cast/ApplicationManager"

class SenderSession

    @sessionId = 1

    constructor: (server, messageProcesser) ->
        @channels = {}
        @server = server

        @sessionId = SenderSession.sessionId++
        @sourceId = ""

        @tag = "#{messageProcesser.remoteAddress}:#{@sessionId}"

        @timeoutId = null
        @channelConnected = false

        @receiverControlChannel = new ReceiverControlChannel this
        @addChannel @receiverControlChannel

        @deviceAuthChannel = new DeviceAuthChannel
        @addChannel @deviceAuthChannel

        # 设备认证成功后启动超时定时器，避免空连接占用系统资源
        @deviceAuthChannel.on "deviceDidAuth", =>
            @timeoutId = setTimeout (=> @close()), 5000

        @connectionControlChannel = new ConnectionControlChannel this
        @addChannel @connectionControlChannel

        # Android SDK 会创建一个独立链接，
        @connectionControlChannel.on "senderConnected", (sourceId) =>
            @sourceId = sourceId
            clearTimeout @timeoutId

        @connectionControlChannel.on "senderDisconnected", (sourceId) =>
            @close()

        @connectionControlChannel.on "channelConnected", =>
            @channelConnected = true
            @server.getReceiverSession().map (session) =>
                session.onSenderConnected @uniqueId()

        @connectionControlChannel.on "channelDisconnected", =>
            @server.getReceiverSession().map (session) =>
                session.onSenderDisconnected @uniqueId()
            @channelConnected = false

        @heartbeatChannel = new HeartbeatChannel
        @addChannel @heartbeatChannel

        @messageProcesser = messageProcesser;
        @messageProcesser.on "didReceiveMessage", (message) =>
            @didReceiveMessage message
        @messageProcesser.on "end", =>
            if @channelConnected
                @server.getReceiverSession().map (session) =>
                    session.onSenderDisconnected @uniqueId()
                @channelConnected = false

    #
    # 关闭链接
    # CastServerV2 响应链接关闭事件，将 Session 移除
    #
    close: ->
        @messageProcesser.close()

    #
    # 链接唯一码
    #
    uniqueId: ->
        return "#{@sessionId}:#{@sourceId}"

    #
    # 添加一个绑定到指定名字空间的消息通道
    #
    addChannel: (channel) ->
        if not channel then throw "Channel must be non-nil"

        namespace = channel.getProtocolNamespace()

        if not @channels[namespace]
            channel.handler = this
            @channels[namespace] = channel

    #
    # 从 CastSocket 接受消息，转发到不同的 CastChannel
    #
    didReceiveMessage: (message) ->

        # Log.i "SenderSession::didReceiveMessage ", message

        # 重置心跳信号
        @heartbeatChannel.resetHeartbeat()

        # 查找 namespace 对应的 channel
        channel = @channels[message.namespace]

        if channel
            switch message.payloadType
                when "STRING"
                    channel.didReceiveTextMessage message.sourceId,
                        message.destinationId, message.payloadUtf8
                when "BINARY"
                    channel.didReceiveBinaryMessage message.sourceId,
                        message.destinationId, message.payloadBinary
        else
            # 直接发往 RECEIVER APPLICATION
            # Log.i "No channel attached for namespace #{message.namespace}, ignoring message."
            @server.getReceiverSession().map (session) =>
                session.onSenderMessage @uniqueId(), message

    #
    # Sends a text message.
    #
    # @param message The message string.
    # @param namespace The namespace of channel
    # @return <code>yes</code> on success or <code>no</code> if the message could not be sent (because
    # the handler is not connected, or because the send buffer is too full at the moment).
    #
    sendTextMessage: (args) ->
        @messageProcesser.sendTextMessage args, (msgObj, buffer) =>

    sendBinaryMessage: (args) ->
        @messageProcesser.sendBinaryMessage args, (msgObj, buffer) =>

module.exports.SenderSession = SenderSession