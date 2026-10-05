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

#import "PBMVastAdsBuilder.h"
#import "PBMVastInlineAd.h"
#import "PBMVastCreativeLinear.h"
#import "PBMVastMediaFile.h"
#import "Log+Extensions.h"

#import "SwiftImport.h"

/// Backs `VastAdInfoParser` (Swift): parses VAST with `PBMVastAdsBuilder`, which also loads and
/// follows wrappers and merges their trackers into the InLine ad, then maps the first InLine ad
/// to a `VastAdInfo`. Created by name from Swift, like the `Factory` types.
@interface PBMVastAdInfoParser_Objc : NSObject <PBMVastAdInfoParsing>

@property (nonatomic, strong, nullable) PBMVastAdsBuilder *builder;

@end

@implementation PBMVastAdInfoParser_Objc

- (void)parse:(NSData *)data completion:(void (^)(PBMVastAdInfo * _Nullable))completion {
    self.builder = [[PBMVastAdsBuilder alloc] initWithConnection:[PrebidServerConnection shared]];
    [self.builder buildAds:data completion:^(NSArray<PBMVastAbstractAd *> *ads, NSError *error) {
        if (error) {
            PBMLogError(@"VAST parsing failed: %@", error.localizedDescription);
        }
        PBMVastInlineAd *inlineAd = nil;
        for (PBMVastAbstractAd *ad in ads) {
            if ([ad isKindOfClass:[PBMVastInlineAd class]]) {
                inlineAd = (PBMVastInlineAd *)ad;
                break;
            }
        }
        completion(inlineAd ? [PBMVastAdInfoParser_Objc infoFromInlineAd:inlineAd] : nil);
    }];
}

+ (PBMVastAdInfo *)infoFromInlineAd:(PBMVastInlineAd *)inlineAd {
    PBMVastCreativeLinear *linear = nil;
    for (PBMVastCreativeAbstract *creative in inlineAd.creatives) {
        if ([creative isKindOfClass:[PBMVastCreativeLinear class]]) {
            linear = (PBMVastCreativeLinear *)creative;
            break;
        }
    }

    NSMutableArray<PBMVastMediaFileInfo *> *mediaFiles = [NSMutableArray array];
    for (PBMVastMediaFile *file in linear.mediaFiles) {
        [mediaFiles addObject:[[PBMVastMediaFileInfo alloc] initWithUrl:file.mediaURI
                                                                   type:file.type
                                                                  width:file.width
                                                                 height:file.height
                                                                bitrate:file.bitrate.integerValue
                                                            isStreaming:file.streamingDeliver]];
    }

    PBMVastAdInfo *info = [PBMVastAdInfo new];
    [info fillWithAdID:inlineAd.identifier
                 title:inlineAd.title
            advertiser:inlineAd.advertiser
              duration:linear.duration
            skipOffset:linear.skipOffset
            mediaFiles:mediaFiles
       clickThroughURL:linear.clickThroughURI
     clickTrackingURLs:linear.clickTrackingURIs ?: @[]
        impressionURLs:inlineAd.impressionURIs
             errorURLs:inlineAd.errorURIs
        trackingEvents:linear.vastTrackingEvents.trackingEvents ?: @{}];
    return info;
}

@end
