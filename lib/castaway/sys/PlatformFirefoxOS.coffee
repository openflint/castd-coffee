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

# node.js

net = rekuire("net")
fs = rekuire("fs")
path = rekuire("path")
uuid = rekuire("uuid")
colors = rekuire("colors")
child_process = rekuire("child_process")

# Local Modules

{ Log }                = rekuire "castaway/util/Log"
{ UUID }               = rekuire "castaway/util/UUID"
{ Platform }           = rekuire "castaway/sys/Platform"
{ MDNSServer }         = rekuire "castaway/cast/v2/MDNSServer"
{ JsonMessageEmitter } = rekuire "castaway/util/JsonMessageEmitter"
{ HashSet }            = rekuire "castaway/util/HashSet"

#
# Firefox OS 平台 PAL 层连接器
#
class PlatformFirefoxOS extends Platform

    constructor: ->
        super
        @status = "DISCONNECTED"
        @pendingMessage = new Array
        @name = null
        @volumeLevel = 1.0
        @volumeMuted = false

        @maxPendingMessageNum = 64

        #add for pal server
        @sockets = new HashSet()
        @setupPalConnectionServer()

        # 每 10s 向 PAL 层主动获取一次状态
        #timerIntervCb = =>
        #    @requestStatus()
        #    setTimeout timerIntervCb, 10000

        # 2s 之后向 PAL 层获取状态请求
        #setTimeout timerIntervCb, 2000

    # pal server
    setupPalConnectionServer: ->
        self = this
        @palServer = new net.createServer((socket) ->
            console.log "PAL create new CONNECTION!"

            self.sockets.add socket

            emitter = new JsonMessageEmitter socket, (jsonMessage) ->
              self.didReceiveSystemMessage jsonMessage

            socket.on 'end', ->
                console.log "PAL sock closed!"
                self.sockets.remove socket
                emitter = null
                return

            socket.on 'error', (exception) ->
                console.log "PAL socket error: #{exception}"
                return

            socket.on 'data', (data) ->
                console.log "pal socket data: #{data}"
                return
            return
        )

        @palServer.listen 8010, '127.0.0.1', () ->
            console.log "CastServer PAL TCP server started!"
            return

        return

    # 获得设备名称
    getDeviceName: ->
        return @name

    # 生成设备唯一码
    generateDeviceUUID: ->
        return UUID.randomUUID().toString()

    # 获得设备唯一码
    getDeviceUUID: ->
        if not @_uuid?
            @_uuid = @generateDeviceUUID()
        return @_uuid
        #filePath = "/data/fling/deviceUUID"

        #writeUUID = =>
            #data = @generateDeviceUUID()
            #try fs.mkdirSync(path.dirname(filePath))
            #console.log "DeviceUUID: #{data}"
            #try fs.writeFileSync filePath, data
            #return data

        #try
            #data = fs.readFileSync filePath
            #return data.toString()
        #catch ex
            #console.log ex
            #return writeUUID()

    # 启动应用程序
    launchApplication: (appURL) ->
        @sendMessage JSON.stringify
            type: "LAUNCH_RECEIVER"
            appUrl: appURL

    # 停止应用
    stopApplication: (appUUID) ->
        @sendMessage JSON.stringify
            type: "STOP_RECEIVER"

    # 发送消息
    sendMessage: (msg) ->
        console.log "PlatformFirefoxOS::sendMessage: #{msg}".blue;

        if @sockets.isEmpty()
            console.log "No client connected.... this.pendingMessage.length = #{@pendingMessage.length}"
            if @pendingMessage.length > @maxPendingMessageNum
              console.log "reach max pending message num[#{@maxPendingMessageNum}]. only remain the tails[32...]!"
              @pendingMessage = @pendingMessage.slice 32
            return @pendingMessage.push msg

        # send to all sockets?
        for sock in @sockets.values()
            msgBuf = new Buffer msg
            lenBuf = new Buffer msgBuf.length + ":"
            sock.write Buffer.concat [lenBuf, msgBuf], () ->
                console.log "发送成功: #{msg}"
                return

        if @pendingMessage.length > 0
            @sendMessage @pendingMessage.shift()

        console.log "Sent all messages! socket total number: #{@sockets.size()}"
        return

    # 处理 PAL 层发送的消息
    didReceiveSystemMessage: (msg) ->
        # 名称变化
        if msg.name and @name != msg.name
            @name = msg.name;
            console.log "Name update, dispatch deviceNameChanged to restart discovery service"
            @emit "deviceNameChanged", @name

        if msg.network_changed
            Log.i "PlatformFirefox: network_changed: #{msg.network_changed}".red
            @emit "network_changed", msg.network_changed

        changed = false
        # 音量变化
        if msg.volumeLevel and @volumeLevel != msg.volumeLevel
            @volumeLevel = msg.volumeLevel
            changed = true

        # 静音状态变化
        if msg.volumeMuted and @volumeMuted != msg.volumeMuted
            @volumeMuted = msg.volumeMuted
            changed = true
        else
            if @volumeLevel > 0
                @volumeMuted = false
            else
                @volumeMuted = true


        if @volumeChangedCallback
            Log.i "PlatformFirefox: volume changed".red
            @volumeChangedCallback()

    # 请求 PAL 层返回系统状态
    #requestStatus: ->
    #    try
    #        @sendMessage JSON.stringify {
    #            type: "GET_STATUS",
    #            requestId: @generateRequestID()
    #        }
    #    catch ex
    #        console.error ex.toString().redBG

    # 获得系统音量
    getVolume: ->
        @volumeLevel

    # 设置音量
    setVolume: (volumeLevel, requestId) ->
        @sendMessage JSON.stringify
            type: "SET_VOLUME"
            level: volumeLevel
            requestId: requestId

    # 获得系统静音状态
    getMuted: ->
        @volumeMuted

    # 设置是否静音
    setMuted: (muted, requestId) ->
        @sendMessage JSON.stringify
            type: "SET_MUTED"
            muted: muted
            requestId: requestId

    monitorVolumeChanged: (@volumeChangedCallback) ->

module.exports.PlatformFirefoxOS = PlatformFirefoxOS
