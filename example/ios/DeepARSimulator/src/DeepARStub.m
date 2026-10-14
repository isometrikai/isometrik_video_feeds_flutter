#import "DeepAR.h"
#import "CameraController.h"

// Simulator stand-in for the device-only DeepAR binary.
// Method bodies are no-ops so the example app can link and launch.
// AR effects still require a physical iPhone.

@implementation DeepAR

- (void)setLicenseKey:(NSString *)key {
}

- (UIView *)createARViewWithFrame:(CGRect)frame {
  return [[UIView alloc] initWithFrame:frame];
}

- (void)shutdown {
}

- (void)changeLiveMode:(BOOL)liveMode {
}

- (void)startVideoRecordingWithOutputWidth:(int)outputWidth outputHeight:(int)outputHeight {
}

- (void)startVideoRecordingWithOutputWidth:(int)outputWidth
                              outputHeight:(int)outputHeight
                                  subframe:(CGRect)subframe {
}

- (void)startVideoRecordingWithOutputWidth:(int)outputWidth
                              outputHeight:(int)outputHeight
                                  subframe:(CGRect)subframe
                videoCompressionProperties:(NSDictionary *)videoCompressionProperties {
}

- (void)startVideoRecordingWithOutputWidth:(int)outputWidth
                              outputHeight:(int)outputHeight
                                  subframe:(CGRect)subframe
                videoCompressionProperties:(NSDictionary *)videoCompressionProperties
                               recordAudio:(BOOL)recordAudio {
}

- (void)switchEffectWithSlot:(NSString *)slot path:(NSString *)path {
}

- (void)switchEffectWithSlot:(NSString *)slot path:(NSString *)path face:(NSInteger)face {
}

- (void)switchEffectWithSlot:(NSString *)slot
                        path:(NSString *)path
                        face:(NSInteger)face
            targetGameObject:(NSString *)targetGameObject {
}

- (void)switchEffectWithSlot:(NSString *)slot data:(NSData *)data {
}

- (void)switchEffectWithSlot:(NSString *)slot data:(NSData *)data face:(NSInteger)face {
}

- (void)takeScreenshot {
}

- (void)finishVideoRecording {
}

- (void)fireTrigger:(NSString *)trigger {
}

- (void)showStats:(BOOL)enabled {
}

- (void)simulatePhysics:(BOOL)enabled {
}

- (void)showColliders:(BOOL)enabled {
}

- (void)changeParameter:(NSString *)gameObject
              component:(NSString *)component
              parameter:(NSString *)parameter
             floatValue:(float)value {
}

- (void)changeParameter:(NSString *)gameObject
              component:(NSString *)component
              parameter:(NSString *)parameter
            vectorValue:(Vector4)value {
}

- (void)changeParameter:(NSString *)gameObject
              component:(NSString *)component
              parameter:(NSString *)parameter
           vector3Value:(Vector3)value {
}

- (void)changeParameter:(NSString *)gameObject
              component:(NSString *)component
              parameter:(NSString *)parameter
              boolValue:(BOOL)value {
}

- (void)changeParameter:(NSString *)gameObject
              component:(NSString *)component
              parameter:(NSString *)parameter
                  image:(UIImage *)image {
}

- (void)changeParameter:(NSString *)gameObject
              component:(NSString *)component
              parameter:(NSString *)parameter
            stringValue:(NSString *)value {
}

- (void)moveGameObject:(NSString *)selectedGameObjectName
    targetGameObjectname:(NSString *)targetGameObjectName {
}

@end

@implementation CameraController

- (void)checkCameraPermission {
}

- (void)checkMicrophonePermission {
}

- (void)startCamera {
}

- (void)startCameraWithAudio:(BOOL)audio {
}

- (void)stopCamera {
}

- (void)startAudio {
}

- (void)stopAudio {
}

@end
