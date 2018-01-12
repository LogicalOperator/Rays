//
//  RaysView.h
//  Rays
//
//  Created by jparsons on 5/6/17.
//  Copyright © 2017 jparsons. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>

#define kBarsCountKey              @"barsCount"
#define kBarsAnimDurationMinKey    @"barsAnimDurationMin"
#define kBarsAnimDurationMaxKey    @"barsAnimDurationMax"
#define kBarsWidthFactorMinKey     @"barsWidthFactorMin"
#define kBarsWidthFactorMaxKey     @"barsWidthFactorMax"
#define kBarsOpacityMinKey         @"barsOpacityMin"
#define kBarsOpacityMaxKey         @"barsOpacityMax"
//current theme
#define kBarColorKey               @"barColor"
#define kBarAltColorKey            @"barAltColor"
#define kBackgroundColorKey        @"backgroundColor"


//#define kUseBarAltColorKey         @"useAltBarColor"
#define kImageURLKey               @"imageURL"
#define kImageAltResURLKey         @"imageAltResURL"
#define kXAlignKey                 @"xAlign"
#define kYAlignKey                 @"yAlign"
#define kXOffsetKey                @"xOffset"
#define kYOffsetKey                @"yOffset"
#define kBarsAngleKey              @"barsAngle"
#define kImgFadeDisableKey         @"imgFadeEnable"
#define kImgShowDurationKey        @"imgShowDuration"
#define kImgZPositionKey           @"imgZPosition"

#define kBarsAnimationSpeedKey     @"barsAnimationSpeed"

#define kThemesRootKey             @"Themes"

#define kAlignTop                  @"Top"
#define kAlignMiddle               @"Middle"
#define kAlignBottom               @"Bottom"

#define kAlignLeft                 @"Left"
#define kAlignCenter               @"Center"
#define kAlignRight                @"Right"


@interface RaysView : ScreenSaverView
{
    IBOutlet id configSheet;
    
    IBOutlet id barsCountOption;
    
    IBOutlet id barsAnimDurationMinOption;
    IBOutlet id barsAnimDurationMaxOption;
    IBOutlet id barsWidthDivisorMinOption;
    IBOutlet NSTextField* barsWidthDivisorMaxOption;
    
    IBOutlet id barsOpacityMinOption;
    IBOutlet id barsOpacityMaxOption;

    IBOutlet NSSlider* barsOpacityMinSlider;
    IBOutlet NSSlider* barsOpacityMaxSlider;
    

    IBOutlet NSColorWell* barColorOption;
    //IBOutlet NSButton* useBarAltColorOption;
    IBOutlet NSColorWell* barAltColorOption;
    IBOutlet NSColorWell* backgroundColorOption;
    IBOutlet NSImageView* imageWell;
    
    IBOutlet id xAlignOption;
    IBOutlet id yAlignOption;
    IBOutlet id xOffsetOption;
    IBOutlet id yOffsetOption;
    
    IBOutlet id barsAngleOption;
    
    IBOutlet NSPopUpButton* themePopupOption;
    
    IBOutlet NSButton* imgFadeDisableOption;
    IBOutlet NSTextField* imgShowDurationOption;
    IBOutlet NSPopUpButton* imgZPositionOption;
    
    IBOutlet id barsAnimationSpeedOption;
    
    IBOutlet NSSlider* barsSpeedSlider;
    IBOutlet NSSlider* barsCountSlider;
    
    IBOutlet NSPopUpButton* imagePopUp;
    
    IBOutlet NSPopUpButton* imageAlignVerticalPopUp;
    IBOutlet NSPopUpButton* imageAlignHorizontalPopUp;
}
@end
