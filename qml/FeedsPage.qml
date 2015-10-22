/*
 * Copyright (C) 2015 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0
import QtQuick.Controls 1.0
import LunaNext.Common 0.1
import LuneOS.Service 1.0

BasePage {
    title: "Preware Feeds"
    forwardButtonSourceComponent: forwardButton

    LunaService {
        id: service
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
    }

    Component.onCompleted: {
        service.call("luna://org.webosinternals.ipkgservice/getConfigs", JSON.stringify({}), getFeedsSuccess,
                           getFeedsFailure)
    }

    function getFeedsSuccess(message) {

        var response = JSON.parse(message.payload)
        feedModel.clear()

        if (response.configs && response.configs.length > 0) {
            for (var n = 0; n < response.configs.length; n++) {
                var config = response.configs[n]
                var configTmp = config.contents.split(' ')

                feedModel.append({
                                       configConfig: config.config,
                                       configName: configTmp[1],
                                       configEnabled: config.enabled,
                                       configURL: configTmp[2]
                                   })
            }
        }
    }

    function getFeedsFailure(message) {
        console.log("Unable to get Preware feeds")
    }

    ListModel {
        id: feedModel
    }


    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)


        Text {
            id: label1
            anchors.left: parent.left
            anchors.right: parent.right
            wrapMode: Text.Wrap
            text: "Select Preware feeds to enable"
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("medium")
        }

        ListView {
            id: feedList
            anchors.left: parent.left
            anchors.right: parent.right
            height: column.height - column.spacing

            clip: true

            model: feedModel

            delegate: Rectangle {
                id: delegate
                anchors.right: parent.right
                anchors.left: parent.left
                height: Units.gu(7)
                color: "transparent"

                Text {
                    id: config
                    anchors.top: parent.top
                    color: "white"
                    font.pixelSize: FontUtils.sizeToPixels("large")
                    text: configConfig.substring(0, configConfig.length-5)
                    font.bold: true
                }
                Text {
                    id: configContents
                    anchors.top: config.bottom
                    color: "white"
                    font.pixelSize: FontUtils.sizeToPixels("medium")
                    text: configURL
                }

                Image {
                    id: feedEnabledToggleOff
                    anchors.verticalCenter: delegate.verticalCenter
                    source: "images/toggle-button-off.png"
                    anchors.right: parent.right
                    anchors.rightMargin: Units.gu(1)
                    height: Units.gu(4)
                    width: Units.gu(8)

                    visible: !configEnabled
                    MouseArea {
                        anchors.fill: parent
                        onPressed: {
                            setFeedStatus (configConfig, !configEnabled)
                            feedEnabledToggleOn.visible = true
                            feedEnabledToggleOff.visible = false
                        }
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: Units.gu(1)
                        anchors.verticalCenter: parent.verticalCenter
                        color: "white"
                        text: "OFF"
                        font.bold: true
                        font.family: "Prelude"
                        font.pixelSize: FontUtils.sizeToPixels("small")
                    }
                }
                Image {
                    id: feedEnabledToggleOn
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Units.gu(1)
                    anchors.right: parent.right
                    source: "images/toggle-button-on.png"
                    height: Units.gu(4)
                    width: Units.gu(8)
                    visible: configEnabled
                    MouseArea {
                        anchors.fill: parent
                        onPressed: {
                            setFeedStatus (configConfig, !configEnabled)
                            feedEnabledToggleOn.visible = false
                            feedEnabledToggleOff.visible = true
                        }
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: Units.gu(1.5)
                        anchors.verticalCenter: parent.verticalCenter
                        color: "white"
                        text: "ON"
                        font.bold: true
                        font.family: "Prelude"
                        font.pixelSize: FontUtils.sizeToPixels("small")
                    }
                }

                function setFeedStatus (config, enabled)
                {
                    var params =
                    {
                        config: config,
                        enabled: enabled
                    }

                    service.call("luna://org.webosinternals.ipkgservice/setConfigState", JSON.stringify(params), setConfigSuccess,
                                       setConfigFailure)
                }

                function setConfigSuccess(message)
                {
                    var response = JSON.parse(message.payload)
                    console.log("Successfully set feed config")
                }

                function setConfigFailure(message)
                {
                    var response = JSON.parse(message.payload)
                    console.log("Failed to set feed config: "+response.errorText)
                }

            }
        }

        Item { // spacer
            height: Units.gu(2)
            width: Units.gu(1) // needed else it will be ignored
        }
    }

    Component {
        id: forwardButton
        StackButton {
            text: "Continue"
            onClicked: {
                pageStack.next();
            }
        }
    }
}
