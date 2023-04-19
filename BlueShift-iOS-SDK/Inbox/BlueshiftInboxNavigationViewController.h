//
//  BlueshiftInboxNavigationViewController.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 15/11/22.
//

#import <UIKit/UIKit.h>
#import "BlueshiftInboxViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftInboxNavigationViewController : UINavigationController

/// If you dont want to use the SDK provided default cell layout, then you can create your own custom layout inside a xib and provide the nib name here.
/// Setting this value is optional if you want to use the SDK provided default cell layout.
/// This option allows you to use only one custom cell in the inbox, and that custom cell will be used as default cell by the SDK.
/// The custom cell nib must be present in the main bundle.
@property (nonatomic, assign) IBInspectable NSString* _Nullable customCellNibName;

/// This value needs to be only set from the Storyboard or Xib to get the `BlueshiftInboxViewControllerDelegate` callbacks.
/// Create a class which implements the protocol `BlueshiftInboxViewControllerDelegate`, implement the required methods.
/// The name must be set in format - `module_name.classs_name` from the storyboard.
/// @warning Set this value only if you are configuring the inbox using the storyboard or xib. Skip setting this property if you are preseting inbox from the code.
@property (nonatomic, assign) IBInspectable NSString* _Nullable inboxDelegateName;

/// Set this property to change the unread badge color displayed on the inbox message cell.
/// The default color is Cyan.
@property (nonatomic, assign) IBInspectable UIColor* _Nullable unreadBadgeColor;

/// Set this property to change the color for the pull down to refresh control.
/// The default color is Cyan.
@property (nonatomic, assign) IBInspectable UIColor* _Nullable refreshControlColor;

/// Set this property to true or false if you want to show/hide the activity indicator while displaying the in-app notification.
/// The in-app notification might take time to display as it needs to download the resources like images or html pages.
/// The inbox will show activity indicatory till the time it is downloading the resources, once its ready it will hide the activity indicator and present the in-app notification.
/// The default value is True.
@property (nonatomic) IBInspectable  BOOL showActivityIndicator;

/// Set this property to true or false if you want to show/hide the activity indicator while displaying the in-app notification.
/// The in-app notification might take time to display as it needs to download the resources like images or html pages.
/// The inbox will show activity indicatory till the time it is downloading the resources, once its ready it will hide the activity indicator and present the in-app notification.
/// The default value is True.
@property (nonatomic) IBInspectable  UIColor* activityIndicatorColor;

/// Set this property to true to enable the large title.
/// Default value is False.
@property (nonatomic, assign) IBInspectable BOOL enableLargeTitle;

/// Set this property to true if you want to enable the sections.
/// By default the groupSections are disabled.
@property (nonatomic) IBInspectable  BOOL groupSections;

/// Set this property to true in case you want to show `Done` button on the navigation bar in order to dismiss the inbox.
/// Default value is True.
@property (nonatomic) IBInspectable  BOOL showDoneButton;

/// Set `BlueshiftInboxViewControllerDelegate` delegate
@property (nonatomic) id<BlueshiftInboxViewControllerDelegate> _Nullable inboxDelegate;

@end

NS_ASSUME_NONNULL_END
