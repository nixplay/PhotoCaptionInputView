//
//  MWPhotoExt.h
//  Pods
//
//  Created by James Kong on 20/4/2017.
//
//

#import <MWPhotoBrowser/MWPhotoBrowser.h>

@interface MWPhotoExt : MWPhoto

+ (MWPhotoExt *)photoWithURL:(NSURL *)url;
+ (MWPhotoExt *)photoWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize;

- (id)initWithURL:(NSURL *)url;
- (id)initWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize;

@property (nonatomic, strong) NSString* photoData;
@end
