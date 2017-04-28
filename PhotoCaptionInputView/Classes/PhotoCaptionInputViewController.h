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
@protocol PhotoCaptionInputViewDelegate;

@interface PhotoCaptionInputViewController : MWPhotoBrowser <MWPhotoBrowserDelegate , UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>

-(id)initWithPhotos:(NSArray*)photos thumbnails:(NSArray*)thumbnails  preselectedAssets:(NSArray*) _preselectedAssets delegate:(id <PhotoCaptionInputViewDelegate>)delegate;

@property (nonatomic) id <PhotoCaptionInputViewDelegate> selfDelegate;
@property (nonatomic, strong) NSMutableArray *selfPhotos;
@property (nonatomic, strong) NSMutableArray *selfThumbs;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) MWGridCell *prevSelectItem;
@property (nonatomic, strong) UITextField *textfield;
@property (nonatomic) CGRect keyboardRect;
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) UIBarButtonItem *trashButton;

@end


@protocol PhotoCaptionInputViewDelegate <NSObject>
-(void) dismissPhotoCaptionInputView:(PhotoCaptionInputViewController*)controller;
-(void) photoCaptionInputView:(PhotoCaptionInputViewController*)controller captions:(NSArray *)captions photos:(NSArray*)photos;
- (NSString *)photoCaptionInputView:(PhotoCaptionInputViewController *)controller titleForPhotoAtIndex:(NSUInteger)index;
@end
