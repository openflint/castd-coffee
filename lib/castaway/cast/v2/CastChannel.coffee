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

#
# A GCKCastChannel is used to send and receive messages that are tagged with a specific
# namespace. In this way, multiple channels may be multiplexed over a single connection
# to the device.
# <p>
# Subclasses should implement the @link CastChannel#didReceiveTextMessage: @endlink and/or
# @link CastChannel#didReceiveBinaryMessage: @endlink methods to process incoming messages,
# and will typically provide additional methods for sending messages that are specific to a
# given namespace.
#
# @ingroup Messages
#
class CastChannel extends events.EventEmitter

    constructor: (@protocolNamespace) ->
        @handler = null

    getProtocolNamespace: ->
        return @protocolNamespace

    #
    # Called when a text message has been received for this channel.
    # The default implementation is a no-op.
    #
    # @param message The message string.
    #
    didReceiveTextMessage: (sourceId, destinationId, message) -> null

    #
    # Called when a binary message has been received for this channel.
    # The default implementation is a no-op.
    #
    # @param data The binary data.
    #
    didReceiveBinaryMessage: (sourceId, destinationId, data) -> null

    #
    # Sends a text message.
    #
    # @param args.message The message string.
    # @param args.destinationID The destination channel id
    # @return <code>yes</code> on success or <code>no</code> if the message could not be sent (because
    # the handler is not connected, or because the send buffer is too full at the moment).
    #
    sendTextMessage: (args) ->
        if @handler
            return @handler.sendTextMessage
                namespace: @protocolNamespace
                sourceId: args.sourceId
                destinationId: args.destinationId
                message: args.message
        return no

    #
    # Sends a binary message.
    #
    # @param args.data The message data.
    # @param args.destinationID The destination channel id
    # @return <code>yes</code> on success or <code>no</code> if the message could not be sent (because
    # the handler is not connected, or because the send buffer is too full at the moment).
    #
    sendBinaryMessage: (args) ->
        if @handler
            return @handler.sendBinaryMessage
                namespace: @protocolNamespace
                sourceId: args.sourceId
                destinationId: args.destinationId
                data: args.data
        return no

module.exports.CastChannel = CastChannel