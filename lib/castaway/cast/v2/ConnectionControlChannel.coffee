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

util = rekuire "util"

{ Log }         = rekuire "castaway/util/Log"
{ CastChannel } = rekuire "castaway/cast/v2/CastChannel"

class ConnectionControlChannel extends CastChannel

    constructor: (@session) ->
        super("urn:x-cast:com.google.cast.tp.connection")

    didReceiveTextMessage: (sourceId, destinationId, message) ->
        Log.i "ConnectionControlChannel: #{sourceId} -> #{destinationId}".blue
        Log.i util.inspect(message).blue

        messageObj = JSON.parse message

        if destinationId == "receiver-0"

            # "receiver-0" 是特殊目标，用了进行 Sender 到 Daemon 的链接状态管理
            if messageObj.type == "CONNECT"
                @emit "senderConnected", sourceId
            else if messageObj.type == "CLOSE"
                @emit "senderDisconnected", sourceId

        else if destinationId.indexOf "web-" == 0

            # "web-x" 是标准 Sender 到 Receiver 的通道管理
            if messageObj.type == "CONNECT"
                @emit "channelConnected"

            else if messageObj.type == "CLOSE"
                @emit "channelDisconnected"

module.exports.ConnectionControlChannel = ConnectionControlChannel