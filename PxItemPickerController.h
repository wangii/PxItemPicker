#import <UIKit/UIKit.h>

@class PxItemPickerController;

@protocol PxItemPickerControllerDataSource <NSObject>

-(NSInteger)numberOfItemsInItemPicker:(PxItemPickerController*)picker;

-(UIImage*)itemPicker:(PxItemPickerController*)picker imageAtIndex:(NSInteger)idx;

@optional

// if not provided, an UIImageView is used;
-(void)itemPicker:(PxItemPickerController*)picker renderView:(UIView*)view;

@end

@protocol PxItemPickerControllerDelegate <NSObject>

-(void)itemPicker:(PxItemPickerController*)picker didFinishWithSelection:(NSInteger)idx;
-(void)itemPicker:(PxItemPickerController*)picker didCancel:(BOOL)flag;

@optional
// default: 36x36
-(CGSize)sizeOfItemViewForItemPicker:(PxItemPickerController*)picker;

// default 10x10 
-(CGSize)gapSizeOfItemPicker:(PxItemPickerController*)picker;

// default 20 for each side;
-(UIEdgeInsets)paddingsOfItemPicker:(PxItemPickerController*)picker;

// default a dot at the center bottom of the itemView;
-(UIView*)selectedOverlayViewOfItemPicker:(PxItemPickerController*)picker;

// return -1 of should not be selected;
-(NSInteger)itemPicker:(PxItemPickerController*)picker willSelect:(NSInteger)idx;

@end

@interface PxItemPickerController : UIViewController
{
	UIScrollView* scrollView;
    NSInteger lastSelectedIdx;
    NSInteger selectedIdx;
    UIView* cachedOverlay;
}

@property (nonatomic, assign) id<PxItemPickerControllerDelegate> delegate;
@property (nonatomic, assign) id<PxItemPickerControllerDataSource> dataSource;
@property (readonly) UIScrollView* scrollView;

+(PxItemPickerController*)pickerController;

-(void)presentModallyOverViewController:(UIViewController*)parent;

-(void)reload;

@end
