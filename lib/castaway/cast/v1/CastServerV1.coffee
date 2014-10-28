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

{ EurekaInfoHandler }          = rekuire "castaway/cast/v1/EurekaInfoHandler"
{ DeviceDescHandler }          = rekuire "castaway/cast/v1/DeviceDescHandler"
{ ApplicationControlHandler }  = rekuire "castaway/cast/v1/ApplicationControlHandler"
{ ApplicationLocationHandler } = rekuire "castaway/cast/v1/ApplicationLocationHandler"
{ SenderConnectionHandler }    = rekuire "castaway/cast/v1/SenderConnectionHandler"
{ ReceiverConnectionHandler }  = rekuire "castaway/cast/v1/ReceiverConnectionHandler"
{ SystemControlHandler }       = rekuire "castaway/cast/v1/SystemControlHandler"
{ SessionHandler }             = rekuire "castaway/cast/v1/SessionHandler"

class CastServerV1

    constructor: (@castApp) ->

    start: ->
        httpServer = @castApp.getHTTPServer()

        # 路由表
        httpServer.addRoute /\/setup\/eureka_info$/, EurekaInfoHandler
        httpServer.addRoute /\/ssdp\/device-desc.xml$/, DeviceDescHandler
        httpServer.addRoute /\/apps\/[^\/]+$/, ApplicationControlHandler
        httpServer.addRoute /\/apps\/[^\/]+\/web\-[0-9]+$/, ApplicationControlHandler
        httpServer.addRoute /\/apps[\/]*$/, ApplicationLocationHandler
        httpServer.addRoute /\/connection\/[^\/]+$/, SenderConnectionHandler
        httpServer.addRoute /\/connection$/, ReceiverConnectionHandler
        httpServer.addRoute /\/system\/control$/, SystemControlHandler
        httpServer.addRoute /\/session\?\d+$/, SessionHandler


module.exports.CastServerV1 = CastServerV1