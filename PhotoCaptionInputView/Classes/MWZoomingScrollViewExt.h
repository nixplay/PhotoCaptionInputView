//
//  MWZoomingScrollViewExt.h
//  Pods
//
//  Created by James Kong on 18/8/2017.
//
//

#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import "MWZoomingScrollView.h"
@interface MWZoomingScrollViewExt : MWZoomingScrollView
@property (assign, nonatomic) CGFloat startTime;
@property (assign, nonatomic) CGFloat stopTime;
- (void) resetTrimmerSubview;
- (void) onVideoTapped;
@end
