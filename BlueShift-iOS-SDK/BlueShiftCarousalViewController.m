//
//  BlueShiftCarousalViewController.m
//  BlueShift-iOS-SDK
//
//  Created by Shahas on 22/09/16.
//  Copyright © 2016 Bullfinch Software. All rights reserved.
//

#import "BlueShiftCarousalViewController.h"

@interface BlueShiftCarousalViewController ()

@property (strong, nonatomic) NSMutableArray *items;

@end

@implementation BlueShiftCarousalViewController

@synthesize carousel;
@synthesize items;
@synthesize pageControl;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //[self createImageView];
    
    [self createAndConfigCarousel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)createAndConfigCarousel {
    // Initialize and configure the carousel
    carousel = [[iCarousel alloc] initWithFrame:CGRectMake(30, 20, self.view.frame.size.width - 60, self.view.frame.size.height - 60)];
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
    pageControl.currentPageIndicatorTintColor = [UIColor blueColor];
    [self.view addSubview:pageControl];
}


- (void)dealloc
{
    //it's a good idea to set these to nil here to avoid
    //sending messages to a deallocated viewcontroller
    carousel.delegate = nil;
    carousel.dataSource = nil;
    
}

#pragma mark -
#pragma mark View lifecycle



- (void)viewDidUnload
{
    [super viewDidUnload];
    self.carousel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(__unused UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


#pragma mark -
#pragma mark iCarousel methods

- (NSInteger)numberOfItemsInCarousel:(__unused iCarousel *)carousel
{
    return (NSInteger)[self.items count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    //create new view if no view is available for recycling
    if (view == nil)
    {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(30, 20, self.view.frame.size.width - 60, self.view.frame.size.height - 60)];
        imageView.image = [items objectAtIndex:index];
        view = imageView;
        view.layer.cornerRadius = 10.0;
        view.layer.masksToBounds = YES;
    }
    
    return view;
}

- (void)showCarouselForNotfication:(UNNotification *)notification {
    [self getImages:notification];
    [self createPageIndicator:self.items.count];
    [self.carousel reloadData];
}

- (void)getImages:(UNNotification *)notification {
    NSArray *attachments = notification.request.content.attachments;
    [self fetchAttachmentsToImageArray:attachments];
}

- (void)fetchAttachmentsToImageArray:(NSArray *)attachments {
    NSMutableArray *itemsArray = [[NSMutableArray alloc]init];
    for(UNNotificationAttachment *attachment in attachments) {
        if (attachment.URL.startAccessingSecurityScopedResource) {
            UIImage *image = [UIImage imageWithContentsOfFile:attachment.URL.path];
            [itemsArray addObject:image];
        }
    }
    self.items = itemsArray;
}

- (CATransform3D)carousel:(__unused iCarousel *)carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
{
    //implement 'flip3D' style carousel
    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * self.carousel.itemWidth);
}

- (CGFloat)carousel:(__unused iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
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
            return value * 1.3f;
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

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel {
    pageControl.currentPage = carousel.currentItemIndex;
}

@end
