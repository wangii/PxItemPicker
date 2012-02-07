#import "PxItemPickerController.h"
#import <QuartzCore/QuartzCore.h>

#define TAG_BASE 999

static CGSize kDefaultItemViewSize = {60, 60};
static UIEdgeInsets kDefaultPaddingInsets = {20, 20, 20, 20};
static CGSize kDefaultGapSize = {10, 10};

static CGFloat kUnselectedOpacity = 0.5;

typedef UIView*(^ItemViewCreationBlock)(NSInteger idx);

@interface PxItemPickerController()

-(void)layoutItems;
-(void)cancel:(id)sender;
-(void)done:(id)sender;
-(void)hilightSelection;

@property(readonly)UIImageView* cachedOverlay;

@end

@implementation PxItemPickerController

@synthesize delegate;
@synthesize dataSource;
@synthesize scrollView;

+ (PxItemPickerController*)pickerController;
{
	return [[[self alloc] init] autorelease];
}

-(id)init;
{
	self = [super initWithNibName:nil bundle:nil];
	
    if (self) {
		selectedIdx = -1;
        lastSelectedIdx = -1;
        cachedOverlay = nil;
	}
    
	return self;
}

-(UIView*)cachedOverlay;
{
    if (!cachedOverlay) {
        if ([self.delegate respondsToSelector:@selector(selectedOverlayViewOfItemPicker:)]) {
            cachedOverlay = [self.delegate selectedOverlayViewOfItemPicker:self];
        }else{
            cachedOverlay = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bluedot.png"]] autorelease];
        }
        
        [scrollView addSubview:cachedOverlay];
    }
    
    return cachedOverlay;
}

-(void)loadView;
{
	[super loadView];

	scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
	[self.view addSubview:scrollView];
    
	[scrollView release];
    scrollView.userInteractionEnabled = YES;
    scrollView.backgroundColor = [UIColor whiteColor];
	UITapGestureRecognizer* tap = [[[UITapGestureRecognizer alloc] initWithTarget:self
																		   action:@selector(tap:)] autorelease];
	[scrollView addGestureRecognizer:tap];
}

-(void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    UIBarButtonItem* done = 
    [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                   target:self 
                                                   action:@selector(done:) ] autorelease];
    
    UIBarButtonItem* cancel = 
    [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                   target:self 
                                                   action:@selector(cancel:) ] autorelease];
    
	self.navigationItem.leftBarButtonItem = cancel;
    self.navigationItem.rightBarButtonItem = done;
    
    self.navigationController.navigationBar.hidden = NO;
}

-(void)viewDidAppear:(BOOL)animated;
{
    [super viewDidAppear:animated];
    
    scrollView.frame = self.view.frame;
	[self layoutItems];

}

-(void)viewWillDisappear:(BOOL)animated;
{
    self.navigationController.navigationBar.hidden = YES;
    [super viewWillDisappear:animated];
}

- (void)layoutItems
{
	CGSize itemSize = kDefaultItemViewSize;
	if ([self.dataSource respondsToSelector:@selector(sizeOfItemViewForItemPicker:)]){
		itemSize = [self.delegate sizeOfItemViewForItemPicker:self];
	}

	UIEdgeInsets inset = kDefaultPaddingInsets;
	if ([self.delegate respondsToSelector:@selector(paddingOfItemPicker:)]) {
		inset = [self.delegate paddingsOfItemPicker:self];
	}

	CGSize gap = kDefaultGapSize;
	if ([self.delegate respondsToSelector:@selector(gapSizeOfItemPicker:)]) {
		gap = [self.delegate gapSizeOfItemPicker:self];
	}

	BOOL useImageView = ![self.dataSource respondsToSelector:@selector(itemPicker:renderView:)];
	NSInteger total = [self.dataSource numberOfItemsInItemPicker:self];

	// number of rows, cols;
	NSInteger cols = (NSInteger)floorf(
			((self.view.frame.size.width - inset.left - inset.right) + gap.width) / (itemSize.width + gap.width)
		);
	NSInteger rows = (NSInteger)ceilf(total/cols);
    
	CGFloat hpadding = (self.view.frame.size.width - cols * itemSize.width - (cols - 1) * gap.width ) / 2;

	ItemViewCreationBlock block = ^UIView*(NSInteger idx){
        
		// compute location;
		NSInteger idxRow = (NSInteger)floorf(idx / cols) ;
		NSInteger idxCol = idx - idxRow * cols;
		
		CGFloat y = inset.top + idxRow * gap.height + idxRow * itemSize.height;
		CGFloat x = hpadding + idxCol*gap.width + idxCol * itemSize.width;
        
		// create the view;
		if(useImageView){
			return [[[UIImageView alloc] initWithFrame:CGRectMake(x, y, itemSize.width, itemSize.height)] autorelease];
		}else{
			return [[[UIView alloc] initWithFrame:CGRectMake(x, y, itemSize.width, itemSize.height)] autorelease];
		}
	};

    CGFloat lasty = 0;
	for(NSInteger idx = 0; idx < total; idx++)
	{
		UIView* v = block(idx);
        lasty = v.frame.origin.y + v.frame.size.height;
        
		v.tag = TAG_BASE + idx;
		[self.scrollView addSubview:v];

		if(useImageView)
		{
			UIImageView* x = (UIImageView*)v;
            x.contentMode = UIViewContentModeScaleAspectFit;
            
			x.image = [self.dataSource itemPicker:self imageAtIndex:idx];
            x.layer.opacity = kUnselectedOpacity;
		}else{
			[self.dataSource itemPicker:self renderView:v];
		}
	}

//	CGFloat h = inset.top + inset.bottom + rows * itemSize.height + (rows - 1) * gap.height;
	
	self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, lasty + inset.bottom);
    
    [self hilightSelection];
}

- (void)tap:(UIGestureRecognizer*)gr;
{
    
	CGPoint p = [gr locationInView:scrollView];
    
	UIView *hitView = nil;
    
    for (UIView* x in scrollView.subviews) {
        if (CGRectContainsPoint(x.frame, p)) {
            hitView = x;
            break;
        }
    }
    
    if (hitView == cachedOverlay || hitView == scrollView) {
        return;
    }

	if (hitView) {

		NSInteger idx = hitView.tag - TAG_BASE;

		if ([self.delegate respondsToSelector:@selector(itemPicker:willSelect:)]) {
			idx = [self.delegate itemPicker:self willSelect:idx];
		}
		
        lastSelectedIdx = selectedIdx;
        selectedIdx = idx;
        [self hilightSelection];
	}
}

-(void)hilightSelection;
{
    if (selectedIdx < 0) {
        return;
    }
    
    UIView* target = [scrollView viewWithTag:selectedIdx + TAG_BASE];
    if (target) 
    {
        UIView* v = [self cachedOverlay];
        CGFloat x = target.frame.origin.x;
        CGFloat y = target.frame.origin.y + (target.frame.size.height - v.frame.size.height);
        
        v.frame = CGRectMake(x, y, v.frame.size.width, v.frame.size.height);
        
        target.layer.opacity = 1;
        
        UIView* z = [scrollView viewWithTag:lastSelectedIdx + TAG_BASE];
        
        if (z) {
            z.layer.opacity = kUnselectedOpacity;
        }
    }
}

- (void)reload
{
    for (UIView* v in scrollView.subviews) {
        [v removeFromSuperview];
    }
    
	[self layoutItems];
}

-(void)presentModallyOverViewController:(UIViewController*)parent;
{
	UINavigationController* nav = [[[UINavigationController alloc] initWithRootViewController:self] autorelease];

	[parent presentModalViewController: nav animated: YES];
}

-(void)cancel:(id)sender;
{
    [self.delegate itemPicker:self didCancel:YES];
}

-(void)done:(id)sender;
{
    if (selectedIdx > -1) {
        [self.delegate itemPicker:self didFinishWithSelection:selectedIdx];
    }else{
        [self.delegate itemPicker:self didCancel:YES];
    }
}

@end
