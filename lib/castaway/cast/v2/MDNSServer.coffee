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
uuid = require "uuid"
fs = require "fs"
os = require "os"
colors = require "colors"
child_process = require "child_process"

{ Log }      = rekuire "castaway/util/Log"
{ Platform } = rekuire "castaway/sys/Platform"
{ NetworkChecker }  = rekuire "castaway/net/NetworkChecker"
mdns = rekuire "castaway/mdns/mdns"


class MDNSServer

    constructor: (@daemon) ->
        @networkChecker = @daemon.getNetworkChecker()

    startServer: (name) ->
        console.log "MDNSServer.startServer : #{name}"

        # advertise a http server on port 8009
        options = {};

        options.name = name;
        options.flags = 2;
        options.txtRecord =
            id: name # 'b68d5c314d884b6a9de588cee6978279',
            ve: "02"
            md: "MatchStick"
            ic: "/setup/icon.png"
            ca: "5"
            fn: name
            st: "0"

        if @advertisement && @advertisement.status
            Log.d "reset MDNSServer ..."
            @advertisement.set mdns.tcp("MatchStick"), 8009, options
        else
            Log.d "create MDNSServer ..."
            @advertisement = mdns.createAdvertisement mdns.tcp("MatchStick"), 8009, options
            @advertisement.start()

    resetServer: (name) ->
        # ipv4 在mdns server discover 判断启动,故设置与启动使用相同
        @startServer name

    stopServer: ->
        Log.d "stop MDNSServer ..."
        if @advertisement && @advertisement.status
            Log.d "real stop MDNSServer ..."
            @advertisement.stop()

    start: ->
        Log.d "Starting MDNSServer ..."

        # 监听设备名称改变事件
        Platform.getInstance().on "deviceNameChanged", (name) =>
            Log.i "MDNS: deviceNameChanged: #{name}"
            @resetServer name

        # 监听网络状态变化
        Platform.getInstance().on "network_changed", (changed) =>
            Log.i "MDNS: network_changed: #{changed}"
            if "ap" == changed or "station" == changed
                deviceName = Platform.getInstance().getDeviceName()
                if deviceName
                    @stopServer()
                    @resetServer deviceName
            else
                Log.i "MDNS: unknow network_changed"

        # 监视系统状态变更
        Platform.getInstance().on "statusChanged", =>
            Log.i "MDNS: statusChanged"
            deviceName = Platform.getInstance().getDeviceName()
            if deviceName
                @resetServer deviceName

#        @networkChecker.on NetworkChecker.EVENT_ADDRESS_ADDED, (event) =>
#            Log.i "MDNS: EVENT_ADDRESS_ADDED: #{event.address}"
#            deviceName = Platform.getInstance().getDeviceName()
#            if deviceName
#                @stopServer()
#                @startServer deviceName

#        @networkChecker.on NetworkChecker.EVENT_ADDRESS_REMOVED, (event) =>
#            Log.i "MDNS: EVENT_ADDRESS_REMOVED: #{event.address}"
#            @stopServer()

module.exports.MDNSServer = MDNSServer
