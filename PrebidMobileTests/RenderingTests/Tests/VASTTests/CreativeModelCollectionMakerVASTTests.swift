/*   Copyright 2018-2021 Prebid.org, Inc.
 
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

import Foundation
import XCTest
@_spi(PBMInternal) @testable import PrebidMobile

class CreativeModelCollectionMakerVASTTests: XCTestCase {
    
    var vastServerResponse: PBMAdRequestResponseVAST?
    
    var successfulExpectation: XCTestExpectation?
    
    override func tearDown() {
        successfulExpectation = nil
    }
    
    func testMakeCompanionAd() {
        let adConfiguration = AdConfiguration()
        adConfiguration.adFormats = [.video]
        
        let conn = UtilitiesForTesting.createConnectionForMockedTest()
        let adLoadManager = MockPBMAdLoadManagerVAST(bid: RawWinningBidFabricator.makeWinningBid(price: 0.1, bidder: "bidder", cacheID: "cache-id"), connection:conn, adConfiguration: adConfiguration)
        
        successfulExpectation = expectation(description: "Expected VAST Load to be successful")
        
        adLoadManager.mock_requestCompletedSuccess = { response in
            self.vastServerResponse = response
            self.successfulExpectation?.fulfill()
        }
        
        let requester = PBMAdRequesterVAST(serverConnection:conn, adConfiguration: adConfiguration)
        requester.adLoadManager = adLoadManager
        
        if let data = UtilitiesForTesting.loadFileAsDataFromBundle("VAST_with_companion.xml") {
            requester.buildAdsArray(data)
        }
        
        self.waitForExpectations(timeout: 2)
        
        XCTAssertNotNil(vastServerResponse)
        
        let modelMaker = PBMCreativeModelCollectionMakerVAST(serverConnection:conn, adConfiguration: adConfiguration)
        
        let successCallbackExpectation = expectation(description: "makeModels successCallback called")
        
        modelMaker.makeModels(vastServerResponse!,
                              successCallback: { models in
            successCallbackExpectation.fulfill()
            
            XCTAssertEqual(models.count, 2)
            XCTAssertTrue(models[0].hasCompanionAd)
            XCTAssertFalse(models[0].isCompanionAd)
            XCTAssertFalse(models[1].hasCompanionAd)
            XCTAssertTrue(models[1].isCompanionAd)
        },
                              failureCallback: { error in
            XCTFail(error.localizedDescription)
        })
        
        waitForExpectations(timeout: 3)
    }
    
    // Regression: a CompanionAds creative listed before the Linear one used to crash with
    // -[PBMVastCreativeCompanionAds bestMediaFile]: unrecognized selector.
    func testMakeCompanionAd_companionBeforeLinear() {
        let adConfiguration = AdConfiguration()
        adConfiguration.adFormats = [.video]

        let conn = UtilitiesForTesting.createConnectionForMockedTest()
        let adLoadManager = MockPBMAdLoadManagerVAST(bid: RawWinningBidFabricator.makeWinningBid(price: 0.1, bidder: "bidder", cacheID: "cache-id"), connection:conn, adConfiguration: adConfiguration)

        successfulExpectation = expectation(description: "Expected VAST Load to be successful")

        adLoadManager.mock_requestCompletedSuccess = { response in
            self.vastServerResponse = response
            self.successfulExpectation?.fulfill()
        }

        let requester = PBMAdRequesterVAST(serverConnection:conn, adConfiguration: adConfiguration)
        requester.adLoadManager = adLoadManager

        // Reuse VAST_with_companion.xml, swapping its two <Creative> blocks so CompanionAds comes first.
        guard let data = UtilitiesForTesting.loadFileAsDataFromBundle("VAST_with_companion.xml"),
              let xml = String(data: data, encoding: .utf8),
              let linearStart = xml.range(of: "<Creative id=\"540069340\">"),
              let companionStart = xml.range(of: "<Creative id=\"540069343\">"),
              let creativesEnd = xml.range(of: "</Creatives>") else {
            XCTFail("Could not load VAST_with_companion.xml")
            return
        }
        let head = String(xml[..<linearStart.lowerBound])
        let linearBlock = String(xml[linearStart.lowerBound..<companionStart.lowerBound])
        let companionBlock = String(xml[companionStart.lowerBound..<creativesEnd.lowerBound])
        let tail = String(xml[creativesEnd.lowerBound...])
        let reordered = head + companionBlock + "\n" + linearBlock + tail

        requester.buildAdsArray(Data(reordered.utf8))

        waitForExpectations(timeout: 2)

        XCTAssertNotNil(vastServerResponse)

        let modelMaker = PBMCreativeModelCollectionMakerVAST(serverConnection:conn, adConfiguration: adConfiguration)

        let successCallbackExpectation = expectation(description: "makeModels successCallback called")

        modelMaker.makeModels(vastServerResponse!,
                              successCallback: { models in
            successCallbackExpectation.fulfill()

            XCTAssertEqual(models.count, 2)
            XCTAssertTrue(models[0].hasCompanionAd)
            XCTAssertFalse(models[0].isCompanionAd)
            XCTAssertFalse(models[1].hasCompanionAd)
            XCTAssertTrue(models[1].isCompanionAd)
        },
                              failureCallback: { error in
            XCTFail(error.localizedDescription)
        })

        waitForExpectations(timeout: 3)
    }

    func testMakeCompanionAd_empty() {
        let adConfiguration = AdConfiguration()
        adConfiguration.adFormats = [.video]
        
        let conn = UtilitiesForTesting.createConnectionForMockedTest()
        let adLoadManager = MockPBMAdLoadManagerVAST(bid: RawWinningBidFabricator.makeWinningBid(price: 0.1, bidder: "bidder", cacheID: "cache-id"), connection:conn, adConfiguration: adConfiguration)
        
        successfulExpectation = expectation(description: "Expected VAST Load to be successful")
        
        adLoadManager.mock_requestCompletedSuccess = { response in
            self.vastServerResponse = response
            self.successfulExpectation?.fulfill()
        }
        
        let requester = PBMAdRequesterVAST(serverConnection:conn, adConfiguration: adConfiguration)
        requester.adLoadManager = adLoadManager
        
        if let data = UtilitiesForTesting.loadFileAsDataFromBundle("VAST_with_empty_companion.xml") {
            requester.buildAdsArray(data)
        }
        
        waitForExpectations(timeout: 2)
        
        XCTAssertNotNil(vastServerResponse)
        
        let modelMaker = PBMCreativeModelCollectionMakerVAST(serverConnection:conn, adConfiguration: adConfiguration)
        
        let successCallbackExpectation = expectation(description: "makeModels successCallback called")
        
        modelMaker.makeModels(vastServerResponse!,
                              successCallback: { models in
            XCTAssertEqual(models.count, 1)
            XCTAssertFalse(models.first!.hasCompanionAd)
            XCTAssertFalse(models.first!.isCompanionAd)
            successCallbackExpectation.fulfill()
        },
                              failureCallback: { error in
            XCTFail(error.localizedDescription)
        })
        
        waitForExpectations(timeout: 3)
    }

    // MARK: - AdChoices

    func testAdChoicesIconIsCarriedToTheModel() {
        let models = makeModels(fromVAST: vast(iconProgram: "AdChoices"))
        let adChoices = models.first?.adChoices
        XCTAssertEqual(adChoices?.imageURL, "https://cdn.example.com/adchoices.png")
        XCTAssertEqual(adChoices?.clickThroughURL, "https://example.com/adchoices")
        XCTAssertEqual(adChoices?.clickTrackingURLs, ["https://t.example.com/icon-click"])
        XCTAssertEqual(adChoices?.viewTrackingURL, "https://t.example.com/icon-view")
        XCTAssertEqual(adChoices?.width, 18)
        XCTAssertEqual(adChoices?.height, 15)
    }

    func testIconOfAnotherProgramIsNotAdChoices() {
        let models = makeModels(fromVAST: vast(iconProgram: "BrandLogo"))
        XCTAssertEqual(models.count, 1)
        XCTAssertNil(models.first?.adChoices)
    }

    private func vast(iconProgram: String) -> String {
        """
        <VAST version="4.0"><Ad id="a"><InLine><AdSystem>Test</AdSystem><AdTitle>t</AdTitle>
        <Impression><![CDATA[https://t.example.com/imp]]></Impression>
        <Creatives><Creative><Linear><Duration>00:00:10</Duration>
        <MediaFiles><MediaFile delivery="progressive" type="video/mp4" width="1280" height="720">\
        <![CDATA[https://cdn.example.com/ad.mp4]]></MediaFile></MediaFiles>
        <Icons><Icon program="\(iconProgram)" width="18" height="15" xPosition="right" yPosition="top">
        <StaticResource creativeType="image/png"><![CDATA[https://cdn.example.com/adchoices.png]]></StaticResource>
        <IconClicks><IconClickThrough><![CDATA[https://example.com/adchoices]]></IconClickThrough>
        <IconClickTracking><![CDATA[https://t.example.com/icon-click]]></IconClickTracking></IconClicks>
        <IconViewTracking><![CDATA[https://t.example.com/icon-view]]></IconViewTracking>
        </Icon></Icons></Linear></Creative></Creatives></InLine></Ad></VAST>
        """
    }

    private func makeModels(fromVAST vast: String) -> [CreativeModel] {
        let adConfiguration = AdConfiguration()
        adConfiguration.adFormats = [.video]
        let conn = UtilitiesForTesting.createConnectionForMockedTest()
        let adLoadManager = MockPBMAdLoadManagerVAST(
            bid: RawWinningBidFabricator.makeWinningBid(price: 0.1, bidder: "bidder", cacheID: "cache-id"),
            connection: conn,
            adConfiguration: adConfiguration
        )
        let loaded = expectation(description: "VAST loaded")
        var response: PBMAdRequestResponseVAST?
        adLoadManager.mock_requestCompletedSuccess = {
            response = $0
            loaded.fulfill()
        }
        let requester = PBMAdRequesterVAST(serverConnection: conn, adConfiguration: adConfiguration)
        requester.adLoadManager = adLoadManager
        requester.buildAdsArray(Data(vast.utf8))
        wait(for: [loaded], timeout: 2)

        guard let response else { return [] }
        var models: [CreativeModel] = []
        let made = expectation(description: "models made")
        PBMCreativeModelCollectionMakerVAST(serverConnection: conn, adConfiguration: adConfiguration)
            .makeModels(response, successCallback: {
                models = $0
                made.fulfill()
            }, failureCallback: {
                XCTFail($0.localizedDescription)
                made.fulfill()
            })
        wait(for: [made], timeout: 3)
        return models
    }
}
