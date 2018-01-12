//
//  RaysView.m
//  Rays
//
//  Created by jparsons on 4/30/17.
//  Copyright © 2017 jparsons. All rights reserved.
//




#import "RaysView.h"
@import QuartzCore;

@implementation RaysView

static NSString* const MyModuleName = @"com.kireji.Rays";

//image
NSImage *img;

// image selected in option but not yet saved
NSImage* imgSelected;
NSURL* imgSelectedURL;
NSURL* imgAltResSelectedURL;


//CIFilter* blurFilter;
//NSArray* filters;

NSDictionary* dict;

ScreenSaverDefaults *defaults;

NSSize screen_size;

float container_edge_length;

NSString* const barsCountKey = @"barsCount";


#pragma mark -
#pragma mark Default Screen Saver Methods

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    
    if (self) {
        #if DEBUG
			NSLog(@"kireji*** %@ hello!", MyModuleName);
        #endif
        
        // ready up color picker
        [NSColorPanel setPickerMask:NSColorPanelRGBModeMask | NSColorPanelGrayModeMask | NSColorPanelWheelModeMask | NSColorPanelCrayonModeMask | NSColorPanelColorListModeMask | NSColorPanelCustomPaletteModeMask];
        
        
        // if no user defaults, load app defaults... defaults need to load the first time to be available for preview
        defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
		
		
        // it seems setting a property to nil will cause the program to use the default values here...
        // Register our default values
        [defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                    @"0.3", kBarsOpacityMinKey,
                                    @"0.6", kBarsOpacityMaxKey,
                                    @"0.025", kBarsWidthFactorMinKey,
                                    @"0.275", kBarsWidthFactorMaxKey,
                                    @"8.0", kBarsAnimDurationMinKey,
                                    @"12.0", kBarsAnimDurationMaxKey,
                                    @"20", kBarsCountKey,
                                    @"0", kBarsAngleKey,
                                    @"0.5", kBarsAnimationSpeedKey,
                                    @"FF0F33", kBarColorKey,
                                    @"383A40", kBarAltColorKey,
                                    @"232329", kBackgroundColorKey,
//                                    @"NO", kUseBarAltColorKey,
                                    @"", kImageURLKey,
                                    @"", kImageAltResURLKey,
                                    @"Center", kXAlignKey,
                                    @"Middle", kYAlignKey,
                                    @"0.0", kXOffsetKey,
                                    @"0.0", kYOffsetKey,
                                    @"NO", kImgFadeDisableKey,
                                    @"10.0", kImgShowDurationKey,
                                    @"Above", kImgZPositionKey,
                                    @"", @"imgWellURL",
                                    nil]
         ];

        
        [self setAnimationTimeInterval:1/30.0];

        
        // make the view layer-backed and become the delegate for the layer
        self.wantsLayer = YES;
    }
    
    return self;
}


- (void)startAnimation
{
	// get screen size
    screen_size = [self bounds].size;
    
    dict = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[RaysView class]] pathForResource:@"FactoryDefaults" ofType:@"plist"]];
    
    // calculate width of bounding layer
    // set it larger than the screen size to handle rotation... quick hack...
	// this also hides a bug:
	//	when bars are re-generated (call to generateBarWithLayer) after animation is finished and the new bar is wider than the previous bar, it will briefly appear on the edge of the screen before swiftly moving along
    container_edge_length = MAX(screen_size.width, screen_size.height) * 1.5f;
    
    [self.layer addSublayer:[self generateImgLayer]];

    
    CALayer* barsMasterLayer = [CALayer layer];
    
    
    // add bars up to selected quantity
    for (int i = 0; i < [defaults integerForKey:kBarsCountKey]; i++) {
        [barsMasterLayer addSublayer:[self generateBarLayer:i]];
    }

	
    // rotate bars master layer
    // increase bar master layer bounds to handle any rotation angle
    [barsMasterLayer setBounds:NSMakeRect(0.0f, 0.0f, container_edge_length, container_edge_length)];
    // user angle
    [barsMasterLayer setAffineTransform:CGAffineTransformMakeRotation([defaults floatForKey:kBarsAngleKey] * (3.14159 / 180.0f))];
    [barsMasterLayer setPosition:CGPointMake(screen_size.width *0.5f, screen_size.height * 0.5f)];

    // add bars master layer to base layer
    [self.layer addSublayer:barsMasterLayer];

    // paint BG
    self.layer.backgroundColor = CGColorCreateCopyWithAlpha([self colorWithHexColorString:[defaults stringForKey:kBackgroundColorKey]].CGColor, 1.0f);
    [self.layer setOpaque:YES];
    
    [super startAnimation];
}

- (void)stopAnimation {
    #if DEBUG
        NSLog(@"%@ stopAnimation", MyModuleName);
    #endif
    
    // remove all sublayers
    [[self.layer.sublayers copy] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    [super stopAnimation];
}


- (void)drawRect:(NSRect)rect {
//    [super drawRect:rect];

    // changing to paint base layer...
    // paint BG
//    NSColor* color;
//    CGFloat backgroundColorComponents[4] = {[defaults floatForKey:kBackgroundRedKey], [defaults floatForKey:kBackgroundGreenKey], [defaults floatForKey:kBackgroundBlueKey], 1.0};
//    color = [NSColor colorWithCGColor:CGColorCreate(CGColorSpaceCreateDeviceRGB(), backgroundColorComponents)];
//    
//    NSBezierPath* path;
//    NSRect rect2;
//    
//    rect2.size = [self bounds].size;
//    rect2.origin = NSMakePoint(0, 0);
//    
//    path = [NSBezierPath bezierPathWithRect:rect2];
//    
//    [color set];
//    [path fill];
//    [path stroke];
}


- (void)animateOneFrame {
    // causes the layer content to be drawn in -drawRect:
//    [self.layer setNeedsDisplay];
    return;
}


- (BOOL)hasConfigureSheet {
    return YES;
}


- (NSWindow*)configureSheet {
    
    ScreenSaverDefaults *defaults;
    
    defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
    
    if (!configSheet) {
        if (![NSBundle loadNibNamed:@"ConfigureSheet" owner:self]) {
            NSLog( @"kireji*** Failed to load configure sheet." );
            NSBeep();
        }
    }

    [self setControls];
    
    #if DEBUG
//        NSLog(@"kireji*** %li", (long)[defaults integerForKey:@"barsCountMax"]);
//        NSLog(@"kireji*** barsCountMaxSlider: %li", (long)[barsCountBaseSlider integerValue]);
    #endif
    
    return configSheet;
}


-(bool)performGammaFade {
	return YES;
}




#pragma mark -
#pragma mark Screen Saver Animation Methods


// Create delegate to handle layers when their animation ends
// Pass finished layer to function to tweak its parameters
-(void)animationDidStop:(CAAnimation*)animation finished:(BOOL)finished {
	
	#if DEBUG
		NSLog(@"kireji*** animation finished yep!");
	#endif
	
	if (finished == YES) {
		CALayer* finishedLayer = [animation valueForKey:@"layer"];
		
		// tweak bar layer properties and animation
		[self generateBarLayerWithLayer:finishedLayer zPosition:finishedLayer.zPosition];
	}
	#if DEBUG
	else {
		NSLog(@"kireji*** bar removed but wasn't finished!");
	}
	#endif
	
}


// wrapper function to create an empty layer object, then feed to function to tweak its parameters
-(CALayer*)generateBarLayer:(int)zPosition {
	
	CALayer* layer = [CALayer layer];
	
	//    layer = [self generateBarLayerWithLayer:layer zPosition:zPosition];
	[self generateBarLayerWithLayer:layer zPosition:zPosition];
	
	return layer;
}


// Generates 'bars', tweaks layer parameters
-(void)generateBarLayerWithLayer:(CALayer*)layer zPosition:(int)zPos {
	// setup basic layer properties: height, width, color, opacity
	NSRect bar = NSZeroRect;
	
	// calc bar size from screen width and height
	float random_size_factor = SSRandomFloatBetween([defaults floatForKey:kBarsWidthFactorMinKey], [defaults floatForKey:kBarsWidthFactorMaxKey]);
	bar.size = NSMakeSize(screen_size.width * random_size_factor, container_edge_length * 1.5f);
	
//	bar.origin = NSMakePoint(0, 0);
	
	float opacity = SSRandomFloatBetween([defaults floatForKey:kBarsOpacityMinKey], [defaults floatForKey:kBarsOpacityMaxKey]);
	
	// assign primary or secondary color to layer
	if (SSRandomFloatBetween(0, 1.0) <= 0.25) {
		// secondary
		layer.backgroundColor = CGColorCreateCopyWithAlpha([self colorWithHexColorString:[defaults stringForKey:kBarAltColorKey]].CGColor, opacity);
	}
	else {
		// use primary color
		layer.backgroundColor = CGColorCreateCopyWithAlpha([self colorWithHexColorString:[defaults stringForKey:kBarColorKey]].CGColor, opacity);
	}
	
	layer.zPosition = zPos;
	
	//set layer frame to rect dimensions
	layer.frame = NSRectToCGRect(bar);
	
	
	
	// setup layer animation
	CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"position"];
	
	// adding delegate for the animation object...
	[animation setDelegate:self];
	
	
	// attach layer info to animation
	[animation setValue:layer forKey:@"layer"];
	
	// from older version where min/max duration could be set by user... read these values from config.
	float anim_duration = SSRandomFloatBetween([defaults floatForKey:kBarsAnimDurationMaxKey], [defaults floatForKey:kBarsAnimDurationMinKey]);
	
	// bars proto config 1/4 chance of L->R
	if (SSRandomFloatBetween(0, 1.0) <= 0.25) {
		//setup layer animation L -> R
		[layer  setPosition:NSMakePoint(0 - bar.size.width, 0)];
		// start point (0 - bar width, screen vertical midpoint)
		[animation setFromValue:[NSValue valueWithPoint:NSMakePoint(0 - bar.size.width, screen_size.height / 2)]];
		// end point (screen width + bar width, screen vertical midpoint)
		[animation setToValue:[NSValue valueWithPoint:NSMakePoint(container_edge_length + bar.size.width, screen_size.height / 2)]];
	}
	else {
		// L <- R
		[layer  setPosition:NSMakePoint(container_edge_length + bar.size.width, 0)];
		// start point (screen width + bar width, screen vertical midpoint)
		[animation setFromValue:[NSValue valueWithPoint:NSMakePoint(container_edge_length + bar.size.width, screen_size.height / 2)]];
		// end point (0 - bar width, screen vertical midpoint)
		[animation setToValue:[NSValue valueWithPoint:NSMakePoint(0 - bar.size.width, screen_size.height / 2)]];
	}
	
	[animation setDuration:anim_duration];
	// set animation speed...
	[animation setSpeed:[defaults floatForKey:kBarsAnimationSpeedKey]];
	
	[layer addAnimation:animation forKey:@"position"];
}


// Creates image layer, loads image, scales (if necessary), places image, and sets up image fade-in/-out
-(CALayer*)generateImgLayer {
	// add image layer
	#if DEBUG
		NSLog(@"kireji*** kImageURLKey value %@", [defaults URLForKey:kImageURLKey]);
	#endif
	
	
	img = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[defaults stringForKey:kImageURLKey]]];
	
	// try to load alternate image resolution file
//	NSLog(@"kireji*** imgAltResURLKey: %@", [defaults stringForKey:kImageAltResURLKey]);
	[img addRepresentation:[NSImageRep imageRepWithContentsOfURL:[NSURL URLWithString:[defaults stringForKey:kImageAltResURLKey]]]];
	
	
	#if DEBUG
		if (img == nil) {
			NSLog(@"kireji*** no image!");
			NSLog(@"kireji*** imgName %@", [defaults URLForKey:kImageURLKey]);
			//NSLog(@"kireji*** bundle: %@", ssBundle);
		}
		else {
			NSLog(@"kireji*** %@", img);
		}
	#endif
	
	CALayer* imgLayer = [CALayer layer];
	
	CGFloat desiredScaleFactor = [[self window] backingScaleFactor];
	CGFloat actualScaleFactor = [img recommendedLayerContentsScale:desiredScaleFactor];
	float imgPreviewScaleFactor = 0.0f;
	
	id layerContents = [img layerContentsForContentsScale:actualScaleFactor];
	
	[imgLayer setContents:layerContents];
	[imgLayer setContentsScale:actualScaleFactor];
	
	// calculate scale factor for image when displayed in preview
	NSScreen *mainScreen = [NSScreen mainScreen];
	NSRect screenRect = [mainScreen frame];
	imgPreviewScaleFactor = [super bounds].size.width / screenRect.size.width;
	
	// normal size image...
	[imgLayer setBounds:NSMakeRect(0, 0, img.size.width, img.size.height)];
	
	
	#if DEBUG
	//        NSLog(@"kireji*** img width, height: %f, %f", img.size.width, img.size.height);
	//        // displays preview window with in preview mode but screen size when screen saver is active
	//        NSLog(@"kireji*** window size?: %f, %f", [super bounds].size.width, [super bounds].size.height);
	//
	//        // displays screen size (scaled) -- as intended
	//        NSLog(@"kireji*** screen size?: %f %f", screenRect.size.width, screenRect.size.height);
	//        NSLog(@"kireji*** imgPreviewScaleFactor: %f", imgPreviewScaleFactor);
	#endif
	
	
	// scale image down when in preview
	if ([self isPreview]) {
		// set image bounds
		imgLayer.bounds = NSMakeRect(
									 imgLayer.bounds.origin.x,
									 imgLayer.bounds.origin.y,
									 imgLayer.bounds.size.width * imgPreviewScaleFactor,
									 imgLayer.bounds.size.height * imgPreviewScaleFactor
									 );
	}
	
	// image position
	// x, y
	// x, y offsets are epxressed as percentage of screen size
	// convert percentage into fractional
	float x_offset = ([defaults floatForKey:kXOffsetKey]) / 100.0f;
	float y_offset = ([defaults floatForKey:kYOffsetKey]) / 100.0f;
	
	// alignment
	NSString* xAlign = [defaults stringForKey:kXAlignKey];
	NSString* yAlign = [defaults stringForKey:kYAlignKey];
	
	#if DEBUG
		NSLog(@"kireji*** xAlign %@", xAlign);
		NSLog(@"kireji*** yAlign %@", yAlign);
		NSLog(@"kireji*** screen.height %f", screen_size.height);
		NSLog(@"kireji*** screen.width %f", screen_size.width);
	#endif
	
	//position
	CGFloat x_pos = 0.0f;
	CGFloat y_pos = 0.0f;
	
	// horizontal
	// left
	if ([xAlign  isEqual: kAlignLeft]) {
		x_pos = 0.0f + (imgLayer.bounds.size.width * 0.5f) + (x_offset * screen_size.width);
	}
	// center
	else if ([xAlign  isEqual: kAlignCenter]) {
		x_pos = (screen_size.width * 0.5f) + (0.0f) + (x_offset * screen_size.width);
	}
	// right
	else {
		x_pos = screen_size.width - (imgLayer.bounds.size.width * 0.5f) - (x_offset * screen_size.width);
	}
	
	// vert
	// top
	if ([yAlign  isEqual: kAlignTop]) {
		y_pos = (screen_size.height) - (imgLayer.bounds.size.height * 0.5f) - (y_offset * screen_size.height);
	}
	// middle
	else if ([yAlign  isEqual: kAlignMiddle]) {
		y_pos = (screen_size.height * 0.5f) + (0.0f) - (y_offset * screen_size.height);
	}
	// bottom
	else {
		y_pos = (0.0f) + (imgLayer.bounds.size.height * 0.5f) + (y_offset * screen_size.height);
	}
	
	[imgLayer setPosition:NSMakePoint(x_pos, y_pos)];
	
	
	// img z position
	if ( [[defaults stringForKey:kImgZPositionKey]  isEqual:@"Above"]) {
		imgLayer.zPosition = FLT_MAX;
	}
	else  {
		imgLayer.zPosition = 0;
	}
	
	
	
	// image fade in-out
	if ([defaults boolForKey:kImgFadeDisableKey] == NO) {
		// fade using keyframes to control timing
		CAKeyframeAnimation* imgKeyframeFade = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
		NSArray* opacityFrames = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1.0f], [NSNumber numberWithFloat:1.0f], [NSNumber numberWithFloat:0.0f], [NSNumber numberWithFloat:0.0f], nil];
		NSArray* frameTimings = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0f], [NSNumber numberWithFloat:0.5f], [NSNumber numberWithFloat:0.75f], [NSNumber numberWithFloat:1.0f], nil];
		[imgKeyframeFade setValues:opacityFrames];
		[imgKeyframeFade setKeyTimes:frameTimings];
		[imgKeyframeFade setDuration: [defaults floatForKey:kImgShowDurationKey]];
		imgKeyframeFade.autoreverses = YES;
		[imgKeyframeFade setRepeatCount:FLT_MAX];
		[imgLayer addAnimation:imgKeyframeFade forKey:@"opacity"];
	}
	
	
	
	return imgLayer;
}




#pragma mark -
#pragma mark Configure Sheet methods

// load app-level defaults into user-level defaults
-(void)loadAppDefaults {
    //read defaults.plist
    //set user defaults
}

// set control values to values from defaults
-(void) setControls {
    [barsCountOption setIntegerValue:[defaults integerForKey:kBarsCountKey]];
    [imageWell setImage:img];

    // also set image URL since an empty value will cause the code to clear the image (url is empty any time a user does not select a new image... )
    imgSelectedURL = [NSURL URLWithString:[defaults stringForKey:kImageURLKey]];
    imgAltResSelectedURL = [NSURL URLWithString:[defaults stringForKey:kImageAltResURLKey]];
	
    [xAlignOption setIntegerValue:[defaults integerForKey:kXAlignKey]];
    [yAlignOption setIntegerValue:[defaults integerForKey:kYAlignKey]];
	
    [xOffsetOption setStringValue:[defaults stringForKey:kXOffsetKey]];
    [yOffsetOption setStringValue:[defaults stringForKey:kYOffsetKey]];

    
    [barColorOption setColor:[self colorWithHexColorString:[defaults stringForKey:kBarColorKey]]];
    [barAltColorOption setColor:[self colorWithHexColorString:[defaults stringForKey:kBarAltColorKey]]];
    [backgroundColorOption setColor:[self colorWithHexColorString:[defaults stringForKey:kBackgroundColorKey]]];
    
//    [useBarAltColorOption setState:[defaults boolForKey:kUseBarAltColorKey]];


    [barsOpacityMinOption setStringValue:[defaults stringForKey:kBarsOpacityMinKey]];
    [barsOpacityMaxOption setStringValue:[defaults stringForKey:kBarsOpacityMaxKey]];
    
    // opacity sliders
    [barsOpacityMinSlider setStringValue:[defaults stringForKey:kBarsOpacityMinKey]];
    [barsOpacityMaxSlider setStringValue:[defaults stringForKey:kBarsOpacityMaxKey]];
    
	
    // add items to the theme popup
    // ok, USA
	NSArray* sortedThemeKeys = [[dict[@"Themes"] allKeys] sortedArrayUsingSelector:@selector(compare:)];
	// assign theme keys to menu list
	[themePopupOption addItemsWithTitles:sortedThemeKeys];
	
    [barsAngleOption setFloatValue:[defaults floatForKey:kBarsAngleKey]];
    
    [imgFadeDisableOption setState:[defaults boolForKey:kImgFadeDisableKey]];
    [imgShowDurationOption setFloatValue:[defaults floatForKey:kImgShowDurationKey]];
    [imgZPositionOption selectItemWithTitle:[defaults stringForKey:kImgZPositionKey]];
    
    [barsAnimationSpeedOption setStringValue:[defaults stringForKey:kBarsAnimationSpeedKey]];
    
    [barsSpeedSlider setStringValue:[defaults stringForKey:kBarsAnimationSpeedKey]];
    [barsCountSlider setStringValue:[defaults stringForKey:kBarsCountKey]];
    
    [imageAlignVerticalPopUp selectItemWithTitle:[defaults stringForKey:kYAlignKey]];
    [imageAlignHorizontalPopUp selectItemWithTitle:[defaults stringForKey:kXAlignKey]];
}

-(IBAction)cancelClick:(id)sender {
    #if DEBUG
        NSLog(@"kireji*** CancelClick");
    #endif

    //remove selected image effects
    [imageWell setImage:img];
    imgSelectedURL = nil;
    imgSelected = nil;
    
    [[NSApplication sharedApplication] endSheet:configSheet];
}


-(IBAction)okClick: (id)sender {
    #if DEBUG
        NSLog(@"kireji*** okClick begin");
    #endif
    
    ScreenSaverDefaults *defaults;
    defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
    
    // Update our defaults
    [defaults setInteger:[barsCountOption integerValue] forKey:kBarsCountKey];
    [defaults setInteger:[xAlignOption integerValue] forKey:kXAlignKey];
    [defaults setInteger:[yAlignOption integerValue] forKey:kYAlignKey];
    [defaults setFloat:[xOffsetOption floatValue] forKey:kXOffsetKey];
    [defaults setFloat:[yOffsetOption floatValue] forKey:kYOffsetKey];
    
    
    // set image and image alternate resolution URL
    if (imgSelectedURL != nil) {
        [defaults setValue:[imgSelectedURL absoluteString] forKey:kImageURLKey];
        [defaults setValue:[imgAltResSelectedURL absoluteString] forKey:kImageAltResURLKey];
    }
    else {
        [defaults setValue:@"" forKey:kImageURLKey];
        [defaults setValue:@"" forKey:kImageAltResURLKey];
    }

	#if DEBUG
		NSLog(@"kireji*** imgSelectedURL is nil: %d", (imgSelectedURL == nil));
		NSLog(@"kireji*** bar color option --> hex: %@", [self hexadecimalValueOfAnNSColor:barColorOption.color]);
	#endif
    
    [defaults setValue:[self hexadecimalValueOfAnNSColor:barColorOption.color] forKey:kBarColorKey];
    [defaults setValue:[self hexadecimalValueOfAnNSColor:barAltColorOption.color] forKey:kBarAltColorKey];
    [defaults setValue:[self hexadecimalValueOfAnNSColor:backgroundColorOption.color] forKey:kBackgroundColorKey];
    
    
//    [defaults setBool:[useBarAltColorOption state] forKey:kUseBarAltColorKey];

    
    [defaults setFloat:[barsOpacityMinSlider floatValue] forKey:kBarsOpacityMinKey];
    [defaults setFloat:[barsOpacityMaxSlider floatValue] forKey:kBarsOpacityMaxKey];
    
    // constrain angle for bars
    float barsAngle = [barsAngleOption floatValue];
    if (barsAngle > 360.0f || barsAngle < -360.0f) {
        barsAngle = 0;
    }
    [defaults setFloat:barsAngle forKey:kBarsAngleKey];
    
    [defaults setBool:[imgFadeDisableOption state] forKey:kImgFadeDisableKey];
    
    // og
//    [defaults setFloat:[imgShowDurationOption floatValue] forKey:kImgShowDurationKey];
    
    float imgShowDuration = [imgShowDurationOption floatValue];
    if (imgShowDuration < 0 || imgShowDuration >= 1800) {
        [defaults setFloat:10.0f forKey:kImgShowDurationKey];
    }
    else {
        [defaults setFloat:[imgShowDurationOption floatValue] forKey:kImgShowDurationKey];
    }
    
    [defaults setValue:[imgZPositionOption titleOfSelectedItem] forKey:kImgZPositionKey];
    
    
    [defaults setFloat:[barsAnimationSpeedOption floatValue] forKey:kBarsAnimationSpeedKey];
    
    [defaults setValue:[imageAlignVerticalPopUp titleOfSelectedItem] forKey:kYAlignKey];
    [defaults setValue:[imageAlignHorizontalPopUp titleOfSelectedItem] forKey:kXAlignKey];
    
    [defaults setFloat:[barsSpeedSlider floatValue] forKey:kBarsAnimationSpeedKey];
    [defaults setInteger:[barsCountSlider integerValue] forKey:kBarsCountKey];
    
    // Save the settings to disk
    [defaults synchronize];
    
    // Close the sheet
    [[NSApplication sharedApplication] endSheet:configSheet];
    
    
    #if DEBUG
        NSLog(@"kireji*** okClick end");
    #endif
}


-(IBAction)resetToDefault:(id)sender {
    // load defaults from plist
    [self loadAppDefaults];
    // set gui controls to matching values
    [self setControls];
}


-(IBAction)selectImageButtonAction:(id)sender{
    
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    // Change "Open" dialog button to "Choose"
    [openDlg setPrompt:@"Choose"];
    // only allow NSImage supported file types
    [openDlg setAllowedFileTypes:NSImage.imageTypes];
    
    
    // Display the dialog and when the OK button is pressed...
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        imgSelectedURL = [openDlg URL];
        // use alternate resolution image url
        imgAltResSelectedURL = [self generateImageAlternateResURL:imgSelectedURL];
        
        imgSelected = [[NSImage alloc] initWithContentsOfURL:imgSelectedURL];
        [imgSelected addRepresentation:[NSImageRep imageRepWithContentsOfURL:imgAltResSelectedURL]];
        
        [imageWell setImage:imgSelected];
        
        #if DEBUG
//            NSLog(@"kireji*** imageSelectedURL: %@", imgSelectedURL);
//            NSLog(@"kireji*** imageSelected: %@", imgSelected);
            NSLog(@"kireji*** imgAltResSelectedURL %@", imgAltResSelectedURL.absoluteString);
        #endif
//        }
    }
}


//-(IBAction)useAltBarColorControlAction:(id)sender {
//    barAltColorOption.enabled = [useBarAltColorOption state];
//}

// TODO: remove conditional blocks: no longer enabling/disabling controls
-(IBAction)evalThemeSelection:(id)sender {
    
    NSString* selectedTheme = [themePopupOption selectedItem].title;
	
    NSDictionary* theme = dict[kThemesRootKey][selectedTheme];

	// bar primary color
	[barColorOption setColor:[self colorWithHexColorString:theme[kBarColorKey]]];
	
	// bar alt color
	[barAltColorOption setColor:[self colorWithHexColorString:theme[kBarAltColorKey]]];

	// background color
	[backgroundColorOption setColor:[self colorWithHexColorString:theme[kBackgroundColorKey]]];
	
	[barsOpacityMinSlider setStringValue:theme[kBarsOpacityMinKey]];
	[barsOpacityMaxSlider setStringValue:theme[kBarsOpacityMaxKey]];
}


-(IBAction)clearImageClick:(id)sender {
    // clear stored image
    [imageWell  setImage:nil];
    img = nil;
    imgSelected = nil;
    imgSelectedURL = nil;
    imgAltResSelectedURL = nil;
}

// Handle selected options from image popup control
// this function works but is not actually used
// the only items in the list trigger a function directly
// this was planned to handle selecting built-in images from the list
-(IBAction)imagePopUpHandler:(id)sender {
    NSString* imagePopUpSelected = [imagePopUp titleOfSelectedItem];
	
	#if DEBUG
		NSLog(@"kireji*** selected item: %@", [imagePopUp selectedItem].title);
	#endif
	
    if ([imagePopUpSelected  isEqual: @"Choose..."]) {
//        [self selectImageButtonAction];
    }
    else if ([imagePopUpSelected isEqual:@"None"]) {
    }
    else {
    }
}


-(IBAction)handleDisableImageFadeCheck:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Disable Fade"];
//    [alert setIcon:NSImageNameD]
    
    [alert setMessageText:@"Disabling Image Fade May Damage Your Display"];
    [alert setInformativeText:@"Displaying unchanging pictures on your displays can damge them. Please consult the documentation for your displays to learn how to prevent this damage before disabling image fade.\n\n"];
    
    // check state before showing; state is inverted since the checkbox state is changed just before the dialog is shown
    if ([imgFadeDisableOption state] == 1) {
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:nil];
    }
    
}


-(void) alertDidEnd:(NSAlert *)a returnCode:(NSInteger)rc contextInfo:(void *)ci {
    switch(rc) {
        case NSAlertFirstButtonReturn:
            [imgFadeDisableOption setState:0];
            break;
        case NSAlertSecondButtonReturn:
            [imgFadeDisableOption setState:1];
            break;
    }
}




#pragma mark -
#pragma mark Helper Functions

-(NSURL*)generateImageAlternateResURL:(NSURL*)imgURL {
	//    NSURL* imgURLTest = [NSURL URLWithString:@"file:///Users/jparsons/Desktop/jjarro-symbol.png"];
	//    NSString* imgURLTest = [[NSURL URLWithString:@"file:///Users/jparsons/Desktop/jjarro-symbol.png"] lastPathComponent];
	NSString* imgName = [[imgURL URLByDeletingPathExtension] lastPathComponent];
	NSString* imgAltResName;
	NSString* imgExt = [imgURL pathExtension];
	NSString* hiResIndicator = @"@2x";
	
	// name the file to the opposite type @2x vs. non-@2x
	if ([imgName hasSuffix:hiResIndicator]) {
		imgAltResName = [imgName substringToIndex:imgName.length - 3];
	}
	else {
		imgAltResName = [imgName stringByAppendingString:hiResIndicator];
	}
	
	
	NSURL* imgAltResURL = [[imgURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:[[NSArray arrayWithObjects:imgAltResName, @".", imgExt, nil] componentsJoinedByString:@""]];
	
	#if DEBUG
		NSLog(@"kireji*** url file name?: %@", imgAltResName);
		NSLog(@"kireji*** url file extension?: %@", imgExt);
		//    NSLog(@"kireji*** url file name has @2x suffix?: %hhd", [imgNameTest hasSuffix:@"@2x"]);
		NSLog(@"kireji*** assembled file path?: %@", imgAltResURL.absoluteString);
	#endif
	
	return imgAltResURL;
}


// generate NSColor from hexademical color string
// from https://stackoverflow.com/questions/8697205/convert-hex-color-code-to-nscolor/8697241#8697241
-(NSColor*)colorWithHexColorString:(NSString*)inColorString {
	NSColor* result = nil;
	unsigned colorCode = 0;
	unsigned char redByte, greenByte, blueByte;
	
	if (nil != inColorString)
	{
		NSScanner* scanner = [NSScanner scannerWithString:inColorString];
		(void) [scanner scanHexInt:&colorCode]; // ignore error
	}
	redByte = (unsigned char)(colorCode >> 16);
	greenByte = (unsigned char)(colorCode >> 8);
	blueByte = (unsigned char)(colorCode); // masks off high bits
	
	CGFloat colorComponents[4] = {(CGFloat)redByte / 0xff, (CGFloat)greenByte / 0xff, (CGFloat)blueByte / 0xff, 1.0f};
	result = [NSColor colorWithCGColor:CGColorCreate(CGColorSpaceCreateDeviceRGB(), colorComponents)];
	
	return result;
}


// Convert NSColor to hexedecimal string
// modified code from Apple Technical Q&A QA1576
-(NSString *)hexadecimalValueOfAnNSColor:(NSColor*)color {
	int redIntValue, greenIntValue, blueIntValue;
	NSString *redHexValue, *greenHexValue, *blueHexValue;
	
	redIntValue=color.redComponent*255.99999f;
	greenIntValue=color.greenComponent*255.99999f;
	blueIntValue=color.blueComponent*255.99999f;
	
	// Convert the numbers to hex strings
	redHexValue=[NSString stringWithFormat:@"%02x", redIntValue];
	greenHexValue=[NSString stringWithFormat:@"%02x", greenIntValue];
	blueHexValue=[NSString stringWithFormat:@"%02x", blueIntValue];
	
	// Concatenate the red, green, and blue components' hex strings together with a "#"
	return [NSString stringWithFormat:@"%@%@%@", redHexValue, greenHexValue, blueHexValue];
}

@end
