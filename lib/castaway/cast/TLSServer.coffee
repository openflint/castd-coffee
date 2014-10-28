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
tls = require "tls"

{ Log } = rekuire "castaway/util/Log"

class TLSServer

    constructor: ->
        @routes = []

    start: ->
        Log.d "Starting TLS Server ..."

        options =
            key: fs.readDataSync "agent1-key.pem"
            cert: fs.readDataSync "agent1-cert.pem"
            rejectUnauthorized: false
            allowHalfOpen: true

        @tlsServer = tls.createServer options, (cleartextStream) =>
            @onTlsRequest cleartextStream

        @tlsServer.on "clientError", (exception, securePair) =>
            console.log ("ClientError" + exception).redBG

        @tlsServer.listen 8009

    addHandler: (handler) ->
        @routes.push
            handler: handler

    onTlsRequest: (cleartextStream) ->
        Log.d "onTlsRequest: #{cleartextStream.remoteAddress}"
        for route in @routes
            handler = new route.handler
            handler.onTlsRequest cleartextStream

module.exports.TLSServer = TLSServer