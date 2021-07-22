//
//  AdjustHelper.m
//  Nextcloud
//
//  Created by TSI-mc on 20/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

#import "AdjustHelper.h"

@implementation AdjustHelper

-(void)configAdjust {
    self.yourAppToken = @"1zfaxn19pd7k";
    self.environment = ADJEnvironmentSandbox;
    self.adjustConfig = [ADJConfig configWithAppToken:self.yourAppToken
                                                environment:self.environment];

    [Adjust appDidLaunch:self.adjustConfig];
}

-(void)subsessionEnd {
    [Adjust trackSubsessionEnd];
}

- (void)trackLogin {
    self.eventLogin = [ADJEvent eventWithEventToken:@"gb97gb"];
    [Adjust trackEvent: self.eventLogin];
}

-(void)trackEvent:(TriggerEvent)event {
//    self.event = [ADJEvent eventWithEventToken:@"gb97gb"];
    if (false) {
        return;
    }
    switch(event){
       case Login:
            self.event = [ADJEvent eventWithEventToken:@"gb97gb"];
          break;
       case Sharing:
            self.event = [ADJEvent eventWithEventToken:@"fqtiu7"];
          break;
        case CreateLink:
            self.event = [ADJEvent eventWithEventToken:@"qeyql3"];
           break;
        case DocumentScan:
            self.event = [ADJEvent eventWithEventToken:@"7fec8n"];
           break;
        case CameraUpload:
            self.event = [ADJEvent eventWithEventToken:@"v1g6ly"];
           break;
        case FileUpload:
            self.event = [ADJEvent eventWithEventToken:@"4rd8r4"];
           break;
        case UseCamera:
            self.event = [ADJEvent eventWithEventToken:@"3czack"];
           break;
        case Logout:
            self.event = [ADJEvent eventWithEventToken:@"g6mj9y"];
           break;
        case ResetsApp:
            self.event = [ADJEvent eventWithEventToken:@"zi18r0"];
           break;
        case AutomaticUploadPhotosOn:
            self.event = [ADJEvent eventWithEventToken:@"vwd9yk"];
           break;
        case AutomaticUploadPhotosOff:
            self.event = [ADJEvent eventWithEventToken:@"e95w5t"];
           break;
        case ManualBackup:
            self.event = [ADJEvent eventWithEventToken:@"oojr4y"];
           break;
        case AutomaticBackup:
            self.event = [ADJEvent eventWithEventToken:@"7dkhkx"];
           break;
      
       default :
            break;;
    }
    [Adjust trackEvent: self.event];
}

@end
