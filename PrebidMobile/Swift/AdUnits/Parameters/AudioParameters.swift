/*   Copyright 2018-2019 Prebid.org, Inc.

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

/// Describes an OpenRTB 2.6 audio object (`imp.audio`).
///
/// Pass it to `PrebidRequest(audioParameters:)` and read the winning VAST from
/// `BidInfo.winningBid?.adm`. The SDK requests audio but does not render it: the caller
/// plays the VAST in its own audio player.
@objcMembers
public class AudioParameters: NSObject {

    /// Content MIME types supported, e.g. `"audio/mpeg"`, `"audio/mp4"`.
    /// Prebid Server required property; the SDK sends a default set when empty.
    public var mimes: [String]

    /// Minimum audio ad duration in seconds.
    public var minDuration: SingleContainerInt?

    /// Maximum audio ad duration in seconds.
    public var maxDuration: SingleContainerInt?

    /// Supported audio protocols (VAST versions).
    public var protocols: [Signals.Protocols]?

    /// Start delay in seconds for pre-roll, mid-roll, or post-roll placements.
    public var startDelay: Signals.StartDelay?

    /// Minimum bit rate in Kbps.
    public var minBitrate: SingleContainerInt?

    /// Maximum bit rate in Kbps.
    public var maxBitrate: SingleContainerInt?

    /// Supported API frameworks for this impression.
    public var api: [Signals.Api]?

    /// Blocked creative attributes.
    public var battr: [Signals.CreativeAttribute]?

    /// Type of audio feed: 1 music service, 2 FM/AM broadcast, 3 podcast.
    public var feed: SingleContainerInt?

    /// Whether the ad is stitched with the audio content.
    public var isStitched: Bool?

    // MARK: - Helpers

    public var rawProtocols: [Int]? {
        protocols?.toIntArray()
    }

    public var rawAPI: [Int]? {
        api?.toIntArray()
    }

    public var rawBattrs: [Int]? {
        battr?.removingDuplicates().toIntArray()
    }

    public var rawStitched: NSNumber? {
        guard let isStitched else { return nil }
        return NSNumber(value: isStitched ? 1 : 0)
    }

    /// - Parameter mimes: supported MIME types
    public init(mimes: [String]) {
        self.mimes = mimes
    }
}
