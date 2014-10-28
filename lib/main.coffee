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

global.rekuire = require "rekuire"

os = require "os"
fs = require "fs"
path = require "path"
colors = require "colors"
child_process = require "child_process"

fs.readDataSync = (filePath) ->
    fs.readFileSync(path.dirname(module.filename) + "/data/" + filePath)

main = ->
    String::startsWith = (prefix) ->
        return @indexOf(prefix) == 0

    String::endsWith = (suffix) ->
        return @match(suffix + "$").toString() == suffix

    { CastDaemon } = rekuire "castaway/CastDaemon"

    castDaemon = new CastDaemon()
    castDaemon.start()

# 触发实例生成
#    Platform = rekuire "Platform"
#    Platform.getInstance()
#
#    SSDPServer = rekuire "v1/SSDPServer"
#    new SSDPServer()
#
#    CastServerV2 = rekuire "v2/CastServer"
#    global.cast.server2 = new CastServerV2()
#
#    CastServerV1 = rekuire "v1/CastServerV1"
#    new CastServerV1();
#
#    mDNSServer = rekuire "v2/MDNSServer"
#    mDNSServer.getInstance().startServer();

exitHandler = (options, err) ->
    if options.cleanup then console.log('clean')
    if err then console.error("\n\n\n\n\n#{err.stack}\n\n\n\n\n".redBG)
    if options.exit then process.exit()

# do something when app is closing
process.on "exit", exitHandler.bind(null, {cleanup: true})

# catches ctrl + c event
process.on "SIGINT", exitHandler.bind(null, {exit: true})

# catches uncaught exceptions
process.on "uncaughtException", (err) ->
    console.log "Caught exception: #{err.stack}"

# 2s后启动主程序
setTimeout main, 2000
