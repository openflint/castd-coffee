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

class AppURI

    @parse: (uri) ->
        result = {}
        data = uri.split("app:?")[1]

        if not data or data.length == 0
            return result

        params = data.split "&"
        params.forEach (param) =>
            keyval = param.split "="

            # This keyval is invalid, skip it
            if keyval.length != 2 then return

            key = keyval[0]
            val = keyval[1]

            # Clean up torrent name
            if key == "dn"
                val = decodeURIComponent(val).replace(/\+/g, " ")

            # Address tracker (tr) is an encoded URI, so decode it
            if key == "tr"
                val = decodeURIComponent(val)

            # Return keywords as an array
            if key == "kt"
                val = decodeURIComponent(val).split("+")

            # Decode
            if key == "uri" or key == "url" or key == "ms"
                val = decodeURIComponent(val)

            # If there are repeated parameters, return an array of values
            if result[key]
                if Array.isArray result[key]
                    result[key].push val
                else
                    old = result[key]
                    result[key] = [old, val]
            else
                result[key] = val

        # Convenience properties to match parse-torrent results
        m
        if result.xt and (m = result.xt.match(/^urn:btih:(.{40})/))
            result.infoHash = new Buffer(m[1], 'hex').toString('hex')
        else if result.xt && (m = result.xt.match(/^urn:btih:(.{32})/))
            decodedStr = base32.decode(m[1]);
            result.infoHash = new Buffer(decodedStr, 'binary').toString('hex')

        if result.dn then result.name = result.dn
        if result.tr then result.announce = result.tr
        if result.kt then result.keywords = result.kt

        return result

module.exports.AppURI = AppURI