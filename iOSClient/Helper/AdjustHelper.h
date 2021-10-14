//
//  AdjustHelper.h
//  Nextcloud
//
//  Created by TSI-mc on 20/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AdjustSdk/Adjust.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    Login,
    Sharing,
    CreateLink,
    DocumentScan,
    CameraUpload,
    FileUpload,
    UseCamera,
    Logout,
    ResetsApp,
    AutomaticUploadPhotosOn,
    AutomaticUploadPhotosOff,
    ManualBackup,
    AutomaticBackup
} TriggerEvent;

@interface AdjustHelper : NSObject

@property (nonatomic, strong) NSString *yourAppToken;
@property (nonatomic, strong) NSString *environment;
@property (nonatomic, strong) ADJConfig *adjustConfig;
@property (nonatomic, strong) ADJEvent *eventLogin;
@property (nonatomic, strong) ADJEvent *event;
@property (nonatomic, assign) TriggerEvent triggerEvent;

-(void)configAdjust;
-(void)subsessionEnd;
-(void)subsessionStart;
-(void)trackLogin;
-(void)trackEvent:(TriggerEvent)event;

@end

NS_ASSUME_NONNULL_END
