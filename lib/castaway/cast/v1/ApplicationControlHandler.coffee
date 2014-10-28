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

{ ApplicationManager } = rekuire "castaway/cast/ApplicationManager"

#
# Creates Websocket Channel. This is requested by 2nd screen application
# {"/app/([^/]+)", ChannelFactory},
#
# /apps/Post_TV_App/web-1
#
class ApplicationControlHandler

    # Handle http request
    onHttpRequest: (req, res) ->
        segs = url.parse(req.url)
        @host = req.headers.host
        @appId = (segs.path.replace "/apps/", "").replace "/web-1", ""
        @appConfig = @findAppConfig(@appId)

        if @appConfig
            console.log "ApplicationControlHandler: #{req.method} #{@appId} #{@host}".green

            if req.method == "GET"
                @responseStatus req, res
            else if req.method == "POST"
                @launchApplication req, res
            else if req.method == "DELETE"
                @stopApplication req, res
        else
            res.writeHead 404
            res.end ""

    # 返回应用状态
    # 合理的做法是
    #
    # currentApp = App.getCurrentApp()
    #
    # if currentApp.getId() == @appId
    #     "running"
    #     connectionSvcURL = currentApp.getConnectionServiceURL()
    #     protocols = currentApp.getSupportedProtocols()
    # else
    #     "stopped"
    #
    responseStatus: (req, res) ->
        body = []

        body.push "<?xml version='1.0' encoding='UTF-8'?>\n"
        body.push "<service xmlns='urn:dial-multiscreen-org:schemas:dial'>\n"
        body.push "  <name>#{@appId}</name>\n"
        body.push "  <options allowStop='true'/>\n"

        app = ApplicationManager.getInstance().getCurrentApplication()

        if app?.isProtocolVersionV1() and app.getId() is @appId
            state = app?.getState()
            if state is "running"
                body.push "  <servicedata xmlns='urn:chrome.google.com:cast'>\n"
                connSvcURL = app.getConnectionServiceURL()
                if connSvcURL
                    body.push "    <connectionSvcURL>#{connSvcURL}</connectionSvcURL>\n"
                    body.push "    <protocols>\n"
                    protocols = app.getSupportedProtocols()
                    for protocol in protocols
                        body.push "      <protocol>#{protocol}</protocol>\n"
                    body.push "    </protocols>\n"
                body.push "  </servicedata>\n"

            body.push "  <state>#{state}</state>\n"
            if state is "running"
                body.push "  <activity-status xmlns=\"urn:chrome.google.com:cast\">\n"
                body.push "    <description>#{@appId} Receiver</description>\n"
                body.push "  </activity-status>\n"
                body.push "  <link rel='run' href='web-1'/>\n"
        else
            body.push "  <state>stopped</state>\n"

        body.push "</service>\n"

        bodyContent = body.join ""
        console.log bodyContent

        res.writeHead 200,
            "Content-Length": bodyContent.length
            "Content-Type": "application/xml"
            "Connection": "keep-alive"
            "Access-Control-Allow-Method": "GET, POST, DELETE, OPTIONS"
            "Access-Control-Expose-Headers": "Location"
            "Cache-Control": "no-cache, must-revalidate, no-store"
        res.end bodyContent

    #
    # 启动应用程序
    #
    launchApplication: (req, res) ->
        postData = null
        req.on "data", (data) =>
            if not postData then postData = ""
            postData += data
        req.on "end", =>
            appUrl = @appConfig.url
            if appUrl.indexOf "$POST_DATA" >= 0 and postData
                appUrl = appUrl.replace "$POST_DATA", postData

            appMgr = ApplicationManager.getInstance()
            app = appMgr.getCurrentApplication()

            if app?.isProtocolVersionV1() and app?.getId() == @appId
                # app was launched
            else
                app = appMgr.launchApplicationV1
                    protocolVersion: 1.0
                    id: @appId
                    host: @host
                    appUrl: appUrl
                    supportedProtocols: @appConfig.supported_protocols

            # Location 指导 SENDER 连接正确的 APP 地址
            res.writeHead 201,
                "Content-Type": "application/xml"
                "Access-Control-Allow-Method": "GET, POST, DELETE, OPTIONS"
                "Access-Control-Expose-Headers": "Location"
                "Cache-control": "no-cache, must-revalidate, no-store"
                "Location": "http://#{@host}/apps/#{@appId}/web-1"
            res.end()

    stopApplication: (req, res) ->
        appMgr = ApplicationManager.getInstance()
        app = appMgr.getCurrentApplication()
        if app?.isProtocolVersionV1() and app.getId() is @appId
            app.stop()
        res.writeHead 200, ""
        res.end()

    findAppConfig: (appId) ->
        { ApplicationConfigs } = rekuire "castaway/cast/v1/ApplicationConfigs"
        for i of ApplicationConfigs.applications
            appConfig = ApplicationConfigs.applications[i]
            if appConfig.app_id is appId and appConfig.url
                return appConfig
        return null

module.exports.ApplicationControlHandler = ApplicationControlHandler
