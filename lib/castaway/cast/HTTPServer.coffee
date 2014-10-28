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

url = require "url"

{ Log } = rekuire "castaway/util/Log"

class HTTPServer

    constructor: ->
        @routes = []

    start: ->
        Log.d "Starting HTTP Server ..."

        http = require "http"
        @httpServer = http.createServer()

        @httpServer.on "request", (req, res) =>
            req.socket.setKeepAlive true
            req.socket.setNoDelay true
            @onHttpRequest req, res

        @httpServer.on "upgrade", (req, socket, upgradeHead) =>
            req.socket.setKeepAlive true
            req.socket.setNoDelay true
            wss = new (require "ws").Server {noServer: true}
            wss.handleUpgrade req, socket, upgradeHead, (client) =>
                @onWebSocketRequest req, client

        @httpServer.listen 8008

    addRoute: (path, handler) ->
        @routes.push
            path: path
            handler: handler

    findHandler: (path) ->
        for route in @routes
            if path.match(route.path)
                return new route.handler
        return null

    onHttpRequest: (req, res) ->
        Log.d "onHttpRequest: #{req.url}"
        segs = url.parse(req.url)
        handler = @findHandler segs.path
        handler?.onHttpRequest(req, res)
        if not handler
            res.writeHead 404
            res.end()

    onWebSocketRequest: (req, client) ->
        segs = url.parse(req.url)
        handler = @findHandler segs.path
        handler?.onWebSocketRequest req, client
        if not handler then client.close()

module.exports.HTTPServer = HTTPServer