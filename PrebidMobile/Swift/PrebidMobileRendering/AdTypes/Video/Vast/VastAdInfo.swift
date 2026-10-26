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

import Foundation

/// One `MediaFile` of a parsed VAST linear creative.
@objc(PBMVastMediaFileInfo) @objcMembers
public class VastMediaFileInfo: NSObject {
    public let url: String
    public let type: String
    public let width: Int
    public let height: Int
    /// Kbps, or 0 when the file doesn't say.
    public let bitrate: Int
    /// `delivery="streaming"` (e.g. HLS) rather than progressive download.
    public let isStreaming: Bool

    public init(url: String, type: String, width: Int, height: Int, bitrate: Int, isStreaming: Bool) {
        self.url = url
        self.type = type
        self.width = width
        self.height = height
        self.bitrate = bitrate
        self.isStreaming = isStreaming
        super.init()
    }
}

/// A parsed VAST InLine ad, for an app that plays the creative in its own player rather than
/// letting the SDK render it (audio, in-stream video, a custom video card).
///
/// Wrappers are already followed, and their impression, error, click and tracking URLs merged
/// in, so firing what is here covers the whole chain. Produced by `VastAdInfoParser`, usually
/// from `BidInfo.winningBid?.adm`.
@objc(PBMVastAdInfo) @objcMembers
public class VastAdInfo: NSObject {
    public internal(set) var adID: String?
    public internal(set) var title: String?
    public internal(set) var advertiser: String?
    /// Seconds; 0 when the creative doesn't say.
    public internal(set) var duration: TimeInterval = 0
    /// Seconds after which the ad may be skipped, or `nil` when it can't be.
    public internal(set) var skipOffset: NSNumber?
    public internal(set) var mediaFiles: [VastMediaFileInfo] = []
    public internal(set) var clickThroughURL: String?
    public internal(set) var clickTrackingURLs: [String] = []
    public internal(set) var impressionURLs: [String] = []
    public internal(set) var errorURLs: [String] = []
    /// VAST tracking event name (`start`, `firstQuartile`, `midpoint`, `thirdQuartile`,
    /// `complete`, `pause`, …) → URLs.
    public internal(set) var trackingEvents: [String: [String]] = [:]
}

/// Parses VAST markup with the SDK's own VAST parser, following wrappers.
public enum VastAdInfoParser {

    /// Calls `completion` on the main queue with the first InLine ad, or `nil` when the markup
    /// isn't VAST, has no ad, or a wrapper can't be resolved.
    public static func parse(_ vast: String, completion: @escaping (VastAdInfo?) -> Void) {
        guard let data = vast.data(using: .utf8) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        // `VastAdsBuilder` also loads and follows wrappers and merges their trackers into the InLine ad.
        let builder = VastAdsBuilder(connection: PrebidServerConnection.shared)
        builder.buildAds(data) { ads, error in
            if let error {
                Log.error("VAST parsing failed: \(error.localizedDescription)")
            }
            let inlineAd = ads?.lazy.compactMap { $0 as? VastInlineAd }.first
            let info = inlineAd.map(info(from:))
            // `builder` is held until the wrapper chain has been loaded.
            withExtendedLifetime(builder) {
                DispatchQueue.main.async { completion(info) }
            }
        }
    }

    /// `async` form of `parse(_:completion:)`.
    public static func parse(_ vast: String) async -> VastAdInfo? {
        await withCheckedContinuation { continuation in
            parse(vast) { continuation.resume(returning: $0) }
        }
    }

    private static func info(from inlineAd: VastInlineAd) -> VastAdInfo {
        let linear = inlineAd.creatives.lazy.compactMap { $0 as? VastCreativeLinear }.first

        let info = VastAdInfo()
        info.adID = inlineAd.identifier
        info.title = inlineAd.title
        info.advertiser = inlineAd.advertiser
        info.duration = linear?.duration ?? 0
        info.skipOffset = linear?.skipOffset
        info.mediaFiles = (linear?.mediaFiles ?? []).map {
            VastMediaFileInfo(url: $0.mediaURI,
                              type: $0.type,
                              width: $0.width,
                              height: $0.height,
                              bitrate: $0.bitrate?.intValue ?? 0,
                              isStreaming: $0.streamingDeliver)
        }
        info.clickThroughURL = linear?.clickThroughURI
        info.clickTrackingURLs = linear?.clickTrackingURIs ?? []
        info.impressionURLs = inlineAd.impressionURIs
        info.errorURLs = inlineAd.errorURIs
        info.trackingEvents = linear?.vastTrackingEvents.trackingEvents ?? [:]
        return info
    }
}
