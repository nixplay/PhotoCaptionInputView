//
//  PhotoCaptionInputViewController.h
//  Pods
//
//  Created by James Kong on 12/4/2017.
//
//

#import <UIKit/UIKit.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import <MWPhotoBrowser/MWGridCell.h>
@protocol PhotoCaptionInputViewDelegate <NSObject>
-(void) onDismiss;
@end
@interface PhotoCaptionInputViewController : MWPhotoBrowser <MWPhotoBrowserDelegate , UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>

-(id)initWithPhotos:(NSArray*)photos thumbnails:(NSArray*)thumbnails delegate:(id<PhotoCaptionInputViewDelegate>)delegate;
@property (nonatomic) id <PhotoCaptionInputViewDelegate> selfDelegate;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSArray *thumbs;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) MWGridCell *prevSelectItem;
@property (nonatomic, strong) UITextField *textfield;
@property (nonatomic) CGRect keyboardRect;

@end
