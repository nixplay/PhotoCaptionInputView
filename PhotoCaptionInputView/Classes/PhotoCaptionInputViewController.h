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
@end
@interface PhotoCaptionInputViewController : UIViewController <MWPhotoBrowserDelegate , UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>

-(id)initWithPhotos:(NSArray*)photos thumbnails:(NSArray*)thumbnails;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSArray *thumbs;
@property (nonatomic, strong) MWPhotoBrowser *browser;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) MWGridCell *prevSelectItem;
@property (nonatomic, strong) UITextField *textfield;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic) CGRect keyboardRect;

@end
