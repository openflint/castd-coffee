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

dgram = require "dgram"
events = require "events"
dns = require "dns"
os = require "os"
util = require "util"

{ Log } = rekuire "castaway/util/Log"

class SSDP extends events.EventEmitter

    @HttpHeader = /HTTP\/\d{1}\.\d{1} \d+ .*/
    @SsdpHeader = /^([^:]+):\s*(.*)$/

    constructor: (opts) ->
        opts = opts || {}

        @_init(opts)
        @_start()

        process.on "exit", =>
            @stop()

    #
    # Initializes instance properties.
    #
    _init: (opts) ->
        @_ssdpSig = opts.ssdpSig or @getSsdpSignature()

        @_ssdpIp = opts.ssdpIp or "239.255.255.250"
        @_ssdpPort = opts.ssdpPort or 1900
        @_ssdpTtl = opts.ssdpTtl or 1

        @_ipPort = @_ssdpIp + ":" + @_ssdpPort
        @_ttl = opts.ttl or 1800

        @_description = opts.description or "upnp/desc.html"

        @_usns = {}
        @_udn = opts.udn or "uuid:f40c2981-7329-40b7-8b04-27f187aecfb5"

    #
    # Creates and configures a UDP socket.
    # Binds event listeners.
    #
    _start: () ->
        # Configure socket for either client or server.
        @responses = {};

        @sock = dgram.createSocket "udp4"

        @sock.on "error", (err) ->
            console.error err, "Socker error"

        @sock.on "message", (msg, rinfo) =>
            @_parseMessage msg, rinfo

        @sock.on "listening", =>
            addr = @sock.address()
            console.info "SSDP listening on http://#{addr.address}:#{addr.port}"
            Log.i "@sock.addMembership #{@_ssdpIp}"
            @sock.addMembership @_ssdpIp, @ip
            Log.i "@sock.addMembership #{@_ssdpTtl}"
            @sock.setMulticastTTL @_ssdpTtl

    #
    # Routes a network message to the appropriate handler.
    #
    _parseMessage: (msg, rinfo) ->
        msg = msg.toString()

        # Log.i msg, rinfo

        type = msg.split("\r\n").shift()

        # HTTP/#.# ### Response
        if SSDP.HttpHeader.test type
            @_parseResponse msg, rinfo
        else
            @_parseCommand msg, rinfo

    #
    # Parses SSDP command.
    #
    _parseCommand: (msg, rinfo) ->
        lines = msg.toString().split "\r\n"
        type = lines.shift().split " " # command, such as "NOTIFY * HTTP/1.1"
        method = type[0]

        headers = {}

        lines.forEach (line) =>
            if line.length
                pairs = line.match SSDP.SsdpHeader
                if pairs
                    headers[pairs[1].toUpperCase()] = pairs[2] # e.g. {'HOST': 239.255.255.250:1900}

        switch method
            when "NOTIFY"
                @_notify headers, msg, rinfo
            when "M-SEARCH"
                @_msearch headers, msg, rinfo
            else
                console.warn message: "\n" + msg, rinfo: rinfo, "Unhandled NOTIFY event"

    #
    # Handles NOTIFY command
    #
    _notify: (headers, msg, rinfo) ->
        if not headers.NTS then console.trace headers, "Missing NTS header"

        switch headers.NTS.toLowerCase()
            # Device coming to life.
            when "ssdp:alive"
                @emit "advertise-alive", headers
            # Device shutting down.
            when "ssdp:byebye"
                @emit "advertise-bye", headers
            else
                console.trace message: "\n#{msg}", rinfo: rinfo, "Unhandled NOTIFY event"

    #
    # Handles M-SEARCH command.
    #
    _msearch: (headers, msg, rinfo) ->
        if not headers["MAN"] || not headers["MX"] || not headers["ST"] then return
        @_inMSearch headers["ST"], rinfo

    #
    # Parses SSDP response message.
    #
    _parseResponse: (msg, rinfo) ->
        if not @responses[rinfo.address]
            @responses[rinfo.address] = true
        @emit "response", msg, rinfo

    _inMSearch: (st, rinfo) ->
        peer = rinfo.address
        port = rinfo.port

        if st[0] == "\"" && st[st.length - 1] == "\""
            st = st.slice 1, -1 # unwrap quoted string

        Object.keys(@_usns).forEach (usn) =>
            udn = @_usns[usn]

            if st == "ssdp:all" || usn == st
                vars =
                    "ST": usn
                    "USN": udn
                    "LOCATION": "#{@_httphost}/#{@_description}"
                    "CACHE-CONTROL": "max-age=#{@_ttl}"
                    "DATE": (new Date()).toUTCString()
                    "SERVER": @_ssdpSig
                    "BOOTID.UPNP.ORG": "9"
                    "CONFIGID.UPNP.ORG": "1"
                    "OPT": "\"http://schemas.upnp.org/upnp/1/0/\"; ns=01"
                    "X-USER-AGENT": "redsonic"
                    "EXT": ""

                pkt = @getSSDPHeader "200 OK", vars, true

                # console.log {'peer': peer, 'port': port}, 'Sending a 200 OK for an M-SEARCH'

                message = new Buffer pkt

                @sock.send message, 0, message.length, port, peer, (err, bytes) =>
                    # console.trace message: pkt, "Sent M-SEARCH response"

    addUSN: (device) ->
        @_usns[device] = @_udn + "::" + device

    search: (st) ->
        require("dns").lookup require("os").hostname(), (err, add) =>
            vars =
                "HOST": @_ipPort
                "ST": st
                "MAN": "\"ssdp:discover\""
                "MX": 3
            pkt = @getSSDPHeader "M-SEARCH", vars

            # console.trace "Sending an M-SEARCH request"

            message = new Buffer pkt

            @sock.send message, 0, message.length, @_ssdpPort, @_ssdpIp, (err, bytes) =>
                # console.trace message: pkt, "Sent M-SEARCH request"

    #
    # Binds UDP socket to an interface/port
    # and starts advertising.
    #
    server: (ip, portno) ->
        @ip = ip
        if not portno then portno = "10293"

        @_usns[@_udn] = @_udn
        @_httphost = "http://" + ip + ":" + portno

        console.log "Will try to bind to 0.0.0.0:" + @_ssdpPort

        @sock.bind @_ssdpPort, "0.0.0.0", () =>
            console.info "UDP socket bound to 0.0.0.0:" + @_ssdpPort

            setTimeout (=>
                @advertise false), 10
            setTimeout (=>
                @advertise false), 1000

            # Wake up.
            setTimeout (=>
                @advertise true), 2000
            setTimeout (=>
                @advertise true), 3000

            # Ad loop.
            setInterval (=>
                @advertise true), 5000


    #
    # Advertise shutdown and close UDP socket.
    #
    stop: ->
        @advertise false
        @advertise false
        @sock.close()
        @sock = null

    #
    advertise: (alive) ->
        if not @sock then return
        if alive == undefined then alive = true

        Object.keys(@_usns).forEach (usn) =>
            udn = @_usns[usn]

            heads =
                HOST: @_ipPort
                NT: usn
                NTS: if alive then "ssdp:alive" else "ssdp:byebye"
                USN: udn

            if alive
                heads["LOCATION"] = @_httphost + "/" + @_description
                heads["CACHE-CONTROL"] = "max-age=1800"
                heads["SERVER"] = @_ssdpSig
                heads["BOOTID.UPNP.ORG"] = "9"
                heads["CONFIGID.UPNP.ORG"] = "1"
                heads["DATE"] = (new Date).toUTCString()
                heads["OPT"] = "\"http://schemas.upnp.org/upnp/1/0/\"; ns=01"
                heads["X-USER-AGENT"] = "redsonic"
                heads["EXT"] = ""

            # console.trace "Sending an advertisement event"

            out = new Buffer @getSSDPHeader "NOTIFY", heads

            @sock.send out, 0, out.length, @_ssdpPort, @_ssdpIp, (err, bytes) =>
                # console.info out.toString()

    getSSDPHeader: (head, vars, res) ->
        ret = ""
        if res == null then res = false

        if res
            ret = "HTTP/1.1 " + head + "\r\n"
        else
            ret = head + " * HTTP/1.1\r\n"

        Object.keys(vars).forEach (n) =>
            ret += n + ": " + vars[n] + "\r\n"

        return ret + "\r\n"

    getSsdpSignature: ->
        return "Linux/3.8.13+, UPnP/1.0, Portable SDK for UPnP devices/1.6.18"

module.exports.SSDP = SSDP