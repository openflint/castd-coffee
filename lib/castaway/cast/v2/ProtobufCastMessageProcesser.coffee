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

{ Log }                        = rekuire "castaway/util/Log"
{ CastMessageSerdes }          = rekuire "castaway/cast/v2/CastMessageSerdes"
{ ProtobufCastMessageEmitter } = rekuire "castaway/cast/v2/ProtobufCastMessageEmitter"

class ProtobufCastMessageProcesser extends events.EventEmitter

    constructor: (socket, data) ->
        @socket = socket
        @remoteAddress = socket.remoteAddress
        @emitter = new ProtobufCastMessageEmitter socket, (message) =>
            @didReceiveMessage message
        process.nextTick =>
            @emitter.didReceiveNetworkData data if data
        socket.on 'close', =>
            @emit 'close'

    #
    # Compatibility on 'Socket' and 'CleartextStream'
    #
    close: ->
        if @socket and typeof @socket.destroy == "function"
            @socket.destroy()
        else if @socket?.socket and typeof @socket?.socket.destroy == "function"
            @socket.socket.destroy()

    didReceiveMessage: (message) ->
        @emit "didReceiveMessage", message

    sendTextMessage: (args, callback) ->
        msgObj =
            protocolVersion: "CASTV2_1_0"
            sourceId: args.sourceId or "receiver-0"
            destinationId: args.destinationId
            namespace: args.namespace
            payloadType: "STRING"
            payloadUtf8: args.message

        castMessageSerdes = new CastMessageSerdes "CastMessage"
        msgBuf = castMessageSerdes.serialize msgObj
        lenBuf = new Buffer 4
        lenBuf.writeInt32BE msgBuf.length, 0
        outBuf = Buffer.concat [lenBuf, msgBuf]
        @socket.write outBuf

        if callback then callback.call msgObj, outBuf

    sendBinaryMessage: (args, callback) ->
        msgObj =
            protocolVersion: "CASTV2_1_0"
            sourceId: args.sourceId or "receiver-0"
            destinationId: args.destinationId
            namespace: args.namespace
            payloadType: "BINARY"
            payloadBinary: args.data

        castMessageSerdes = new CastMessageSerdes "CastMessage"
        msgBuf = castMessageSerdes.serialize msgObj
        lenBuf = new Buffer 4
        lenBuf.writeInt32BE msgBuf.length, 0
        outBuf = Buffer.concat [lenBuf, msgBuf]
        @socket.write outBuf

        if callback then callback.call msgObj, outBuf

module.exports.ProtobufCastMessageProcesser = ProtobufCastMessageProcesser
