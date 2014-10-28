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

S = require "string"
request = require "request"

{ Log }         = rekuire "castaway/util/Log"
{ UUID }        = rekuire "castaway/util/UUID"
{ Application } = rekuire "castaway/cast/Application"
{ AppURI }      = rekuire "castaway/cast/v2/AppURI"
{ Platform }    = rekuire "castaway/sys/Platform"

class ApplicationV2 extends Application

    @nextTransportId = 1

    constructor: (opts) ->
        @appId = opts.appId
        @usesIpc = false
        @displayName = @appId
        @sessionId = UUID.randomUUID().toString()
        @statusText = ""
        @transportId = @genNextTransportId()
        @configServerAddress = "https://clients3.google.com/cast/chromecast/device/app?a={appid}"

    isProtocolVersionV2: ->
        true

    isRunning: ->
        return @running

    genNextTransportId: ->
        ApplicationV2.nextTransportId += 2
        return "web-" + ApplicationV2.nextTransportId

    launch: (@launchedCallback) ->
        if @appId.indexOf("app:?") == 0
            @parseNewStyle @appId
        else
            @parseOldStyle @configServerAddress, @appId

    launchInternal: (url) ->
        Log.i "AppV2:launch: #{@displayName}"
        Platform.getInstance().launchBrowser(url)

    stop: ->
        @emit "close"
        Platform.getInstance().stopBrowser()

    parseNewStyle: (appId) ->
        appUri = AppURI.parse(appId)
        Log.i "解析应用程序配置 ..."
        Log.i appUri

        if typeof appUri.id is "string"
            if typeof appUri.ms is "string"
                @parseOldStyle appUri.ms, appUri.id
            else
                @parseOldStyle @configServerAddress, appUri.id

        else if typeof appUri.uri is "string"
            @displayName = appUri.dn or appUri.uri
            @usesIpc = true
            @appUrl = appUri.uri
            @launchInternal @appUrl

        else if typeof appuri.url is "string"
            @displayName = appUri.dn or appUri.url
            @usesIpc = true
            @appUrl = appUri.url
            @launchInternal @appUrl

    parseOldStyle: (serverAddr, appId) ->
        Log.i "开始下载应用程序配置 ..."
        configUrl = S(serverAddr).template({appid: appId}, '{', '}').s;
        Log.i "ConfigUrl : #{configUrl}"

        request configUrl, (error, response, body) =>
            Log.i "应用程序配置下载结束 ... #{body}"

            if not error and response.statusCode == 200

                # {"display_name":"ITMediaPlayer",
                #  "uses_ipc":true,
                #  "app_id":"E9C6F80E",
                #  "url":"https://simplemediaplayer.sinaapp.com/static/sample_media_receiver.html"}
                appInfo = JSON.parse body.substring(")]}'\n".length)

                @displayName = appInfo.display_name
                @usesIpc = appInfo.uses_ipc
                @appId = appInfo.app_id
                @appUrl = appInfo.url

                @launchInternal @appUrl

            else
                console.log "ERROR:#{error}"

    #
    # 接收到 ReceiverApplication 的 "ready" 消息
    #
    notifyApplicationDidReady: (message) ->
        console.log("应用程序启动完毕 ...");

        @statusText = message.statusText;
        @namespaces = message.activeNamespaces;
        @running = true;
        @launchedCallback? this

        @emit "didLaunch", this

    #
    # 更新状态，触发 'statusUpdate' 事件
    #
    updateStatusText: (statusText) ->
        @statusText = statusText
        process.Tick => @emit "statusUpdate"

module.exports.ApplicationV2 = ApplicationV2