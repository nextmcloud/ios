//
//  AdjustHelper.h
//  Nextcloud
//
//  Created by A200073704 on 17/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <Adjust.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    Login,
    LoginSuccessful,
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
