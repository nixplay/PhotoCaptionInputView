//
//  MWZoomingScrollViewExt.h
//  Pods
//
//  Created by James Kong on 18/8/2017.
//
//

#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import "MWZoomingScrollView.h"
@class MWZoomingScrollViewExt;
@protocol MWZoomingScrollViewDelegate<NSObject>
-(void) zoomingScrollView:(MWZoomingScrollViewExt*) zoomingScrollViewExt photo:(id<MWPhoto>)photo startTime:(CGFloat)startTime endTime:(CGFloat) endTime;
@end
@interface MWZoomingScrollViewExt : MWZoomingScrollView
@property (strong, nonatomic) id<MWZoomingScrollViewDelegate> mDelegate;

@property (assign, nonatomic) CGFloat startTime;
@property (assign, nonatomic) CGFloat endTime;
@property (strong, nonatomic) NSString *description;

- (void) setStartTime:(CGFloat)startTime endTime:(CGFloat)endTime;
- (void) resetTrimmerSubview;
- (void) onVideoTapped;
@end
