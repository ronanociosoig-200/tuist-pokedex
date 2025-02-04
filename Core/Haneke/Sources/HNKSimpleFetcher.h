//
//  HNKSimpleFetcher.h
//  Haneke
//
//  Created by Hermes Pique on 8/19/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
// swiftlint:disable all

#import <Foundation/Foundation.h>
#import <Haneke/HNKCache.h>

/**
 Simple fetcher that represents a key-image pair.
 @discussion Used as a convenience by the UIKit categories.
 */
@interface HNKSimpleFetcher : NSObject<HNKFetcher>

/**
 Initializes a fetcher with the given key and image.
 @param key Image key.
 @param image Image that will be returned by the fetcher.
 */
- (instancetype)initWithKey:(NSString*)key image:(UIImage*)image NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end
