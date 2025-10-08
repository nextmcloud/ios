//
//  AdjustHelper.m
//  Nextcloud
//
//  Created by A200073704 on 17/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

#import "AdjustHelper.h"
//#import <AdjustSdk/AdjustSdk.h>

@implementation AdjustHelper

-(void)configAdjust {
    self.yourAppToken = @"1zfaxn19pd7k";
    self.environment = ADJEnvironmentProduction;
    self.adjustConfig = [ADJConfig configWithAppToken:self.yourAppToken
                                                environment:self.environment];
    [self.adjustConfig setLogLevel:ADJLogLevelVerbose];
    [Adjust appDidLaunch:self.adjustConfig];
    self.adjustConfig = [[ADJConfig alloc] initWithAppToken:self.yourAppToken
                                                environment:self.environment];
    [self.adjustConfig setLogLevel:ADJLogLevelVerbose];
    [Adjust initSdk:self.adjustConfig];
}

-(void)subsessionEnd {
    [Adjust trackSubsessionEnd];
}

-(void)subsessionStart {
    [Adjust trackSubsessionStart];
}

- (void)trackLogin {
    self.eventLogin = [ADJEvent eventWithEventToken:@"p8hl78"];
    self.eventLogin = [[ADJEvent alloc] initWithEventToken:@"p8hl78"];
//    self.eventLogin = [ADJEvent eventWithEventToken:@"p8hl78"];
    [Adjust trackEvent: self.eventLogin];
}

-(void)trackEvent:(TriggerEvent)event {
//    self.event = [ADJEvent eventWithEventToken:@"gb97gb"];
    BOOL track = [[NSUserDefaults standardUserDefaults] valueForKey:@"isAnalysisDataCollectionSwitchOn"];
    if (!track) {
        return;
    }
    
    switch(event){
       case Login:
        {
            ADJEvent *event = [ADJEvent eventWithEventToken:@"p8hl78"];
            ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"p8hl78"];
//            event = [ADJEvent eventWithEventToken:@"gb97gb"];
//            self.event = [ADJEvent eventWithEventToken:@"gb97gb"];
            [Adjust trackEvent:event];
        }
          break;
        case LoginSuccessful:
         {
             ADJEvent *event = [ADJEvent eventWithEventToken:@"dowf81"];
             ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"dowf81"];
 //            event = [ADJEvent eventWithEventToken:@"gb97gb"];
 //            self.event = [ADJEvent eventWithEventToken:@"gb97gb"];
             [Adjust trackEvent:event];
         }
           break;
       case Sharing:
        {
            ADJEvent *event = [ADJEvent eventWithEventToken:@"mbeoyd"];
            ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"mbeoyd"];
            [Adjust trackEvent:event];
            NSLog(@"%@", [event debugDescription]);
        }
//            self.event = [ADJEvent eventWithEventToken:@"fqtiu7"];
          break;
        case CreateLink:
        {
            ADJEvent *event = [ADJEvent eventWithEventToken:@"29b333"];
            ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"29b333"];
            [Adjust trackEvent:event];
        }
//            self.event = [ADJEvent eventWithEventToken:@"qeyql3"];
           break;
        case DocumentScan:
        {
            ADJEvent *event = [ADJEvent eventWithEventToken:@"im963g"];
            ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"im963g"];
            [Adjust trackEvent:event];
        }
//            self.event = [ADJEvent eventWithEventToken:@"7fec8n"];
           break;
        case CameraUpload:
        {
            ADJEvent *event = [ADJEvent eventWithEventToken:@"hf9paq"];
            ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"hf9paq"];
            [Adjust trackEvent:event];
        }
//            self.event = [ADJEvent eventWithEventToken:@"v1g6ly"];
           break;
        case FileUpload:
        {
            ADJEvent *event = [ADJEvent eventWithEventToken:@"hsbk2m"];
            ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"hsbk2m"];
            [Adjust trackEvent:event];
        }
//            self.event = [ADJEvent eventWithEventToken:@"4rd8r4"];
           break;
        case UseCamera:
        {
            ADJEvent *event = [ADJEvent eventWithEventToken:@"3czack"];
            ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"3czack"];
            [Adjust trackEvent:event];
        }
//            self.event = [ADJEvent eventWithEventToken:@"3czack"];
           break;
        case Logout:
        {
            ADJEvent *event = [ADJEvent eventWithEventToken:@"n5q2qu"];
            ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"n5q2qu"];
            [Adjust trackEvent:event];
        }
//            self.event = [ADJEvent eventWithEventToken:@"g6mj9y"];
           break;
        case ResetsApp:
        {
            ADJEvent *event = [ADJEvent eventWithEventToken:@"3sj1xp"];
            ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"3sj1xp"];
            [Adjust trackEvent:event];
        }
//            self.event = [ADJEvent eventWithEventToken:@"zi18r0"];
           break;
        case AutomaticUploadPhotosOn:
        {
            ADJEvent *event = [ADJEvent eventWithEventToken:@"5lxz6h"];
            ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"5lxz6h"];
            [Adjust trackEvent:event];
        }
//            self.event = [ADJEvent eventWithEventToken:@"vwd9yk"];
           break;
        case AutomaticUploadPhotosOff:
        {
            ADJEvent *event = [ADJEvent eventWithEventToken:@"176496"];
            ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"176496"];
            [Adjust trackEvent:event];
        }
//            self.event = [ADJEvent eventWithEventToken:@"e95w5t"];
           break;
        case ManualBackup:
        {
            ADJEvent *event = [ADJEvent eventWithEventToken:@"oojr4y"];
            ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"oojr4y"];
            [Adjust trackEvent:event];
        }
//            self.event = [ADJEvent eventWithEventToken:@"oojr4y"];
           break;
        case AutomaticBackup:
        {
            ADJEvent *event = [ADJEvent eventWithEventToken:@"7dkhkx"];
            ADJEvent *event = [[ADJEvent alloc] initWithEventToken:@"7dkhkx"];
            [Adjust trackEvent:event];
        }
//            self.event = [ADJEvent eventWithEventToken:@"7dkhkx"];
           break;
      
       default :
            break;
    }
//    [Adjust trackEvent: self.event];
}

@end

