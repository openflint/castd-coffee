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

{ Log }             = rekuire "castaway/util/Log"
{ HashSet }         = rekuire "castaway/util/HashSet"
{ SenderSession }   = rekuire "castaway/cast/v2/SenderSession"
{ ReceiverSession } = rekuire "castaway/cast/v2/ReceiverSession"

{ JsonCastMessageProcesser }     = rekuire "castaway/cast/v2/JsonCastMessageProcesser"
{ ProtobufCastMessageProcesser } = rekuire "castaway/cast/v2/ProtobufCastMessageProcesser"

class CastServerV2

    constructor: (@castApp) ->
        @receiverSessions = new HashSet()
        @senderSessions = new HashSet()

    start: ->
        # SENDER
        addSenderSession = (senderSession) =>
            @senderSessions.add senderSession
            size = @senderSessions.size()
            Log.i "CastServer.addSenderSession #{senderSession.tag}, size = #{size}".red

        removeSenderSession = (senderSession) =>
            @senderSessions.remove senderSession
            size = @senderSessions.size()
            Log.i "CastServer.removeSenderSession #{senderSession.tag}, size = #{size}".red

        tlsServer = @castApp.getTLSServer()
        tlsServer.addHandler =>
            onTlsRequest: (cleartextStream) =>
                Log.i "New Sender Connection : #{cleartextStream.remoteAddress} #{cleartextStream.authorized}"
                senderSession = null
                cleartextStream.on "data", (data) =>
                    if senderSession == null
                        messageProcesser = new ProtobufCastMessageProcesser cleartextStream, data
                        senderSession = new SenderSession this, messageProcesser
                        cleartextStream.on "close", =>
                            removeSenderSession senderSession
                        addSenderSession senderSession

        # RECEIVER
        addReceiverSession = (receiverSession) =>
            @receiverSessions.add receiverSession
            size = @receiverSessions.size()
            Log.i "CastServer.addReceiverSession size = #{size}"

        removeReceiverSession = (receiverSession) =>
            @receiverSessions.remove receiverSession
            size = @receiverSessions.size()
            Log.i "CastServer.removeReceiverSession size = #{size}"

        httpServer = @castApp.getHTTPServer()
        httpServer.addRoute /\/v2\/ipc/, =>
            onWebSocketRequest: (req, wsConn) =>
                Log.i ("New Receiver Connection").greenBG
                receiverSession = new ReceiverSession this, wsConn
                addReceiverSession receiverSession
                wsConn.on "close", =>
                    removeReceiverSession receiverSession

        # SIMPLE SENDER
        tcpServer = @castApp.getTCPServer()
        tcpServer.addHandler =>
            onTcpRequest: (socket) =>
                Log.i "New Simple Sender Connection : #{socket.remoteAddress}"
                senderSession = null
                socket.on "data", (data) =>
                    if senderSession == null
                        messageProcesser = new JsonCastMessageProcesser socket, data
                        senderSession = new SenderSession this, messageProcesser
                        socket.on "close", =>
                            removeSenderSession senderSession
                        addSenderSession senderSession

    getSenderSession: ->
        return @senderSessions.values()

    getReceiverSession: ->
        return @receiverSessions.values()

module.exports.CastServerV2 = CastServerV2
