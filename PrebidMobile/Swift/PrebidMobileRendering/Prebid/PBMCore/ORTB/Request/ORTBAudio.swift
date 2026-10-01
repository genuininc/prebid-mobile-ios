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

/// OpenRTB 2.6 `imp.audio` object (section 3.2.8).
@objc(PBMORTBAudio)
public class ORTBAudio: NSObject, PBMJsonCodable {

    // MARK: - Properties

    /// Content MIME types supported, e.g. `audio/mpeg`. Required by OpenRTB.
    @objc public var mimes: [String]?
    @objc public var minduration: NSNumber?
    @objc public var maxduration: NSNumber?
    @objc public var protocols: [NSNumber]?
    @objc public var startdelay: NSNumber?
    @objc public var minbitrate: NSNumber?
    @objc public var maxbitrate: NSNumber?
    @objc public var delivery: [NSNumber]?
    @objc public var api: [NSNumber]?
    @objc public var battr: [NSNumber]?
    /// Type of audio feed: 1 music service, 2 FM/AM broadcast, 3 podcast.
    @objc public var feed: NSNumber?
    /// 1 when the ad is stitched with the audio content, 0 otherwise.
    @objc public var stitched: NSNumber?
    /// Volume normalization mode.
    @objc public var nvol: NSNumber?

    // MARK: - Init

    public override init() {
        super.init()
    }

    @objc(initWithJsonDictionary:)
    public required init(jsonDictionary: [String: Any]) {
        super.init()
        let json = JSONObject<Key>(jsonDictionary)
        mimes       = json[.mimes]
        minduration = json[.minduration]
        maxduration = json[.maxduration]
        protocols   = json[.protocols]
        startdelay  = json[.startdelay]
        minbitrate  = json[.minbitrate]
        maxbitrate  = json[.maxbitrate]
        delivery    = json[.delivery]
        api         = json[.api]
        battr       = json[.battr]
        feed        = json[.feed]
        stitched    = json[.stitched]
        nvol        = json[.nvol]
    }

    // MARK: - PBMJsonEncodable

    @objc(toJsonDictionary)
    public var jsonDictionary: [String: Any] {
        var json = JSONObject<Key>()
        json[.mimes]       = mimes
        json[.minduration] = minduration
        json[.maxduration] = maxduration
        json[.protocols]   = protocols
        json[.startdelay]  = startdelay
        json[.minbitrate]  = minbitrate
        json[.maxbitrate]  = maxbitrate
        json[.delivery]    = delivery
        json[.feed]        = feed
        json[.stitched]    = stitched
        json[.nvol]        = nvol
        if let api = api, !api.isEmpty {
            json[.api] = api
        }
        if let battr = battr, !battr.isEmpty {
            json[.battr] = battr
        }
        return json.dict
    }

    // MARK: - Keys

    private enum Key: String {
        case mimes, minduration, maxduration, protocols, startdelay
        case minbitrate, maxbitrate, delivery, api, battr
        case feed, stitched, nvol
    }
}
