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
var events = require("events");

var JsonMessageEmitter = require('./cast/v2/JsonMessageEmitter');

module.exports = {
    setUp: function (callback) {
        this.mockSocket = new events.EventEmitter();
        callback();
    },

    tearDown: function (callback) {
        callback();
    },

    // 测试一个数据包中包含消息的一部分分片
    testPieces: function (test) {
        var parsedMessages = new Array();
        new JsonMessageEmitter(this.mockSocket, function (jsonMessage) {
            parsedMessages.push(jsonMessage);
        });

        this.mockSocket.emit('data', new Buffer('2'));
        this.mockSocket.emit('data', new Buffer('1:{"type":"GE'));
        this.mockSocket.emit('data', new Buffer('T_STATUS"}'));

        test.equal(parsedMessages.length, 1);
        test.done();
    },

    // 测试一个数据包中包含完整的消息
    testWhole: function (test) {
        var parsedMessages = new Array();
        var emitter = new JsonMessageEmitter(this.mockSocket, function (jsonMessage) {
            parsedMessages.push(jsonMessage);
        });
        this.mockSocket.emit('data', new Buffer('21:{"type":"GET_STATUS"}'));
        test.equal(parsedMessages.length, 1);
        test.deepEqual(parsedMessages[0], {type: "GET_STATUS"});
        test.done();
    },

    // 测试一个数据包中包含多个消息
    testMulti: function (test) {
        var parsedMessages = new Array();
        var emitter = new JsonMessageEmitter(this.mockSocket, function (jsonMessage) {
            parsedMessages.push(jsonMessage);
        });
        this.mockSocket.emit('data', new Buffer('21:{"type":"GET_STATUS"}18:{"name":"jianglu"}'));
        test.equal(parsedMessages.length, 2);
        test.deepEqual(parsedMessages[0], {type: "GET_STATUS"});
        test.deepEqual(parsedMessages[1], {name: "jianglu"});
        test.done();
    },

    // 测试一个数据包中包含多个或者部分消息
    testMixed: function (test) {
        var parsedMessages = new Array();
        var emitter = new JsonMessageEmitter(this.mockSocket, function (jsonMessage) {
            parsedMessages.push(jsonMessage);
        });
        this.mockSocket.emit('data', new Buffer('21:{"type":"GET_STATUS"}18:{"na'));
        this.mockSocket.emit('data', new Buffer('me":"jianglu"}'));
        test.equal(parsedMessages.length, 2);
        test.deepEqual(parsedMessages[0], {type: "GET_STATUS"});
        test.deepEqual(parsedMessages[1], {name: "jianglu"});
        test.done();

    },

    // 测试中文消息
    testChinese: function (test) {
        var parsedMessages = new Array();
        var emitter = new JsonMessageEmitter(this.mockSocket, function (jsonMessage) {
            parsedMessages.push(jsonMessage);
        });
        test.equals((new Buffer('{"name":"蒋露"}')).length, 17);
        this.mockSocket.emit('data', new Buffer('17:{"name":"蒋露"}'));
        test.equal(parsedMessages.length, 1);
        test.deepEqual(parsedMessages[0], {name: "蒋露"});
        test.done();
    }
};