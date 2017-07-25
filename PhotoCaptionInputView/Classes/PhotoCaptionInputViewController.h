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
#import <IQKeyboardManager/IQTextView.h>
#import <IQKeyboardManager/IQUITextFieldView+Additions.h>
#import <IQKeyboardManager/IQUIView+IQKeyboardToolbar.h>
@protocol PhotoCaptionInputViewDelegate;

@interface PhotoCaptionInputViewController : MWPhotoBrowser <MWPhotoBrowserDelegate , UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextViewDelegate>

-(id)initWithPhotos:(NSArray*)photos thumbnails:(NSArray*)thumbnails  preselectedAssets:(NSArray*) _preselectedAssets delegate:(id <PhotoCaptionInputViewDelegate>)delegate;

@property (nonatomic) id <PhotoCaptionInputViewDelegate> selfDelegate;
@property (nonatomic, strong) NSMutableArray *selfPhotos;
@property (nonatomic, strong) NSMutableArray *selfThumbs;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) MWGridCell *prevSelectItem;
@property (nonatomic, strong) IQTextView *textView;
@property (nonatomic) CGRect keyboardRect;
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) UIBarButtonItem *trashButton;
-(void) getPhotosCaptions;
@end


@protocol PhotoCaptionInputViewDelegate <NSObject>

@optional
-(void) dismissPhotoCaptionInputView:(PhotoCaptionInputViewController*)controller;
-(void) photoCaptionInputView:(PhotoCaptionInputViewController*)controller captions:(NSArray *)captions photos:(NSArray*)photos preSelectedAssets:(NSArray*)preSelectedAssets;
@optional
- (NSString *)photoCaptionInputView:(PhotoCaptionInputViewController *)controller titleForPhotoAtIndex:(NSUInteger)index;
- (NSMutableArray*)photoBrowser:(MWPhotoBrowser *)photoBrowser buildToolbarItems:(UIToolbar*)toolBar;
@end
