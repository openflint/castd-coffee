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

{ Log }         = rekuire "castaway/util/Log"
{ CastChannel } = rekuire "castaway/cast/v2/CastChannel"

class HeartbeatChannel extends CastChannel

    constructor: ->
        super("urn:x-cast:com.google.cast.tp.heartbeat")

    resetHeartbeat: ->

    didReceiveTextMessage: (sourceId, destinationId, message) ->
        # Log.i "HeartbeatChannel:".blue
        # Log.i util.inspect(message).blue

        messageObj = JSON.parse message

        if messageObj.type == "PING"
            @sendTextMessage
                sourceId: destinationId, # or "Tr@n$p0rt-0" ?
                destinationId: sourceId, # or "Tr@n$p0rt-0" ?
                message: "{\"type\":\"PONG\"}"
        else if messageObj.type == "PONG"
            @sendTextMessage
                sourceId: destinationId,
                destinationId: sourceId,
                message: "{\"type\":\"PING\"}"
        else
            Log.w "HeartbeatChannel received unknow message : #{message}"

module.exports.HeartbeatChannel = HeartbeatChannel