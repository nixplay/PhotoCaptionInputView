//
//  MWPhotoExt.m
//  Pods
//
//  Created by James Kong on 20/4/2017.
//
//

#import "MWPhotoExt.h"

@implementation MWPhotoExt
@synthesize photoData = _photoData;
@synthesize startEndTime = _startEndTime;
+ (MWPhotoExt *)photoWithURL:(NSURL *)url {
    return [[MWPhotoExt alloc] initWithURL:url];
}

+ (MWPhotoExt *)photoWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize {
    return [[MWPhotoExt alloc] initWithAsset:asset targetSize:targetSize];
}


- (id)initWithURL:(NSURL *)url{
    self = [super initWithURL:url];
    _photoData = [url absoluteString];
    return self;
}
- (id)initWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize{
    self = [super initWithAsset:asset targetSize:targetSize];
    _photoData = [asset localIdentifier];
    return self;
}

- (void) startEndTime:(NSDictionary *) startEndTime{
    _startEndTime = startEndTime;
}


- (NSDictionary*) startEndTime{
    return _startEndTime;
}

@end
