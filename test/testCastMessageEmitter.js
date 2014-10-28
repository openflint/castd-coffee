/*

 Copyright (C) 2013-2014, Infthink (Beijing) Technology Co., Ltd.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS-IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 */

var assert = require('assert');
var util = require('util');
var fs = require('fs');
var events = require("events");

var Protobuf = require("protobuf").Protobuf;
var ProtobufDesc = new Protobuf(fs.readFileSync("./data/cast_channel.desc"));

var CastMessageEmitter = require('../v2/CastMessageEmitter');

module.exports = {
    setUp: function (callback) {
        this.mockSocket = new events.EventEmitter();
        callback();
    },

    tearDown: function (callback) {
        callback();
    },

    testUtf8Payload: function (test) {
        var receivedCastMessageObj = null;
        new CastMessageEmitter(this.mockSocket, function (castMessage) {
            receivedCastMessageObj = castMessage;
        });

        var castMessageObj = {
            protocol_version: 'CASTV2_1_0',
            source_id: 'gms_cast_mrp-21',
            destination_id: 'receiver-0',
            namespace: 'urn:x-cast:com.google.cast.receiver',
            payload_type: 'STRING',
            payload_utf8: 'TEST PAYLOAD'
        };
        var castMessage = ProtobufDesc.Serialize(castMessageObj, "CastMessage");

        var lengthBuffer = new Buffer(4);
        lengthBuffer.writeInt32BE(castMessage.length, 0);
        this.mockSocket.emit('data', lengthBuffer);
        this.mockSocket.emit('data', castMessage);

        test.deepEqual(receivedCastMessageObj, castMessageObj);
        test.done();
    },

    testBinaryPayload: function (test) {
        var receivedCastMessageObj = null;
        new CastMessageEmitter(this.mockSocket, function (castMessage) {
            receivedCastMessageObj = castMessage;
        });

        var castMessageObj = {
            protocol_version: 'CASTV2_1_0',
            source_id: 'gms_cast_mrp-21',
            destination_id: 'receiver-0',
            namespace: 'urn:x-cast:com.google.cast.receiver',
            payload_type: 'BINARY',
            payload_binary: new Buffer('TEST BINARY PAYLOAD')
        };
        var castMessage = ProtobufDesc.Serialize(castMessageObj, "CastMessage");

        var lengthBuffer = new Buffer(4);
        lengthBuffer.writeInt32BE(castMessage.length, 0);
        this.mockSocket.emit('data', lengthBuffer);
        this.mockSocket.emit('data', castMessage);

        test.deepEqual(receivedCastMessageObj, castMessageObj);
        test.done();
    }
};