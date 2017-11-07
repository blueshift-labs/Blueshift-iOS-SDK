//
//  BlueShiftCarousalViewController.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//


#import "BlueShiftCarousalViewController.h"

@interface BlueShiftCarousalViewController ()

@property (strong, nonatomic) NSMutableArray *items;
@property NSMutableArray *deepLinkURLs;

@end

@implementation BlueShiftCarousalViewController

@synthesize carousel;
@synthesize items;
@synthesize pageControl;
@synthesize deepLinkURLs;

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

- (BOOL)isBlueShiftCarouselPushNotification:(UNNotification *)notification {
    if ([notification.request.content.categoryIdentifier isEqualToString: @"carousel"] || [notification.request.content.categoryIdentifier isEqualToString: @"carousel_animation"]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isBlueShiftCarouselActions:(UNNotificationResponse *)response {
    if(response.actionIdentifier && ([response.actionIdentifier isEqualToString:@"next"] || [response.actionIdentifier isEqualToString:@"previous"] || [response.actionIdentifier isEqualToString:@"go_to_app"])) {
        return YES;
    } else {
        return NO;
    }
}

- (void)createAndConfigCarousel {
    // Initialize and configure the carousel
    carousel = [[iCarousel alloc] initWithFrame:CGRectMake(30, 10, self.view.frame.size.width - 60, self.view.frame.size.height - 40)];
    carousel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    carousel.type = iCarouselTypeCylinder;
    carousel.delegate = self;
    carousel.dataSource = self;
    carousel.autoscroll = -0.1;
    [self.view addSubview:carousel];
}


- (void)createPageIndicator:(NSUInteger)numberOfPages {
    // Init Page Control
    UIPageControl *pc = [[UIPageControl alloc] init];
    pageControl = pc;
    pageControl.frame = CGRectMake(0, self.view.frame.size.height - 30, self.view.frame.size.width, 30);
    pageControl.numberOfPages = numberOfPages;
    pageControl.currentPage = 0;
    pageControl.pageIndicatorTintColor = [UIColor whiteColor];
    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    [self.view addSubview:pageControl];
}


- (void)dealloc {
    //it's a good idea to set these to nil here to avoid
    //sending messages to a deallocated viewcontroller
    carousel.delegate = nil;
    carousel.dataSource = nil;
    
}



- (void)viewDidUnload {
    [super viewDidUnload];
    self.carousel = nil;
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(__unused UIInterfaceOrientation)interfaceOrientation {
    return YES;
}



- (NSInteger)numberOfItemsInCarousel:(__unused iCarousel *)carousel {
    return (NSInteger)[self.items count];
}



- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    //create new view if no view is available for recycling
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(30, 10, self.view.frame.size.width - 60, self.view.frame.size.height - 40)];
    imageView.image = [items objectAtIndex:index];
    view = imageView;
    view.layer.cornerRadius = 12.0;
    view.layer.masksToBounds = YES;
    return view;
}



- (void)showCarouselForNotfication:(UNNotification *)notification {
    [self getImages:notification];
    [self createPageIndicator:self.items.count];
    [self setCarouselTheme:[notification.request.content.userInfo  objectForKey:@"carousel_theme"]];
    if([notification.request.content.categoryIdentifier isEqualToString:@"carousel"]) {
        self.carousel.autoscroll = 0;
    } else if([notification.request.content.categoryIdentifier isEqualToString:@"carousel_animation"]) {
        self.carousel.autoscroll = -0.1;
    }
    if(self.items.count == 1) {
        self.carousel.autoscroll = 0;
    }
    [self.carousel reloadData];
}


- (void)setCarouselTheme:(NSString *)themeNmae {
    self.carousel.type = [self fetchCarouselThemeEnum:themeNmae];
}


- (void)getImages:(UNNotification *)notification {
    NSArray <UNNotificationAttachment *> *attachments = notification.request.content.attachments;
    [self fetchAttachmentsToImageArray:attachments];
    NSArray *carouselImages = [notification.request.content.userInfo objectForKey:@"carousel_elements"];
    [self fetchDeepLinkURLs:carouselImages];
    if(self.items.count < carouselImages.count) {
        NSMutableArray *images = [[NSMutableArray alloc]init];
        images = [self.items mutableCopy];
        NSMutableArray *attachmentIDs = [[NSMutableArray alloc]init];
        for(UNNotificationAttachment *attachment in attachments) {
            [attachmentIDs addObject:attachment.identifier];
        }
        [carouselImages enumerateObjectsUsingBlock:
         ^(NSDictionary *image, NSUInteger index, BOOL *stop) {
             if(attachmentIDs.count < index + 1 || ![[attachmentIDs objectAtIndex:index] isEqualToString:[NSString stringWithFormat:@"image_%lu.jpg", (unsigned long)index]]) {
                 NSURL *imageURL = [NSURL URLWithString:[image objectForKey:@"image_url"]];
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
    for(UNNotificationAttachment *attachment in attachments) {
        if (attachment.URL.startAccessingSecurityScopedResource) {
            UIImage *image = [UIImage imageWithContentsOfFile:attachment.URL.path];
            if(image != nil) {
                [itemsArray addObject:image];
            }
        }
    }
    self.items = itemsArray;
}

- (void)setCarouselActionsForResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption))completion {
    if([response.actionIdentifier isEqualToString:@"next"]) {
        [carousel scrollToItemAtIndex:carousel.currentItemIndex + 1 animated:YES];
        completion(UNNotificationContentExtensionResponseOptionDoNotDismiss);
    } else if([response.actionIdentifier isEqualToString:@"previous"]) {
        [carousel scrollToItemAtIndex:carousel.currentItemIndex - 1 animated:YES];
        completion(UNNotificationContentExtensionResponseOptionDoNotDismiss);
    } else {
        completion(UNNotificationContentExtensionResponseOptionDismissAndForwardAction);
    }
}


- (CATransform3D)carousel:(__unused iCarousel *)carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform {
    //implement 'flip3D' style carousel
    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * self.carousel.itemWidth);
}



- (CGFloat)carousel:(__unused iCarousel *)icarousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value {
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


- (void)carouselCurrentItemIndexDidChange:(iCarousel *)icarousel {
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
        return iCarouselTypeCylinder;
    }
}

@end
