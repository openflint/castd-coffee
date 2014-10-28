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

fs = require "fs"
util = require "util"

{ Log }               = rekuire "castaway/util/Log"
{ CastChannel }       = rekuire "castaway/cast/v2/CastChannel"
{ CastMessageSerdes } = rekuire "castaway/cast/v2/CastMessageSerdes"

class DeviceAuthChannel extends CastChannel

    constructor: ->
        super("urn:x-cast:com.google.cast.tp.deviceauth")

    #
    # Response auth request, '0x0A00'
    # Return an empty message
    #
    didReceiveBinaryMessage: (sourceId, destinationId, data) ->

        Log.i "DeviceAuthChannel received auth request : #{data}"

        deviceAuthMessageSerdes = new CastMessageSerdes "DeviceAuthMessage"

        # no use
        # deviceAuthRequestMessageObj = deviceAuthMessageSerdes.deserialize data

        deviceAuthMessageObj =
            response:
                signature: new Buffer 64
                client_auth_certificate: new Buffer 128

        deviceAuthMessage = deviceAuthMessageSerdes.serialize deviceAuthMessageObj

        @sendBinaryMessage
            data: deviceAuthMessage
            destinationId: sourceId

        @emit "deviceDidAuth"

module.exports.DeviceAuthChannel = DeviceAuthChannel