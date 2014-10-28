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

fs = rekuire "fs"

{ Log } = rekuire "castaway/util/Log"

class CastMessageSerdes

    constructor: (@schema) ->

    createDescription: ->
        Protobuf = try (require "protobuf")?.Protobuf
        if not Protobuf
            Protobuf = try require "node-protobuf"
        return new Protobuf fs.readDataSync "cast_channel.desc"

    serialize: (msg) ->
        desc = @createDescription()
        @convertFieldForSerialize msg

        # Log.i "CastMessageSerdes::serialize"
        # Log.i msg

        return desc.Serialize msg, @schema

    deserialize: (data) ->
        desc = @createDescription()
        msg = desc.Parse data, @schema

        # Log.i "CastMessageSerdes::deserialize"
        # Log.i msg

        @convertFieldForDeserialize msg
        return msg

    convertFieldForSerialize: (msg) ->

        if @schema == "CastMessage"

            msg.protocol_version = msg.protocolVersion
            delete msg.protocolVersion

            msg.source_id = msg.sourceId
            delete msg.sourceId

            msg.destination_id = msg.destinationId
            delete msg.destinationId

            msg.payload_type = msg.payloadType
            delete msg.payloadType

            if msg.payloadUtf8
                msg.payload_utf8 = msg.payloadUtf8
                delete msg.payloadUtf8

            if msg.payloadBinary
                msg.payload_binary = msg.payloadBinary
                delete msg.payloadBinary

        else if @scheme == "AuthResponse"

            msg.client_auth_certificate = msg.clientAuthCertificate
            delete msg.clientAuthCertificate

    convertFieldForDeserialize: (msg) ->

        if @schema == "CastMessage"

            if msg.protocol_version
                msg.protocolVersion = msg.protocol_version
                delete msg.protocol_version

            if msg.source_id
                msg.sourceId = msg.source_id
                delete msg.source_id

            if msg.destination_id
                msg.destinationId = msg.destination_id
                delete msg.destination_id

            if msg.payload_type
                msg.payloadType = msg.payload_type
                delete msg.payload_type

            if msg.payload_utf8
                msg.payloadUtf8 = msg.payload_utf8
                delete msg.payload_utf8

            if msg.payload_binary
                msg.payloadBinary = msg.payload_binary
                delete msg.payload_binary

        else if @scheme == "AuthResponse"

            if msg.client_auth_certificate
                msg.clientAuthCertificate = msg.client_auth_certificate
                delete msg.client_auth_certificate

module.exports.CastMessageSerdes = CastMessageSerdes