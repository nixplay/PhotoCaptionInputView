//
//  NixViewController.m
//  PhotoCaptionInputView
//
//  Created by James Kong on 04/12/2017.
//  Copyright (c) 2017 James Kong. All rights reserved.
//

#import "NixViewController.h"
#import "PhotoCaptionInputViewController.h"
#import "MWPhotoExt.h"
@interface NixViewController (){
    PHFetchResult<PHAsset*> * fetchResult;
}
@end

@implementation NixViewController
    
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //    [self presentViewController:vc animated:NO completion:^{
    //
    //    }];
    // Do any additional setup after loading the view, typically from a nib.
    
}
    
-(void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}
    
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    NSMutableArray *thumbs = [[NSMutableArray alloc] init];
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if(status == PHAuthorizationStatusAuthorized){
            fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:nil];
            
            uint32_t randomAssetIndex = (uint32_t)arc4random_uniform((uint32_t)(fetchResult.count - 1));
            
            PHAsset * asset = [fetchResult objectAtIndex:randomAssetIndex];
            UIScreen *screen = [UIScreen mainScreen];
            CGFloat scale = screen.scale;
            // Sizing is very rough... more thought required in a real implementation
            CGFloat imageSize = MAX(screen.bounds.size.width, screen.bounds.size.height) * 1.5;
            CGSize imageTargetSize = CGSizeMake(imageSize * scale, imageSize * scale);
            CGSize thumbTargetSize = CGSizeMake(imageSize / 3.0 * scale, imageSize / 3.0 * scale);
            
            [photos addObject:[MWPhotoExt photoWithAsset:asset targetSize:imageTargetSize]];
            [thumbs addObject:[MWPhotoExt photoWithAsset:asset targetSize:thumbTargetSize]];
            dispatch_async(dispatch_get_main_queue(), ^{
                PhotoCaptionInputViewController *vc = [[PhotoCaptionInputViewController alloc] initWithPhotos:photos thumbnails:thumbs preselectedAssets:nil delegate:self];
                UINavigationController *nc = [[UINavigationController alloc]initWithRootViewController:vc];
                vc.allow_video = YES;
                [self presentViewController:nc animated:YES completion:^{
                    
                }];
            });
        }
    }];
    
    
}
    
    
- (void)didReceiveMemoryWarning
    {
        NSLog(@"didReceiveMemoryWarning");
        [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
    }
    
#pragma mark - PhotoCaptionInputViewDelegate
- (NSMutableArray*)photoBrowser:(MWPhotoBrowser *)photoBrowser buildToolbarItems:(UIToolbar*)toolBar{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    [items addObject:flexSpace];
    
    float margin = 1.0f;
    
    
    
    
    [toolBar setBackgroundImage:[UIImage new]
             forToolbarPosition:UIToolbarPositionAny
                     barMetrics:UIBarMetricsDefault];
    
    [toolBar setBackgroundColor:[UIColor clearColor]];
    
    for (UIView *subView in [toolBar subviews]) {
        if ([subView isKindOfClass:[UIImageView class]]) {
            // Hide the hairline border
            subView.hidden = YES;
        }
    }
    
    UIButton *button =  [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat buttonWidth = self.view.frame.size.height > self.view.frame.size.width ? self.view.frame.size.width : self.view.frame.size.height;
    CGRect newFrame = CGRectMake(0,0,
                                 (buttonWidth *.45)-5,
                                 toolBar.frame.size.height - margin*2 );
    if(@available(iOS 11, *)){
        newFrame = CGRectMake(0,0,
                              (buttonWidth *.45)-5,
                              toolBar.frame.size.height - margin*2 );
    }
    [button setFrame:newFrame];
    [button setBackgroundColor:[UIColor grayColor]];
    button.layer.cornerRadius = 2; // this value vary as per your desire
    button.clipsToBounds = YES;
    [button setAttributedTitle:[self attributedString:@"Button 1" WithSize:12 color:[UIColor whiteColor]] forState:UIControlStateNormal];
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    UIBarButtonItem *addFriendsButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    [items addObject:addFriendsButton];
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    if(@available(iOS 11, *)){
        fixedSpace.width = 1;
    }else{
        fixedSpace.width = -8 ;
    }
    [items addObject:fixedSpace];
    
    
    button = [[UIButton alloc] initWithFrame: newFrame];
    [button setBackgroundColor:[UIColor grayColor]];
    button.layer.cornerRadius = 2; // this value vary as per your desire
    button.clipsToBounds = YES;
    //                [button setTitle:labelText forState:UIControlStateNormal];
    [button setAttributedTitle:[self attributedString:@"Button 2" WithSize:12 color:[UIColor whiteColor]] forState:UIControlStateNormal];
    
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    UIBarButtonItem *addPhotoButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    [items addObject:addPhotoButton];
    
    
    
    
    
    [items addObject:flexSpace];
    toolBar.barStyle = UIBarStyleDefault;
    
    toolBar.barTintColor = [UIColor whiteColor];;
    return items;
}
-(void) onDismiss{
    [self dismissViewControllerAnimated:NO completion:nil];
}
-(void)dismissPhotoCaptionInputView:(PhotoCaptionInputViewController *)controller{
    [controller dismissViewControllerAnimated:YES completion:nil];
}
-(void) photoCaptionInputViewCaptions:(NSArray *)captions photos:(NSArray *)photos{
    [captions enumerateObjectsUsingBlock:^(NSArray* obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"%@",obj);
        
    }];
    
    
    [photos enumerateObjectsUsingBlock:^(NSArray* obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"%@",obj);
        
    }];
}
    
-(NSAttributedString *) attributedString:(NSString*)string WithSize:(NSInteger)size color:(UIColor*)color{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]init];
    
    NSDictionary *dictAttr0 = [self attributedDirectoryWithSize:size color:color];
    NSAttributedString *attr0 = [[NSAttributedString alloc]initWithString:string attributes:dictAttr0];
    [attributedString appendAttributedString:attr0];
    return attributedString;
}
    
-(NSDictionary *) attributedDirectoryWithSize:(NSInteger)size color:(UIColor*)color{
    NSDictionary *dictAttr0 = @{NSFontAttributeName:[UIFont systemFontOfSize:size],
                                NSForegroundColorAttributeName:color};
    return dictAttr0;
}
@end
