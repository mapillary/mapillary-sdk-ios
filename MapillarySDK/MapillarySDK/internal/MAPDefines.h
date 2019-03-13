//
//  MAPDefines.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#ifndef MAPDefines_h
#define MAPDefines_h

#define AWS_COGNITO_IDENTITY_POOL_ID        @"eu-west-1:57d09467-4c2f-470d-9577-90d3f89f76a1"

#define MAPILLARY_CLIENT_ID                 @"MapillaryClientId"
#define MAPILLARY_CLIENT_CALLBACK_URL       @"MapillaryCallbackUrl"

#define MAPILLARY_KEYCHAIN_SERVICE          @"MapillaryKeychainService"
#define MAPILLARY_KEYCHAIN_ACCOUNT          @"MapillaryKeychainAccount"
#define MAPILLARY_CURRENT_USER_NAME         @"MapillaryCurrentUserName"
#define MAPILLARY_CURRENT_USER_EMAIL        @"MapillaryCurrentUserEmail"
#define MAPILLARY_CURRENT_USER_KEY          @"MapillaryCurrentUserKey"

// Sequence
#define kMAPAppNameString                   @"MAPAppNameString"
#define kMAPDeviceMake                      @"MAPDeviceMake"
#define kMAPDeviceModel                     @"MAPDeviceModel"
#define kMAPDeviceUUID                      @"MAPDeviceUUID"
#define kMAPDirectionOffset                 @"MAPDirectionOffset"
#define kMAPLocalTimeZone                   @"MAPLocalTimeZone"
#define kMAPOrganizationKey                 @"MAPOrganizationKey"
#define kMAPPrivate                         @"MAPPrivate"
#define kMAPRigSequenceUUID                 @"MAPRigSequenceUUID"
#define kMAPRigUUID                         @"MAPRigUUID"
#define kMAPSettingsUserKey                 @"MAPSettingsUserKey"
#define kMAPSequenceUUID                    @"MAPSequenceUUID"
#define kMAPTimeOffset                      @"MAPTimeOffset"
#define kMAPVersionString                   @"MAPVersionString"

// Image/location
#define kMAPLatitude                        @"MAPLatitude"
#define kMAPLongitude                       @"MAPLongitude"
#define kMAPAltitude                        @"MAPAltitude"
#define kMAPCaptureTime                     @"MAPCaptureTime"
#define kMAPGpsTime                         @"MAPGpsTime"
#define kMAPAccelerometerVector             @"MAPAccelerometerVector"
#define kMAPGPSAccuracyMeters               @"MAPGPSAccuracyMeters"
#define kMAPAtanAngle                       @"MAPAtanAngle"
#define kMAPCompassHeading                  @"MAPCompassHeading"
#define kMAPTrueHeading                     @"TrueHeading"
#define kMAPMagneticHeading                 @"MagneticHeading"
#define kMAPAccuracyDegrees                 @"AccuracyDegrees"
#define kMAPDeviceAngle                     @"MAPDeviceAngle"
#define kMAPGPSSpeed                        @"MAPGPSSpeed"

// At export
#define kMAPSettingsUploadHash              @"MAPSettingsUploadHash"
#define kMAPPhotoUUID                       @"MAPPhotoUUID"

// Used?
#define kMAPSettingsTokenValid              @"MAPSettingsTokenValid"

// API
#define kMAPSettingStaging                  @"MAPSettingStaging"
#define kMAPAPIEndpoint                     @"https://a.mapillary.com"
#define kMAPAPIEndpointStaging              @"http://staging.mapillary.io:8080"
#define kMAPAuthEndpoint                    @"https://www.mapillary.com"
#define kMAPAuthEndpointStaging             @"http://staging.mapillary.io:3002"
#define kMAPRedirectURLStaging              @"http://staging.mapillary.io:3000"
#define kMAPClientIdStaging                 @"YWFhYWFhYWFhYWFhYWFhYWFhYWFhYTphcHBfYQ=="

#endif /* MAPDefines_h */
