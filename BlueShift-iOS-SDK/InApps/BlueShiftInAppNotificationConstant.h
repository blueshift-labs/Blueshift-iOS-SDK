//
//  BlueShiftInAppNotificationConstant.h
//  Pods
//
//  Created by Noufal Subair on 31/07/19.
//

#ifndef BlueShiftInAppNotificationConstant_h
#define BlueShiftInAppNotificationConstant_h

/* InApp Notification Modal */
#define kInAppNotificationDataKey                               @"data"
#define kInAppNotificationKey                                   @"inapp"
#define kInAppNotificationActionButtonKey                       @"actions"
#define kInAppNotificationModalContentKey                       @"content"
#define kInAppNotificationModalHTMLKey                          @"html"
#define kInAppNotificationModalURLKey                           @"url"
#define kInAppNotificationModalTitleKey                         @"title"
#define kInAppNotificationModalSubTitleKey                      @"sub_title"
#define kInAppNotificationModalMessageKey                       @"message"
#define kInAppNotificationModalIconKey                          @"icon"
#define kInAppNotificationModalBannerKey                        @"banner"
#define kInAppNotificationModalImageFileNameKey                 @"file_name"
#define kInAppNotificationModalSecondaryIconKey                 @"secondary_icon"
#define kInAppNotificationModalIconImageKey                     @"icon_image"

#define kInAppNotificationModalContentStyleKey                  @"content_style"
#define kInAppNotificationModalContentStyleDarkKey              @"content_style_dark"
#define kInAppNotificationModalTitleColorKey                    @"title_color"
#define kInAppNotificationModalTitleBackgroundColorKey          @"title_background_color"
#define kInAppNotificationModalTitleGravityKey                  @"title_gravity"
#define kInAppNotificationModalTitleSizeKey                     @"title_size"
#define kInAppNotificationModalMessageColorKey                  @"message_color"
#define kInAppNotificationModalMessageAlignKey                  @"message_align"
#define kInAppNotificationModalMessageBackgroundColorKey        @"message_background_color"
#define kInAppNotificationModalMessageGravityKey                @"message_gravity"
#define kInAppNotificationModalMessageSizeKey                   @"message_size"
#define kInAppNotificationModalIconSizeKey                      @"icon_size"
#define kInAppNotificationModalIconColorKey                     @"icon_color"
#define kInAppNotificationModalIconBackgroundColorKey           @"icon_background_color"
#define kInAppNotificationModalIconBackgroundRadiusKey          @"icon_background_radius"
#define kInAppNotificationModalActionsOrientationKey            @"actions_orientation"
#define kInAppNotificationModalSecondaryIconSizeKey             @"secondary_icon_size"
#define kInAppNotificationModalSecondaryIconColorKey            @"secondary_icon_color"
#define kInAppNotificationModalSecondaryIconBackgroundColorKey  @"secondary_icon_background_color"
#define kInAppNotificationModalSecondaryIconRadiusKey           @"secondary_icon_background_color"
#define kInAppNotificationModalIconImageBackgroundColorKey      @"icon_image_background_color"
#define kInAppNotificationModalIconImageBackgroundRadiusKey     @"icon_image_background_radius"

#define kInAppNotificationModalTemplateStyleKey                 @"template_style"
#define kInAppNotificationModalTemplateStyleDarkKey             @"template_style_dark"
#define kInAppNotificationModalPositionKey                      @"position"
#define kInAppNotificationModalWidthKey                         @"width"
#define kInAppNotificationModalHeightKey                        @"height"
#define kInAppNotificationModalBackgroundColorKey               @"background_color"
#define kInAppNotificationModalBackgroundImageKey               @"background_image"
#define kInAppNotificationModalEnableCloseButtonKey             @"show"
#define kInAppNotificationModalBackgroundActionKey              @"enable_background_action"
#define kInAppNotificationModalCloseButtonKey                   @"close_button"
#define kInAppNotificationModalBackgroundDimAmountKey           @"background_dim_amount"
#define kInAppNotificationModalBottomSafeAreaColorKey           @"bottom_safearea_color"

#define kInAppNotificationModalTextKey                          @"text"
#define kInAppNotiificationModalTextColorKey                    @"text_color"
#define kInAppNotificationModalPageKey                          @"ios_link"
#define kInAppNotificationModalSharableTextKey                  @"shareable_text"
#define kInAppNotificationModalBackgroundRadiusKey              @"background_radius"
#define kInAppNotificationModalTextSizeKey                      @"text_size"
#define kInAppNotificationButtonIndex                           @"btn_"

/* Define a Font */
#define kInAppNotificationModalFontExtensionKey                 @"otf"
#define kInAppNotificationModalFontAwesomeNameKey               @"FontAwesome5Free-Solid"

/* Define Position Modal */
#define kInAppNotificationModalPositionBottomKey                @"bottom"
#define kInAppNotificationModalPositionTopKey                   @"top"
#define kInAppNotificationModalPositionCenterKey                @"center"

/* Define Resolution Type */
#define kInAppNotificationModalResolutionPointsKey             @"points"
#define kInAppNotificationModalResolutionPercntageKey           @"percentage"
#define kInAppNotificationModalHTMLHeaderKey                    @"<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header>"

/* Define a Notification Type */
#define kInAppNotificationTypeCenterPopUpKey                    @"modal"
#define kInAppNotificationTypeSlideBannerKey                    @"slide_in_banner"
#define kInAppNotificationTypeRatingKey                         @"rating"

/*  Define a DataMart */
#define kInAppNotificationEntityNameKey                         @"InAppNotificationEntity"

/*  Define a Button type */
#define kInAppNotificationButtonTypeKey                         @"type"
#define kInAppNotificationButtonTypeCloseKey                    @"close"
#define kInAppNotificationButtonTypeOpenKey                     @"open"

/* Define size of view */
#define kInAppNotificationModalIconWidth                        50.0
#define kInAppNotificationModalIconHeight                       50.0
#define kSlideInInAppNotificationMinimumHeight                  50.0
#define kInAppNotificationModalYPadding                         10.0
#define kInAppNotificationModalTitleHeight                      40.0
#define kInAppNotificationSlideBannerXPadding                   20.0
#define kInAppNotificationSlideBannerActionButtonWidth          35.0
#define kInAppNotificationSlideBannerActionButtonHeight         35.0
#define KInAppNotificationModalCloseButtonWidth                 32.0
#define KInAppNotificationModalCloseButtonHeight                32.0

#define kInAppNotificationDefaultWidth                          90.0
#define kInAppNotificationDefaultHeight                         90.0
#define kInAppNotificationImageModalDefaultHeight               100.0

#define kHTMLInAppNotificationMaximumWidthInPoints              470.0
#define kHTMLInAppNotificationMinimumHeight                     25.0

/* In App Message Layout Margin */
#define kInAppNotificationModalLayoutMarginKey                  @"margin"
#define kInAppNotificationModalLayoutMarginLeftKey              @"left"
#define kInAppNotificationModalLayoutMarginRightKey             @"right"
#define kInAppNotificationModalLayoutMarginTopKey               @"top"
#define kInAppNotificationModalLayoutMarginBottomKey            @"bottom"
#define kInAppNotificationModalGravityStartKey                  @"start"
#define kInAppNotificationModalGravityEndKey                    @"end"

#define kNotificationClickElementKey                            @"clk_elmt"
#define kNotificationURLElementKey                              @"clk_url"
#define kInAppNotificationFontFileDownlaodURL                   @"https://bsftassets.s3-us-west-2.amazonaws.com/inapp/Font+Awesome+5+Free-Solid-900.otf"

#define kInAppNotificationModalMessagePaddingKey                @"message_padding"
#define kInAppNotificationModalIconPaddingKey                   @"icon_padding"
#define kInAppNotificationModalTitlePaddingKey                  @"title_padding"
#define kInAppNotificationModalBannerPaddingKey                 @"banner_padding"
#define kInAppNotificationModalSubTitlePaddingKey               @"sub_title_padding"
#define kInAppNotificationModalIconImagePaddingKey              @"icon_image_padding"
#define kInAppNotificationModalActionsPaddingKey                @"actions_padding"

#define kInAppNotificationModalTimestampDateFormat              @"yyyy-MM-dd'T'HH:mm:ss.SSSZ"
#define kInAppNotificationDismissDeepLinkURL                    @"blueshift://dismiss"

#endif /* BlueShiftInAppNotificationConstant_h */
