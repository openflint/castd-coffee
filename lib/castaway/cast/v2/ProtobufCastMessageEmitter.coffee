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

{ CastMessageSerdes }       = rekuire "castaway/cast/v2/CastMessageSerdes"
{ ProtobufMessageEmitter }  = rekuire "castaway/util/ProtobufMessageEmitter"

class ProtobufCastMessageEmitter extends ProtobufMessageEmitter

    constructor: (socket, callback) ->
        super(socket, callback)

    decodeProtobuf: (msgBuf) ->
        return (new CastMessageSerdes "CastMessage").deserialize msgBuf

module.exports.ProtobufCastMessageEmitter = ProtobufCastMessageEmitter