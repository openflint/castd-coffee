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

module.exports.ApplicationConfigs =
    "applications": [
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "edaded98-5119-4c8a-afc1-de722da03562"
        "url": "http://chromecast.redbull.tv/receiver.php"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_restart": true
        "allow_empty_post_data": true
        "app_id": "PlayMovies"
        "url": "https://play.google.com/video/avi/eureka?$POST_DATA"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_restart": true
        "allow_empty_post_data": true
        "app_id": "00000000-0000-0000-0000-000000000000"
        "url": "chrome://home?remote_url=https%3A%2F%2Fclients3.google.com%2Fcast%2Fchromecast%2Fhome%3Fchs%3D1"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "1812335e-441c-4e1e-a61a-312ca1ead90e"
        "url": "http://api.viki.io/mobile/receiver.html"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "06ee44ee-e7e3-4249-83b6-f5d0b6f07f34"
        "url": "http://plexapp.com/chromecast/qa/index.html"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "2be788b9-b7e0-4743-9069-ea876d97ac20"
        "url": "http://vevo.com/googlecastplayer"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_restart": true
        "allow_empty_post_data": true
        "app_id": "GoogleSantaTracker"
        "url": "http://www.gstatic.com/santatracker_chromecast_receiver/santacast.html"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "06ee44ee-e7e3-4249-83b6-f5d0b6f07f34_1"
        "url": "http://plexapp.com/chromecast/production/index.html"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "Pandora_App"
        "url": "https://tv.pandora.com/cast?$POST_DATA"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "aa35235e-a960-4402-a87e-807ae8b2ac79"
        "url": "http://receiver.aviatheapp.com/"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_restart": true
        "allow_empty_post_data": false
        "app_id": "YouTube"
        "url": "https://www.youtube.com/tv?$POST_DATA"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "HBO_App"
        "url": "https://devicecast.hbogo.com/chromecast/player.html?$POST_DATA"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "TicTacToe"
        "url": "http://www.gstatic.com/eureka/sample/tictactoe/tictactoe.html"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "Revision3_App"
        "url": "http://revision3.com/receiver/revision3"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "Songza_App"
        "url": "http://songza.com/devices/google-cast/receiver/1/"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "a7f3283b-8034-4506-83e8-4e79ab1ad794_2"
        "url": "http://chromecast.real.com/cloudcast.html"
        "dial_enabled": true
    ,
        "use_channel": false
        "allow_restart": false
        "allow_empty_post_data": true
        "external": true
        "native_app": true
        "dial_info": "<port>9080</port><capabilities>websocket</capabilities>"
        "app_id": "Netflix"
        "dial_enabled": true
        "command_line": "/bin/logwrapper /netflix/bin/netflix_init --data-dir /data/netflix/data -I /data/netflix/AACS -D QWS_DISPLAY=directfb -D LD_LIBRARY_PATH=/system/lib:/netflix/qt/lib -D NF_PLAYREADY_DIR=/data/netflix/playready -D KEYSTORE=/data/netflix/AACS -D KEYBOARD_PORT=7000 -D ENABLE_SECURITY_PATH=1 -D DISABLE_SECURITY_PATH_VIDEO=0 -D DISABLE_SECURITY_PATH_AUDIO=1 --dpi-friendlyname $FRIENDLY_NAME -Q source_type=12&dial=$URL_ENCODED_POST_DATA"
    ,
        "use_channel": true
        "allow_restart": true
        "allow_empty_post_data": true
        "app_id": "GoogleMusic"
        "url": "https://play.google.com/music/cast/player"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "18a8aeaa-8e3d-4c24-b05d-da68394a3476_1"
        "url": "http://www.beyondpod.mobi/android/chromecast/prod.aspx"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "Post_TV_App"
        "url": "http://rcvr.washingtonpost.com/Receiver/index.html?$POST_DATA"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_restart": true
        "allow_empty_post_data": false
        "app_id": "ChromeCast"
        "url": "https://www.gstatic.com/cv/receiver1.html?$POST_DATA"
        "dial_enabled": true
    ,
        "use_channel": true
        "allow_empty_post_data": true
        "app_id": "Hulu_Plus"
        "url": "https://secure.hulu.com/dash/chromecast_player?$POST_DATA"
        "dial_enabled": true
    ,
        "display_name": "Default Media Receiver"
        "uses_ipc": true
        "app_id": "CC1AD845"
        "resolution_height": 0
        "url": "https://www.gstatic.com/eureka/player/player.html?skin=https://www.gstatic.com/eureka/player/0000/skins/cast/skin.css"
    ,
        "display_name": "Chrome Mirroring"
        "uses_ipc": true
        "external": true
        "native_app": true
        "app_id": "0F5096E8"
        "resolution_height": 0
        "command_line": "/bin/logwrapper /chrome/v2mirroring --vmodule=*media/cast/*=1,*=0 $POST_DATA"
    ]
    "configuration":
        "idle_screen_app": "00000000-0000-0000-0000-000000000000"