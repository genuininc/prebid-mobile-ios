/*   Copyright 2018-2021 Prebid.org, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import XCTest

@testable import PrebidMobile

class VastAdInfoParserTests: XCTestCase {

    private let inlineVAST = """
    <VAST version="4.0">
      <Ad id="ad-1">
        <InLine>
          <AdSystem>Test</AdSystem>
          <AdTitle><![CDATA[Spot :30]]></AdTitle>
          <Advertiser>example.com</Advertiser>
          <Error><![CDATA[https://t.example.com/error?code=[ERRORCODE]]]></Error>
          <Impression><![CDATA[https://t.example.com/imp1]]></Impression>
          <Impression><![CDATA[https://t.example.com/imp2]]></Impression>
          <Creatives>
            <Creative id="c-1">
              <Linear skipoffset="00:00:05">
                <Duration>00:00:30</Duration>
                <TrackingEvents>
                  <Tracking event="start"><![CDATA[https://t.example.com/start]]></Tracking>
                  <Tracking event="midpoint"><![CDATA[https://t.example.com/mid]]></Tracking>
                  <Tracking event="complete"><![CDATA[https://t.example.com/complete]]></Tracking>
                </TrackingEvents>
                <VideoClicks>
                  <ClickThrough><![CDATA[https://example.com/landing]]></ClickThrough>
                  <ClickTracking><![CDATA[https://t.example.com/click]]></ClickTracking>
                </VideoClicks>
                <MediaFiles>
                  <MediaFile delivery="progressive" type="video/mp4" width="1280" height="720" bitrate="2000">
                    <![CDATA[https://cdn.example.com/ad.mp4]]>
                  </MediaFile>
                </MediaFiles>
              </Linear>
            </Creative>
          </Creatives>
        </InLine>
      </Ad>
    </VAST>
    """

    func testParsesInlineAd() async throws {
        let parsed = await VastAdInfoParser.parse(inlineVAST)
        let info = try XCTUnwrap(parsed)

        XCTAssertEqual(info.adID, "ad-1")
        XCTAssertEqual(info.title, "Spot :30")
        XCTAssertEqual(info.advertiser, "example.com")
        XCTAssertEqual(info.duration, 30)
        XCTAssertEqual(info.skipOffset?.doubleValue, 5)
        XCTAssertEqual(info.clickThroughURL, "https://example.com/landing")
        XCTAssertEqual(info.clickTrackingURLs, ["https://t.example.com/click"])
        XCTAssertEqual(info.impressionURLs, ["https://t.example.com/imp1", "https://t.example.com/imp2"])
        XCTAssertEqual(info.errorURLs, ["https://t.example.com/error?code=[ERRORCODE]"])
        XCTAssertEqual(info.trackingEvents["start"], ["https://t.example.com/start"])
        XCTAssertEqual(info.trackingEvents["midpoint"], ["https://t.example.com/mid"])
        XCTAssertEqual(info.trackingEvents["complete"], ["https://t.example.com/complete"])

        let file = try XCTUnwrap(info.mediaFiles.first)
        XCTAssertEqual(info.mediaFiles.count, 1)
        XCTAssertEqual(file.url, "https://cdn.example.com/ad.mp4")
        XCTAssertEqual(file.type, "video/mp4")
        XCTAssertEqual(file.width, 1280)
        XCTAssertEqual(file.height, 720)
        XCTAssertEqual(file.bitrate, 2000)
        XCTAssertFalse(file.isStreaming)
    }

    func testReturnsNilForNonVAST() async {
        let info = await VastAdInfoParser.parse("<html>not vast</html>")
        XCTAssertNil(info)
    }
}
