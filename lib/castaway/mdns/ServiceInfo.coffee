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

Log = rekuire "castaway/util/Log"


#
# Service information
#
class ServiceInfo

    #
    # Create a service description.
    # type: fully qualified service type name
    # name: fully qualified service name
    # address: IP address as unsigned short, network byte order
    # port: port that the service runs on
    # weight: weight of the service
    # priority: priority of the service
    # properties: dictionary of properties (or a string holding the
    #             bytes for the text field)
    # server: fully qualified name for service host (defaults to name)
    #
    constructor: (opts) ->
        if not opts.type or not opts.name
            throw "InvalidArgumentException"

        Log.i "B"

        Log.i "#{opts.name}"
        Log.i "#{opts.type}"

        if not opts.name.endsWith(opts.type)
            throw "BadTypeInNameException"

        Log.i "C"

        @type = opts.type
        @name = opts.name
        @address = opts.address or null
        @port = opts.port or null
        @weight = opts.weight or 0
        @priority = opts.priority or 0

        if opts.server
            @server = opts.server
        else
            @server = opts.name

        @setProperties opts.properties or null

    setProperties: (properties) ->
        Log.i "ServiceInfo::setProperties(#{properties})"

module.exports = ServiceInfo