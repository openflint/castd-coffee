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

{ Platform }    = rekuire "castaway/sys/Platform"
{ Application } = rekuire "castaway/cast/Application"

class ApplicationV1 extends Application

    @nextRequestId = 1

    constructor: (opts) ->
        @id = opts.id
        @url = opts.url

        @status =
            name: opts.id
            host: opts.host
            state: "stopped"
            link: ""
            connectionSvcURL: null
            protocols: opts.supportedProtocols or [ "ramp" ]

        @controlChannel = null

        @sender = {}
        @senderCount = 0
        @senderQueue = {}

        @receiver = {}
        @receiverCount = 0
        @receiverQueue = {}

    getNextRequestId: ->
        return ApplicationV1.nextRequestId++

    getId: ->
        @id

    getState: ->
        @status.state

    getConnectionServiceURL: ->
        if @controlChannel and not @status.connectionSvcURL
            @status.connectionSvcURL = "http://#{@status.host}/connection/#{@id}"
        return @status.connectionSvcURL

    isProtocolVersionV1: ->
        true

    getSupportedProtocols: ->
        @status.protocols

    setProtocols: (protocols) ->
        @status.protocols = protocols

    # 注册 RECEIVER 的控制链路
    setControlChannel: (channel) ->
        @controlChannel = channel

    getControlChannel: ->
        return @controlChannel

    launch: ->
        if @status.state == "stopped"
            @status.state = "running"
            @status.connectionSvcURL = null # 等待 RECEIVER 注册
            console.log "AppV1:launch: #{@status.name}, #{@status.state}"
            Platform.getInstance().launchBrowser(@url)

    stop: ->
        if @status.state == "running"
            @status.state = "stopped"
            @emit "close"
            Platform.getInstance().stopBrowser()

    addReceiver: (chan, receiver) ->
        @receiver[chan] = receiver
        @receiverCount++

        if not @receiverQueue[chan]
            @receiverQueue[chan] = []

        console.log "self.receiverQueue[#{chan}] = " + @receiverQueue[chan].length

        for m in @receiverQueue[chan]
            console.log "SENDER -> RECEIVER : #{m}"
            @receiver[chan].send m

    removeReceiver: (chan) ->
        console.log "removeReceiver chan = #{chan}"

        if @sender[chan]
            @sender[chan].close()
            @sender[chan] = null
            @senderCount--

        if @receiver[chan]
            @receiver[chan].close()
            @receiver[chan] = null
            @receiverCount--

        console.log "self.senderCount = #{@senderCount}"
        console.log "self.receiverCount = #{@receiverCount}"

    addSender: (chan, sender) ->
        @sender[chan] = sender
        @senderCount++

        if not @senderQueue[chan] then @senderQueue[chan] = []

        console.log "self.senderQueue[#{chan}] = #{@senderQueue[chan]}"

        for m in @senderQueue[chan]
            console.log "RECEIVER -> SENDER : #{m}"
            @sender[chan].send m

        @senderQueue[chan] = []

    # 关闭对等连接
    removeSender: (chan) ->
        console.log "removeSender chan = #{chan}"

        if @sender[chan]
            @sender[chan].close()
            @sender[chan] = null
            @senderCount--

        if @receiver[chan]
            @receiver[chan].close()
            @receiver[chan] = null
            @receiverCount--

        console.log "self.senderCount = #{@senderCount}"
        console.log "self.receiverCount = #{@receiverCount}"

    # SENDER to RECEIVER
    senderToReceiver: (chan, message) ->
        # console.log "[#{chan}] S2R : #{message}"
        if @receiver[chan]
            @receiver[chan].send message
        else
            if not @receiverQueue[chan] then @receiverQueue[chan] = []
            @receiverQueue[chan].push message
            console.log "[#{chan}] S2R PUSH : #{message}"

    # RECEIVER to SENDER
    receiverToSender: (chan, message) ->
        # console.log "[#{chan}] R2S : #{message}"
        if @sender[chan]
            @sender[chan].send message
        else
            if not @senderQueue[chan] then @senderQueue[chan] = []
            @senderQueue[chan].push message
            console.log "[#{chan}] R2S PUSH : #{message}"

module.exports.ApplicationV1 = ApplicationV1