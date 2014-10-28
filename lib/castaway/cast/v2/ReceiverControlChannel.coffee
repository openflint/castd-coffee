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
{ CastChannel }        = rekuire "castaway/cast/v2/CastChannel"
{ ApplicationManager } = rekuire "castaway/cast/ApplicationManager"
{ Platform }           = rekuire "castaway/sys/Platform"

#
# Receiver 控制通道
#
class ReceiverControlChannel extends CastChannel

    constructor: (@session) ->
        @appMgr = ApplicationManager.getInstance()
        super("urn:x-cast:com.google.cast.receiver")

    # Override
    didReceiveTextMessage: (sourceId, destinationId, message) ->
        Log.i "ReceiverControlChannel:".blue
        Log.i util.inspect(message).blue

        messageObj = JSON.parse message

        if messageObj.type == "GET_STATUS"
            @responseReceiverStatus sourceId, destinationId, messageObj
        else if messageObj.type == "LAUNCH"
            @launchReceiverApplication sourceId, destinationId, messageObj
        else if messageObj.type == "GET_APP_AVAILABILITY"
            @responseAppAvailability sourceId, destinationId, messageObj
        else if messageObj.type == "STOP"
            @stopReceiverApplication sourceId, destinationId, messageObj
        else if messageObj.type == "SET_VOLUME"
            platform = Platform.getInstance()
            if messageObj.volume.level
                platform.setVolume messageObj.volume.level, messageObj.requestId
                Log.i "ReceiverControlChannel: set volume #{messageObj.volume.level}".blue
            else if messageObj.volume.muted?
                platform.setMuted messageObj.volume.muted, messageObj.requestId
                Log.i "ReceiverControlChannel: set muted #{messageObj.volume.muted}".blue
            platform.monitorVolumeChanged (=> @broadcastReceiverStatus messageObj.requestId)
        else if messageObj.type == "SET_MUTED"
            platform = Platform.getInstance()
            platform.setMuted messageObj.volume.muted, messageObj.requestId
            platform.monitorVolumeChanged (=> @broadcastReceiverStatus messageObj.requestId)
        else
            Log.i "ReceiverControlChannel received unknow message : #{messageObj}"

    #
    # 返回 Receiver 状态
    #
    responseReceiverStatus: (sourceId, destinationId, messageObj) ->
        if destinationId == "receiver-0"
            @broadcastReceiverStatus()
        else
            Log.w "Message \"GET_STATUS\" destinationId : #{destinationId}"

    #
    # 启动 Receiver 应用程序
    #
    # { "responseType" : "LAUNCH_ERROR", "reason" : "" }
    #
    # "BAD_PARAMETER"
    # "CANCELLED"
    # "NOT_ALLOWED"
    # "NOT_FOUND"
    # "CAST_INIT_TIMEOUT"
    #
    launchReceiverApplication: (sourceId, destinationId, messageObj) ->
        # 启动新应用
        appId = messageObj.appId
        launchRequestId = messageObj.requestId

        app = @appMgr.launchApplicationV2
            protocolVersion: 2.0
            appId: appId, (app) => # 应用已经启动完毕，发送回复
                @broadcastReceiverStatus launchRequestId
                app.on "statusUpdate", =>
                    @broadcastReceiverStatus()

        # 如果应用程序由于网络异常等原因在 30s 内没有正常启动，就自动关闭
        timeoutId = setTimeout (=> app.stop()), 30 * 1000
        app.on "didLaunch", => clearTimeout timeoutId

        app.on "close", =>
            Log.i "应用程序关闭！需要关闭 SESSION ！"
            process.nextTick => @broadcastReceiverStatus()
            # 1s 后关闭链路？
            setTimeout (=> @session?.close()), 1000

        # 应用正在启动中，先发送状态回复
        process.nextTick =>
            @broadcastReceiverStatus()

    #
    # 停止 Receiver 应用程序
    #
    stopReceiverApplication: (sourceId, destinationId, messageObj) ->
        # { protocol_version: 'CASTV2_1_0',
        #   source_id: 'A485134F-CD97-4195-8EB9-6D639DA15B08',
        #   destination_id: 'receiver-0',
        #   namespace: 'urn:x-cast:com.google.cast.receiver',
        #   payload_type: 'STRING',
        #   payload_utf8: '{"type":"STOP","requestId":3}' }

        # 关闭应用，保持 Sender 链接，Receiver 被动关闭
        app = @appMgr.getCurrentApplication()

        return if not app?.isProtocolVersionV2()

        app.stop()

        # 返回命令执行结果
        process.nextTick =>
            @broadcastReceiverStatus messageObj.requestId

    #
    # 返回 App Availability 可用性状态
    #
    responseAppAvailability: (sourceId, destinationId, messageObj) ->
        #
        # { protocol_version: 'CASTV2_1_0',
        #   source_id: 'gms_cast_mrp-21',
        #   destination_id: 'receiver-0',
        #   namespace: 'urn:x-cast:com.google.cast.receiver',
        #   payload_type: 'STRING',
        #   payload_utf8: '{"type":"GET_APP_AVAILABILITY","requestId":1,"appId":["CC1AD845"]}' }
        #
        # {"requestId":1,"responseType":"GET_APP_AVAILABILITY","availability":{"CC1AD845":"APP_AVAILABLE"}}
        #

        # 消息中的 appId 为数组对象，当前仅仅处理第一个应用程序 Id
        appId = messageObj.appId[0]

        respMsg =
            requestId: 1
            responseType: "GET_APP_AVAILABILITY"
            availability: {}

        respMsg.availability[appId] = "APP_AVAILABLE"

        Log.i "GET_APP_AVAILABILITY: "
        Log.i respMsg

        @sendTextMessage
            destinationId: sourceId
            message: JSON.stringify respMsg

    #
    # 广播 Receiver 状态
    #
    broadcastReceiverStatus: (requestId) ->

        # 根据系统接口获得声音配置
        platform = Platform.getInstance()
        statusMessage =
            volume:
                level: platform.getVolume()
                muted: platform.getMuted()

        app = @appMgr.getCurrentApplication()

        if app?.isProtocolVersionV2()

            # 如果当前存在正在运行的应用，返回应用状态
            if app.isRunning()
                namespaces = new Array
                for k in app.namespaces
                    namespaces.unshift
                        name: app.namespaces[k]
                statusMessage.applications = new Array
                statusMessage.applications[0] =
                    appId: app.appId
                    displayName: app.displayName
                    namespaces: namespaces
                    sessionId: app.sessionId
                    statusText: app.statusText
                    transportId: app.transportId

        Log.i "StatusMessage:"
        Log.i statusMessage

        # note:
        #     The invocation below seems uselessly, and daemon works well if commentate it.
        #     Anyway, remain it for minimal modification.
        @sendTextMessage
            destinationId: "*"
            message: JSON.stringify
                type: "RECEIVER_STATUS"
                requestId: requestId or 0
                status: statusMessage

        # traverse all SenderSession in CastServerV2 and send receiver's status to them
        @session.server.getSenderSession().map (session, index, array) =>
            session.sendTextMessage
                namespace: "urn:x-cast:com.google.cast.receiver"
                destinationId: "*",
                sourceId: "receiver-0", # "receiver-0" indicates that daemon send the message to sender actively
                message: JSON.stringify
                    type: "RECEIVER_STATUS"
                    requestId: 0 # 0 indicates that this message is a broadcast for sender
                    status: statusMessage

module.exports.ReceiverControlChannel = ReceiverControlChannel
