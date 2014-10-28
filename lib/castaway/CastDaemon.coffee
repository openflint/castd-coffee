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

{ Log } = rekuire "castaway/util/Log"

class CastDaemon

    constructor: ->
        { NetworkChecker } = rekuire "castaway/net/NetworkChecker"

        @networkChecker = new NetworkChecker

        @networkChecker.on NetworkChecker.EVENT_ADDRESS_ADDED, (event) =>
            Log.i "EVENT_ADDRESS_ADDED: #{event.address}"
            Log.i event.sender.knowAddresses()

        @networkChecker.on NetworkChecker.EVENT_ADDRESS_REMOVED, (event) =>
            Log.i "EVENT_ADDRESS_REMOVED: #{event.address}"
            Log.i event.sender.knowAddresses()

        { TLSServer } = rekuire "castaway/cast/TLSServer"
        @tlsServer = new TLSServer

        { HTTPServer } = rekuire "castaway/cast/HTTPServer"
        @httpServer = new HTTPServer

        { TCPServer } = rekuire "castaway/cast/TCPServer"
        @tcpServer = new TCPServer

        { SSDPServer } = rekuire "castaway/cast/v1/SSDPServer"
        @ssdpServer = new SSDPServer this

        { CastServerV1 } = rekuire "castaway/cast/v1/CastServerV1"
        @castServerV1 = new CastServerV1 this

        { MDNSServer } = rekuire "castaway/cast/v2/MDNSServer"
        @mdnsServer = new MDNSServer this

        { CastServerV2 } = rekuire "castaway/cast/v2/CastServerV2"
        @castServerV2 = new CastServerV2 this

    getHTTPServer: ->
        @httpServer

    getTLSServer: ->
        @tlsServer

    getTCPServer: ->
        @tcpServer

    getNetworkChecker: ->
        @networkChecker

    start: ->
        @networkChecker.start()
        @mdnsServer.start()
        @ssdpServer.start()
        @httpServer.start()
        @tlsServer.start()
        @tcpServer.start()
        @castServerV1.start()
        @castServerV2.start()

module.exports.CastDaemon = CastDaemon
