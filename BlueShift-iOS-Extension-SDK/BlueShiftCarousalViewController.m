//
//  BlueShiftCarousalViewController.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//


#import "BlueShiftCarousalViewController.h"
#import "UIColor+BlueShiftHexString.h"
#import "BlueshiftExtensionConstants.h"

#define kPaddingLeft            0
#define kpaddingRight           0
#define kPaddingTop             0
#define kPaddingBottom          0

#define kTextPaddingLeft        10
#define kTextPaddingRight       10
#define kTextPaddingTop         0
#define kTextPaddingBottom      10

#define kPageIndicatorHeight    30

#define kImageCornerRadius      0.0
#define kSlideDuration          3.0f

@interface BlueShiftCarousalViewController ()

@property (strong, nonatomic) NSMutableArray *items;
@property NSMutableArray *deepLinkURLs;
@property NSArray *carouselElements;
@property NSTimer *carouselTimer;
@property BOOL isAnimatedCarousel;

@end

@implementation BlueShiftCarousalViewController

@synthesize carousel;
@synthesize items;
@synthesize pageControl;
@synthesize deepLinkURLs;
@synthesize carouselElements;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    [self setBackgroundColor];
}

- (void)setBackgroundColor {
    self.view.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self createAndConfigCarousel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)isBlueShiftCarouselPushNotification:(UNNotification *)notification  API_AVAILABLE(ios(10.0)){
    if ([notification.request.content.categoryIdentifier isEqualToString: kNotificationCarouselIdentifier] || [notification.request.content.categoryIdentifier isEqualToString: kNotificationCarouselAnimationIdentifier]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isBlueShiftCarouselActions:(UNNotificationResponse *)response  API_AVAILABLE(ios(10.0)){
    if(response.actionIdentifier && ([response.actionIdentifier isEqualToString:kNotificationCarouselNextIdentifier] || [response.actionIdentifier isEqualToString:kNotificationCarouselPreviousIdentifier] || [response.actionIdentifier isEqualToString:kNotificationCarouselGotoappIdentifier])) {
        return YES;
    } else {
        return NO;
    }
}

- (void)createAndConfigCarousel {
    // Initialize and configure the carousel
    carousel = [[BlueShiftiCarousel alloc] initWithFrame:CGRectMake(kPaddingLeft, kPaddingTop, self.view.frame.size.width - (kPaddingLeft + kpaddingRight), self.view.frame.size.height - (kPaddingTop + kPaddingBottom))];
    carousel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    carousel.type = iCarouselTypeLinear;
    carousel.delegate = self;
    carousel.dataSource = self;
    carousel.autoscroll = -0.1;
    [self.view addSubview:carousel];
}


- (void)createPageIndicator:(NSUInteger)numberOfPages {
    // Init Page Control
    UIPageControl *pc = [[UIPageControl alloc] init];
    pageControl = pc;
    pageControl.frame = CGRectMake(0, self.view.frame.size.height - kPageIndicatorHeight, self.view.frame.size.width, kPageIndicatorHeight);
    pageControl.numberOfPages = numberOfPages;
    pageControl.currentPage = 0;
    pageControl.pageIndicatorTintColor = [UIColor whiteColor];
    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    [self.view addSubview:pageControl];
}

- (void)createContentViewOnTopOf:(UIView *)view withTitle:(NSDictionary *)title andSubTitle:(NSDictionary *)subTitle withPosition:(NSString *)position {
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 260)];
    contentView.backgroundColor = [UIColor clearColor];
    CGRect titleFrame = CGRectMake(kTextPaddingLeft, kTextPaddingTop , self.view.frame.size.width - (kTextPaddingLeft + kTextPaddingRight), 30);
    UILabel *titleLabel =  [self createTitle:title withFrame:titleFrame onView:contentView];
    CGRect subTitleFrame = CGRectMake(kTextPaddingLeft, kTextPaddingTop + titleLabel.frame.size.height + 5, self.view.frame.size.width - (kTextPaddingLeft + kTextPaddingRight), 30);
    UILabel *subTitleLabel = [self createSubTitle:subTitle withFrame:subTitleFrame onView:contentView];
    CGRect newFrame = contentView.frame;
    newFrame.size.height = titleLabel.frame.size.height + subTitleLabel.frame.size.height + 10;
    contentView.frame = newFrame;
    [self contentView:contentView onTopOfTheView:view withTitle:titleLabel andSubTitle:subTitleLabel withPosition:position];
    [view addSubview: contentView];
}

- (UILabel *)createTitle:(NSDictionary *)titleDictionary withFrame:(CGRect)frame onView:(UIView *)view {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:frame];
    [self setLabel:titleLabel withData:titleDictionary];
    if(titleLabel.font.pointSize == 0)
        [titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:18]];
    else
        [titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:titleLabel.font.pointSize]];
    CGRect newFrame = titleLabel.frame;
    newFrame.size.height = [self getLabelHeight:titleLabel];
    titleLabel.frame = newFrame;
    [view addSubview:titleLabel];
    return titleLabel;
}


- (UILabel *)createSubTitle:(NSDictionary *)subTitleDictionary withFrame:(CGRect)frame onView:(UIView *)view {
    UILabel *subTitleLabel = [[UILabel alloc] initWithFrame:frame];
    [self setLabel:subTitleLabel withData:subTitleDictionary];
    if(subTitleLabel.font.pointSize == 0)
        [subTitleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:14]];
    else
        [subTitleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:subTitleLabel.font.pointSize]];
    CGRect newFrame = subTitleLabel.frame;
    newFrame.size.height = [self getLabelHeight:subTitleLabel];
    subTitleLabel.frame = newFrame;
    [view addSubview:subTitleLabel];
    return subTitleLabel;
}

- (void)setLabel:(UILabel *)label withData:(NSDictionary *)data {
    NSString *text = [data objectForKey:@"text"];
    NSString *hexColor = [data objectForKey:@"text_color"];
    NSString *hexBackgroundColor = [data objectForKey:@"text_background_color"];
    NSString *fontSizeString = [data objectForKey:@"text_size"];
    UIColor *textColor = hexColor != nil ? [UIColor colorWithHexString:hexColor] : [UIColor whiteColor];
    UIColor *textBackgroundColor = hexBackgroundColor != nil ? [UIColor colorWithHexString:hexBackgroundColor] : [UIColor clearColor];
    CGFloat fontSize = (CGFloat)[fontSizeString floatValue];
    if (text) {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
        
        [attributedString addAttribute:NSBackgroundColorAttributeName
                                 value:textBackgroundColor
                                 range:NSMakeRange(0, attributedString.length)];
        label.attributedText = attributedString;
        [label setTextColor:textColor];
        [label setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:fontSize]];
        [label setNumberOfLines:0];
    }
}

- (void)leftAlignTitle:(UILabel *)title andSubTitle:(UILabel *)subTitle {
    [title setTextAlignment:NSTextAlignmentLeft];
    [subTitle setTextAlignment:NSTextAlignmentLeft];
}

- (void)centerAlignTitle:(UILabel *)title andSubTitle:(UILabel *)subTitle {
    [title setTextAlignment:NSTextAlignmentCenter];
    [subTitle setTextAlignment:NSTextAlignmentCenter];
}

- (void)rightAlignTitle:(UILabel *)title andSubTitle:(UILabel *)subTitle {
    [title setTextAlignment:NSTextAlignmentRight];
    [subTitle setTextAlignment:NSTextAlignmentRight];
}

- (CGPoint)alignContentViewVerticallyTop:(UIView *)contentView onTopOfTheView:(UIView *)view {
    return CGPointMake(0, 15);
}

- (CGPoint)alignContentViewVerticallyMiddle:(UIView *)contentView onTopOfTheView:(UIView *)view {
    return CGPointMake(0, (view.frame.size.height-contentView.frame.size.height)/2);
}

- (CGPoint)alignContentViewVerticallyBottom:(UIView *)contentView onTopOfTheView:(UIView *)view {
    return CGPointMake(0, (view.frame.size.height-contentView.frame.size.height)-15);
}

- (void) positionContentView:(UIView *)contentView topOfTheView:(UIView *)view andLeftAlignTitle:(UILabel*)titleLabel andSubTitle:(UILabel *)subTitleLabel {
    CGRect newFrame = contentView.frame;
    [self leftAlignTitle:titleLabel andSubTitle:subTitleLabel];
    CGPoint newPoint = [self alignContentViewVerticallyTop:contentView onTopOfTheView:view];
    newFrame.origin = newPoint;
    contentView.frame = newFrame;
}

- (void) positionContentView:(UIView *)contentView topOfTheView:(UIView *)view andCenterAlignTitle:(UILabel*)titleLabel andSubTitle:(UILabel *)subTitleLabel {
    CGRect newFrame = contentView.frame;
    [self centerAlignTitle:titleLabel andSubTitle:subTitleLabel];
    CGPoint newPoint = [self alignContentViewVerticallyTop:contentView onTopOfTheView:view];
    newFrame.origin = newPoint;
    contentView.frame = newFrame;
}

- (void) positionContentView:(UIView *)contentView topOfTheView:(UIView *)view andRightAlignTitle:(UILabel*)titleLabel andSubTitle:(UILabel *)subTitleLabel {
    CGRect newFrame = contentView.frame;
    [self rightAlignTitle:titleLabel andSubTitle:subTitleLabel];
    CGPoint newPoint = [self alignContentViewVerticallyTop:contentView onTopOfTheView:view];
    newFrame.origin = newPoint;
    contentView.frame = newFrame;
}

- (void) positionContentView:(UIView *)contentView middleOfTheView:(UIView *)view andLeftAlignTitle:(UILabel*)titleLabel andSubTitle:(UILabel *)subTitleLabel {
    CGRect newFrame = contentView.frame;
    [self leftAlignTitle:titleLabel andSubTitle:subTitleLabel];
    CGPoint newPoint = [self alignContentViewVerticallyMiddle:contentView onTopOfTheView:view];
    newFrame.origin = newPoint;
    contentView.frame = newFrame;
}

- (void) positionContentView:(UIView *)contentView middleOfTheView:(UIView *)view andCenterAlignTitle:(UILabel*)titleLabel andSubTitle:(UILabel *)subTitleLabel {
    CGRect newFrame = contentView.frame;
    [self centerAlignTitle:titleLabel andSubTitle:subTitleLabel];
    CGPoint newPoint = [self alignContentViewVerticallyMiddle:contentView onTopOfTheView:view];
    newFrame.origin = newPoint;
    contentView.frame = newFrame;
}

- (void) positionContentView:(UIView *)contentView middleOfTheView:(UIView *)view andRightAlignTitle:(UILabel*)titleLabel andSubTitle:(UILabel *)subTitleLabel {
    CGRect newFrame = contentView.frame;
    [self rightAlignTitle:titleLabel andSubTitle:subTitleLabel];
    CGPoint newPoint = [self alignContentViewVerticallyMiddle:contentView onTopOfTheView:view];
    newFrame.origin = newPoint;
    contentView.frame = newFrame;
}

- (void) positionContentView:(UIView *)contentView bottomOfTheView:(UIView *)view andLeftAlignTitle:(UILabel*)titleLabel andSubTitle:(UILabel *)subTitleLabel {
    CGRect newFrame = contentView.frame;
    [self leftAlignTitle:titleLabel andSubTitle:subTitleLabel];
    CGPoint newPoint = [self alignContentViewVerticallyBottom:contentView onTopOfTheView:view];
    newFrame.origin = newPoint;
    contentView.frame = newFrame;
}

- (void) positionContentView:(UIView *)contentView bottomOfTheView:(UIView *)view andCenterAlignTitle:(UILabel*)titleLabel andSubTitle:(UILabel *)subTitleLabel {
    CGRect newFrame = contentView.frame;
    [self centerAlignTitle:titleLabel andSubTitle:subTitleLabel];
    CGPoint newPoint = [self alignContentViewVerticallyBottom:contentView onTopOfTheView:view];
    newFrame.origin = newPoint;
    contentView.frame = newFrame;
}

- (void) positionContentView:(UIView *)contentView bottomOfTheView:(UIView *)view andRightAlignTitle:(UILabel*)titleLabel andSubTitle:(UILabel *)subTitleLabel {
    CGRect newFrame = contentView.frame;
    [self rightAlignTitle:titleLabel andSubTitle:subTitleLabel];
    CGPoint newPoint = [self alignContentViewVerticallyBottom:contentView onTopOfTheView:view];
    newFrame.origin = newPoint;
    contentView.frame = newFrame;
}

- (void) contentView:(UIView *)contentView onTopOfTheView:(UIView *)view withTitle:(UILabel *)title andSubTitle:(UILabel *)subTitle withPosition:(NSString *)position {
    if([position isEqualToString:@"top_left"]) {
        [self positionContentView:contentView topOfTheView:view andLeftAlignTitle:title andSubTitle:subTitle];
    } else if([position isEqualToString:@"top_center"]) {
        [self positionContentView:contentView topOfTheView:view andCenterAlignTitle:title andSubTitle:subTitle];
    } else if([position isEqualToString:@"top_right"]) {
        [self positionContentView:contentView topOfTheView:view andRightAlignTitle:title andSubTitle:subTitle];
    } else if([position isEqualToString:@"middle_left"]) {
        [self positionContentView:contentView middleOfTheView:view andLeftAlignTitle:title andSubTitle:subTitle];
    } else if([position isEqualToString:@"middle_center"]) {
        [self positionContentView:contentView middleOfTheView:view andCenterAlignTitle:title andSubTitle:subTitle];
    } else if([position isEqualToString:@"middle_right"]) {
        [self positionContentView:contentView middleOfTheView:view andRightAlignTitle:title andSubTitle:subTitle];
    } else if([position isEqualToString:@"bottom_left"]) {
        [self positionContentView:contentView bottomOfTheView:view andLeftAlignTitle:title andSubTitle:subTitle];
    } else if([position isEqualToString:@"bottom_center"]) {
        [self positionContentView:contentView bottomOfTheView:view andCenterAlignTitle:title andSubTitle:subTitle];
    } else if([position isEqualToString:@"bottom_right"]) {
        [self positionContentView:contentView bottomOfTheView:view andRightAlignTitle:title andSubTitle:subTitle];
    } else {
        [self positionContentView:contentView middleOfTheView:view andCenterAlignTitle:title andSubTitle:subTitle];
    }
}

- (CGFloat)getLabelHeight:(UILabel*)label {
    CGSize constraint = CGSizeMake(label.frame.size.width, CGFLOAT_MAX);
    CGSize size;
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    CGSize boundingBox = [label.text boundingRectWithSize:constraint
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{NSFontAttributeName:label.font}
                                                  context:context].size;
    
    size = CGSizeMake(ceil(boundingBox.width), ceil(boundingBox.height));
    return size.height;
}

- (void)dealloc {
    //it's a good idea to set these to nil here to avoid
    //sending messages to a deallocated viewcontroller
    carousel.delegate = nil;
    carousel.dataSource = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopCarouselTimer];
    self.carousel = nil;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSInteger)numberOfItemsInCarousel:(__unused BlueShiftiCarousel *)carousel {
    return (NSInteger)[self.items count];
}

- (UIViewContentMode)setImageContentMode: (NSString *)mode {
    if([mode  isEqual: @"ScaleToFill"]) {
        return UIViewContentModeScaleToFill;
    } else if([mode  isEqual: @"AspectFill"]) {
        return UIViewContentModeScaleAspectFill;
    } else if([mode  isEqual: @"AspectFit"]) {
        return UIViewContentModeScaleAspectFit;
    } else {
        return UIViewContentModeScaleAspectFill;
    }
}


- (UIView *)carousel:(BlueShiftiCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    //create new view if no view is available for recycling
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(kPaddingLeft, kPaddingTop, self.view.frame.size.width - (kPaddingLeft + kpaddingRight), self.view.frame.size.height - (kPaddingTop + kPaddingBottom))];
    NSDictionary *carouselElement = [self.carouselElements objectAtIndex:index];
    imageView.image = [items objectAtIndex:index];
    imageView.contentMode = [self setImageContentMode:[carouselElement objectForKey:@"image_mode"]];
    view = imageView;
    view.layer.cornerRadius = kImageCornerRadius;
    view.layer.masksToBounds = YES;
    NSDictionary *titleDictionary = [carouselElement objectForKey:@"content_text"];
    NSDictionary *subTitleDictionary = [carouselElement objectForKey:@"content_subtext"];
    NSString *position = [carouselElement objectForKey:@"content_layout_type"];
    [self createContentViewOnTopOf:view withTitle:titleDictionary andSubTitle:subTitleDictionary withPosition:position];
    return view;
}



- (void)showCarouselForNotfication:(UNNotification *)notification  API_AVAILABLE(ios(10.0)){
    [self getImages:notification];
    [self createPageIndicator:self.items.count];
    [self setCarouselTheme:[notification.request.content.userInfo  objectForKey:@"carousel_theme"]];
    carousel.autoscroll = 0;
    carousel.currentItemIndex = -1;
    if([notification.request.content.categoryIdentifier isEqualToString:@"carousel_animation"]) {
        _isAnimatedCarousel = YES;
        [self startCarouselTimer];
    }
    [self.carousel reloadData];
}

-(void)showNextImage {
    [carousel scrollToItemAtIndex:carousel.currentItemIndex + 1 animated:YES];
}

-(void)startCarouselTimer {
    if(_carouselTimer == nil && self.items.count > 1) {
        _carouselTimer = [NSTimer scheduledTimerWithTimeInterval:kSlideDuration target:self selector:@selector(showNextImage) userInfo:nil repeats:YES];
    }
}

-(void)stopCarouselTimer {
    if (_carouselTimer) {
        [_carouselTimer invalidate];
        _carouselTimer = nil;
    }
}

-(void)restartTimer {
    if (_isAnimatedCarousel == YES) {
        [self stopCarouselTimer];
        [self startCarouselTimer];
    }
}

- (void)setCarouselTheme:(NSString *)themeNmae {
    self.carousel.type = [self fetchCarouselThemeEnum:themeNmae];
}


- (void)getImages:(UNNotification *)notification  API_AVAILABLE(ios(10.0)){
    NSArray <UNNotificationAttachment *> *attachments = notification.request.content.attachments;
    [self fetchAttachmentsToImageArray:attachments];
    self.carouselElements = [notification.request.content.userInfo objectForKey:@"carousel_elements"];
    [self fetchDeepLinkURLs:self.carouselElements];
    if(self.items.count < self.carouselElements.count) {
        NSMutableArray *images = [self.items mutableCopy];
        NSMutableArray *attachmentIDs = [[NSMutableArray alloc]init];
        for(UNNotificationAttachment *attachment in attachments) {
            [attachmentIDs addObject:attachment.identifier];
        }
        [self.carouselElements enumerateObjectsUsingBlock:
         ^(NSDictionary *image, NSUInteger index, BOOL *stop) {
             if(attachmentIDs.count < index + 1 || ![[attachmentIDs objectAtIndex:index] isEqualToString:[NSString stringWithFormat:@"image_%lu.jpg", (unsigned long)index]]) {
                 NSURL *imageURL = [NSURL URLWithString:[image objectForKey:kNotificationMediaImageURL]];
                 NSData *imageData = nil;
                 if(imageURL != nil && imageURL.absoluteString.length != 0) {
                     imageData = [[NSData alloc] initWithContentsOfURL: imageURL];
                     UIImage *image = [UIImage imageWithData:imageData];
                     [images insertObject:image atIndex:index];
                     [attachmentIDs insertObject:[NSString stringWithFormat:@"image_%lu.jpg", (unsigned long)index] atIndex:index];
                 }
             }
         }];
        self.items = images;
    }
}

- (void)fetchDeepLinkURLs:(NSArray *)carouselImages {
    self.deepLinkURLs = (NSMutableArray *)carouselImages;
}


- (void)fetchAttachmentsToImageArray:(NSArray *)attachments {
    NSMutableArray *itemsArray = [[NSMutableArray alloc]init];
    if (@available(iOS 10.0, *)) {
        for(UNNotificationAttachment *attachment in attachments) {
            if (attachment.URL.startAccessingSecurityScopedResource) {
                UIImage *image = [UIImage imageWithContentsOfFile:attachment.URL.path];
                if(image != nil) {
                    [itemsArray addObject:image];
                }
            }
        }
    } else {
        // Fallback on earlier versions
    }
    self.items = itemsArray;
}

- (void)setCarouselActionsForResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption))completion API_AVAILABLE(ios(10.0)){
    if([response.actionIdentifier isEqualToString:@"next"]) {
        [carousel scrollToItemAtIndex:carousel.currentItemIndex + 1 animated:YES];
        [self restartTimer];
        completion(UNNotificationContentExtensionResponseOptionDoNotDismiss);
    } else if([response.actionIdentifier isEqualToString:@"previous"]) {
        [carousel scrollToItemAtIndex:carousel.currentItemIndex - 1 animated:YES];
        [self restartTimer];
        completion(UNNotificationContentExtensionResponseOptionDoNotDismiss);
    } else {
        completion(UNNotificationContentExtensionResponseOptionDismissAndForwardAction);
    }
}


- (CATransform3D)carousel:(__unused BlueShiftiCarousel *)carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform {
    //implement 'flip3D' style carousel
    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * self.carousel.itemWidth);
}



- (CGFloat)carousel:(__unused BlueShiftiCarousel *)icarousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value {
    //customize carousel display
    switch (option)
    {
        case iCarouselOptionWrap:
        {
            //normally you would hard-code this to YES or NO
            return YES;
        }
        case iCarouselOptionSpacing:
        {
            //add a bit of spacing between the item views
            if(icarousel.type == iCarouselTypeLinear) {
                return value * 1.1f;
            } else {
                return value * 1.2f;
            }
        }
        case iCarouselOptionFadeMax:
        {
            if (self.carousel.type == iCarouselTypeCustom)
            {
                //set opacity based on distance from camera
                return 0.0f;
            }
            return value;
        }
        case iCarouselOptionShowBackfaces:
        case iCarouselOptionRadius:
        case iCarouselOptionAngle:
        case iCarouselOptionArc:
        case iCarouselOptionTilt:
        case iCarouselOptionCount:
        case iCarouselOptionFadeMin:
        case iCarouselOptionFadeMinAlpha:
        case iCarouselOptionFadeRange:
        case iCarouselOptionOffsetMultiplier:
        case iCarouselOptionVisibleItems:
        {
            return value;
        }
    }
}


- (void)carouselCurrentItemIndexDidChange:(BlueShiftiCarousel *)icarousel {
    pageControl.currentPage = icarousel.currentItemIndex;
    
    NSUserDefaults *myDefaults = [[NSUserDefaults alloc]
                                  initWithSuiteName:self.appGroupID];
    NSNumber *index = [NSNumber numberWithInteger:icarousel.currentItemIndex];
    [myDefaults setObject:index forKey:@"selected_index"];
    [myDefaults synchronize];
}

- (iCarouselType)fetchCarouselThemeEnum:(NSString *)themeName {
    if([themeName isEqualToString:@"linear"]) {
        return iCarouselTypeLinear;
    } else if([themeName isEqualToString:@"rotatory"]) {
        return iCarouselTypeRotary;
    } else if([themeName isEqualToString:@"inverted_rotatory"]) {
        return iCarouselTypeInvertedRotary;
    } else if([themeName isEqualToString:@"cylinder"]) {
        return iCarouselTypeCylinder;
    } else if([themeName isEqualToString:@"inverted_cylinder"]) {
        return iCarouselTypeInvertedCylinder;
    } else if([themeName isEqualToString:@"wheel"]) {
        return iCarouselTypeWheel;
    } else if([themeName isEqualToString:@"inverted_wheel"]) {
        return iCarouselTypeInvertedWheel;
    } else if([themeName isEqualToString:@"cover_flow_1"]) {
        return iCarouselTypeCoverFlow;
    } else if([themeName isEqualToString:@"cover_flow_2"]) {
        return iCarouselTypeCoverFlow2;
    } else if([themeName isEqualToString:@"time_machine"]) {
        return iCarouselTypeTimeMachine;
    } else if([themeName isEqualToString:@"inverted_time_machine"]) {
        return iCarouselTypeInvertedTimeMachine;
    } else {
        return iCarouselTypeLinear;
    }
}

@end
