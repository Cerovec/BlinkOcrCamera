//
//  ViewController.m
//  NoProcessing-sample
//
//  Created by Jura on 04/09/15.
//  Copyright (c) 2015 MicroBlink. All rights reserved.
//

#import "ViewController.h"
#import <MicroBlink/MicroBlink.h>

#define LICENSE_KEY "VOXRIUIJ-ERH4LRMF-FFQMLROF-YXC4LROF-YXC4LROF-YXC4LROF-YXC4LROF-HOGOJ4FB"

@interface ViewController () <PPScanDelegate>

@property (nonatomic, strong) PPCoordinator *coordinator;

@property (nonatomic, strong) PPSettings *emptySettings;

@property (nonatomic, strong) PPSettings *ocrSettings;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.emptySettings = [[PPSettings alloc] init];
    self.emptySettings.metadataSettings.currentVideoFrame = YES;
    self.emptySettings.licenseSettings.licenseKey = @LICENSE_KEY;

    self.ocrSettings = [[PPSettings alloc] init];
    self.ocrSettings.licenseSettings.licenseKey = @LICENSE_KEY;
    PPOcrRecognizerSettings *ocrRecognizerSettings = [[PPOcrRecognizerSettings alloc] init];
    [ocrRecognizerSettings addOcrParser:[[PPRawOcrParserFactory alloc] init] name:@"Raw"];
    [self.ocrSettings.scanSettings addRecognizerSettings:ocrRecognizerSettings];
}

/**
 * Method allocates and initializes the Scanning coordinator object.
 * Coordinator is initialized with settings for scanning
 *
 *  @param error Error object, if scanning isn't supported
 *
 *  @return initialized coordinator
 */
- (PPCoordinator *)coordinatorWithError:(NSError**)error {

    if ([PPCoordinator isScanningUnsupported:error]) {
        return nil;
    }

    PPCoordinator *coordinator = [[PPCoordinator alloc] initWithSettings:self.emptySettings];
    
    return coordinator;
}


- (void)viewWillAppear:(BOOL)animated {

    NSError *error;

    self.coordinator = [self coordinatorWithError:&error];

    /** If scanning isn't supported, present an error */
    if (self.coordinator == nil) {
        NSString *messageString = [error localizedDescription];
        [[[UIAlertView alloc] initWithTitle:@"Warning"
                                    message:messageString
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil, nil] show];

        return;
    }

    /** Allocate and present the scanning view controller */
    UIViewController<PPScanningViewController>* scanningViewController =
        [self.coordinator cameraViewControllerWithDelegate:self];

    [self addChildViewController:scanningViewController];
    scanningViewController.view.frame = self.view.bounds;
    [self.view addSubview:scanningViewController.view];
    [scanningViewController didMoveToParentViewController:self];
}


#pragma mark - PPScanDelegate

- (void)scanningViewControllerUnauthorizedCamera:(UIViewController<PPScanningViewController> *)scanningViewController {
    // Add any logic which handles UI when app user doesn't allow usage of the phone's camera
}

- (void)scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController
                  didFindError:(NSError *)error {
    // Can be ignored. See description of the method
}

- (void)scanningViewControllerDidClose:(UIViewController<PPScanningViewController> *)scanningViewController {

    // As scanning view controller is presented full screen and modally, dismiss it
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController
              didOutputResults:(NSArray *)results {

    // Because this method is called only when ocrSettings are used

    for (id result in results) {
        if ([result isKindOfClass:[PPOcrRecognizerResult class]]) {
            PPOcrRecognizerResult *ocrResult = (PPOcrRecognizerResult *)result;
            NSLog(@"Ocr result %@", [[ocrResult ocrLayout] string]);
        }
    }

    self.coordinator.currentSettings = self.ocrSettings;
    [self.coordinator applySettings];

    [scanningViewController resumeScanningAndResetState:NO];
}

- (void)scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController didOutputMetadata:(PPMetadata *)metadata {

    // Did output metadata. This is called just when EmptySettings are used
    // - because only they have metadataSettings.currentVideoFrame = YES

    if ([metadata isKindOfClass:[PPImageMetadata class]]) {
        NSLog(@"PPImageMetadata!");

        PPImageMetadata* imageMetadata = (PPImageMetadata *)metadata;

        UIImage *image = [imageMetadata image];

        self.coordinator.currentSettings = [self ocrSettings];
        [self.coordinator applySettings];

        [scanningViewController pauseScanning];

        [self.coordinator processImage:image scanningRegion:CGRectMake(0.0, 0.0, 1.0, 1.0) delegate:self];
    }
}


@end
