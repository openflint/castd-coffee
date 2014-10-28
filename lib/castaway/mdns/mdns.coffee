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

{ mdnsSdServer } = require './mdnsSdServer'
{ MDNSHelper } = require './MDNSHelper'

createAdvertisement = createAdvertisement:(fullProtocol, port, options) ->
    mdnsServer = new mdnsSdServer
    mdnsServer.set fullProtocol, port, options
    return mdnsServer

exports.createAdvertisement = createAdvertisement.createAdvertisement

exports.mdnsSdServer = mdnsSdServer

exports.tcp = MDNSHelper.protocolHelperTcp
exports.udp = MDNSHelper.protocolHelperUdp

