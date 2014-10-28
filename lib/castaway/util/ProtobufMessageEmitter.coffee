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
net = require "net"
util = require "util"
colors = require "colors"

class ProtobufMessageEmitter

    constructor: (socket, callback) ->
        @callback = callback
        @messageSize = -1
        @buffer = new Buffer 0

        socket.on "end", =>

        socket.on "error", (err) =>
            console.log "Error:#{err.toString()}".red.bold

        socket.on "data", (data) =>
            @didReceiveNetworkData data

    didReceiveNetworkData: (data) ->
        @buffer = Buffer.concat [@buffer, data]

        while true
            if @messageSize < 0
                if @buffer.length > 4
                    @messageSize = @buffer.readInt32BE 0
                    @buffer = @buffer.slice 4
                else
                    break

            # 收到完整的数据包
            if @messageSize > 0
                if @buffer.length >= @messageSize
                    msgBuf = @buffer.slice 0, @messageSize
                    msg = @decodeProtobuf msgBuf

                    if @callback then @callback msg

                    if @buffer.length > @messageSize
                        @buffer = @buffer.slice @messageSize
                    else
                        @buffer = new Buffer 0
                    @messageSize = -1
                else
                    break

    decodeProtobuf: (msgBuf) ->
        return {}

module.exports.ProtobufMessageEmitter = ProtobufMessageEmitter