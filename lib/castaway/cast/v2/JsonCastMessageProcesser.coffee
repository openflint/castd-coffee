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

events = rekuire "events"

{ JsonMessageEmitter } = rekuire "castaway/util/JsonMessageEmitter"

class JsonCastMessageProcesser extends events.EventEmitter

    constructor: (socket, data) ->
        @socket = socket
        @remoteAddress = socket.remoteAddress
        @emitter = new JsonMessageEmitter socket, (message) =>
            @didReceiveMessage message
        process.nextTick =>
            @emitter.didReceiveNetworkData data if data
        socket.on 'close', =>
            @emit 'close'

    close: ->
        if @socket and typeof @socket?.destroy == "function"
            @socket.destroy()
        else if @socket?.socket and typeof @socket?.socket?.destroy == "function"
            @socket.socket.destroy()

    didReceiveMessage: (message) ->
        if message.payloadType == "BINARY"
            str = message.payloadBinary.toString()
            message.payloadBinary = new Buffer str, "base64"
        console.log message
        @emit "didReceiveMessage", message

    sendTextMessage: (args, callback) ->
        msgObj =
            protocolVersion: "CASTV2_1_0"
            sourceId: args.sourceId or "receiver-0"
            destinationId: args.destinationId
            namespace: args.namespace
            payloadType: "STRING"
            payloadUtf8: args.message

        msgTxt = JSON.stringify msgObj
        msgBuf = new Buffer msgTxt
        lenBuf = new Buffer msgBuf.length + ":"

        outBuf = Buffer.concat [lenBuf, msgBuf]
        @socket.write outBuf

        if callback then callback msgObj, outBuf

    sendBinaryMessage: (args, callback) ->
        msgObj =
            protocolVersion: "CASTV2_1_0"
            sourceId: args.sourceId or "receiver-0"
            destinationId: args.destinationId
            namespace: args.namespace
            payloadType: "BINARY"
            payloadBinary: args.data.toString "base64"

        msgTxt = JSON.stringify msgObj
        msgBuf = new Buffer msgTxt
        lenBuf = new Buffer msgBuf.length + ":"

        outBuf = Buffer.concat [lenBuf, msgBuf]
        @socket.write outBuf

        if callback then callback msgObj, outBuf

module.exports.JsonCastMessageProcesser = JsonCastMessageProcesser
