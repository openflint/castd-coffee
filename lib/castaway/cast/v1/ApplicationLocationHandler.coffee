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

url = rekuire "url"
colors = require "colors"
events = require "events"

{ ApplicationManager } = rekuire "castaway/cast/ApplicationManager"

#
# ApplicationLocationHandler
#
class ApplicationLocationHandler

    # Handle http request
    onHttpRequest: (req, res) ->
        host = req.headers.host

        console.log "AppsHandler: #{req.method} #{host}".green

        headers =
            "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
            "Access-Control-Expose-Headers": "Location",
            "Content-Length": 0

        app = ApplicationManager.getInstance().getCurrentApplication()
        if app?.isProtocolVersionV1()
            headers["Location"] = "/apps/#{app.getId()}"

        # Access-Control-Allow-Method:GET, POST, DELETE, OPTIONS
        # Access-Control-Expose-Headers:Location
        # Content-Length:0
        # Location:/apps/a7f3283b-8034-4506-83e8-4e79ab1ad794_2

        res.writeHead 204, headers
        res.end()

module.exports.ApplicationLocationHandler = ApplicationLocationHandler
