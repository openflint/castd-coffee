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

events = require "events"
os = require "os"

{ Log } = rekuire "castaway/util/Log"
{ MDNSHelper } = rekuire "castaway/mdns/MDNSHelper"
{ Platform } = rekuire "castaway/sys/Platform"

BufferBuilder = rekuire "castaway/util/BufferBuilder"

class mdnsSdServer extends events.EventEmitter

    @MDNS_ADDRESS = "224.0.0.251"
    @MDNS_PORT = 5353
    @MDNS_TTL = 1
    @MDNS_LOOPBACK_MODE = true

    constructor: ->
        events.EventEmitter.call(this)
        @on "ready", =>
            Log.d "MDNSServer is ready !"

        @fullProtocol
        @serverName 
        @txtRecord
        @serverPort
        @flags  
        @address = @getAddress()
        @localName 
        @dnsSdResponse
        @status = false

    getAddress: ->
        address = {} 
        ifaces = os.networkInterfaces()
        for k,v of ifaces
            if (k.toLowerCase().indexOf "lo") < 0
                ipadd = {}
                for i in v
                    if i.family == "IPv4"
                        ipadd.ipv4 = i.address
                    if i.family == "IPv6"
                        ipadd.ipv6 = i.address
                # castd node ipv6 not found
                if ipadd.ipv4 #&& ipadd.ipv6
                    address = ipadd
                    break
        return address

    set: (fullProtocol, port, options) ->
        @fullProtocol = fullProtocol
        @serverPort = port
        @serverName = options.name
        @txtRecord = options.txtRecord
        @flags = options.flags
        @resetDnsSdResponse()

    resetDnsSdResponse: ->
        @address = @getAddress()
        @localName = @serverName + @address.ipv4 
        @dnsSdResponse = MDNSHelper.creatDnsSdResponse 0, @fullProtocol, @serverName, @serverPort, @txtRecord, @address, @localName

    _start: ->
        if !@running 
            @address = @getAddress()
            if @address.ipv4 && @dnsSdResponse
                Log.d "Starting MDNSServer ..."

                dgram = require "dgram"
                @socket = dgram.createSocket "udp4"

                @socket.on "error", (err) =>
                    Log.e err

                @socket.on "message", (data, rinfo) =>
                    @onReceive data, rinfo.address, rinfo.port

                @socket.on "listening", =>
                    Log.d "MDNS socket is listened"
                    @socket.setMulticastTTL mdnsSdServer.MDNS_TTL
                    @socket.setMulticastLoopback mdnsSdServer.MDNS_LOOPBACK_MODE

                @socket.bind mdnsSdServer.MDNS_PORT, "0.0.0.0", =>
                    Log.d "MDNS socket is binded"
                    @socket.addMembership mdnsSdServer.MDNS_ADDRESS, @address.ipv4
                    @running = true
                    @listen()
                    @emit "ready"
                @status = true
            else
                Log.d "MDNSServer start fail"
                if not @dnsSdResponse
                    Log.d "MDNSServer dont config , please config"
                if not @address.ipv4
                    Log.d "MDNSServer dont ipv4, please check network"

    start: ->
        @_start()
        setTimeout ( =>
            @_start() ), 5000 

    stop: ->
        @socket.close()
        @status = false
        Log.d "MDNSServer stop"

    listen: ->
        if not @running then return

    onReceive: (data, address, port) ->
        message = MDNSHelper.decodeMessage data
        if message.isQuery
            for question in message.questions
                if question.name is @fullProtocol
                    if question.type is MDNSHelper.TYPE_PTR
                        @resetDnsSdResponse()
                        @dnsSdResponse.transactionID = message.transactionID
                        # test client find server
                        #serverResponse = MDNSHelper.decodeMessage MDNSHelper.encodeMessage @dnsSdResponse
                        #Log.i MDNSHelper.parseDnsSdResponse serverResponse
                        buff = new Buffer MDNSHelper.encodeMessage @dnsSdResponse
                        Log.i "mdns receive message: #{message}".red
                        @socket.send buff, 0, buff.length, port, address, =>
                            Log.i "mdnsResponse to #{address}:#{port} done".red

module.exports.mdnsSdServer = mdnsSdServer
