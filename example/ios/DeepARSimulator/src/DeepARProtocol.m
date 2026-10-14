#import <Foundation/Foundation.h>

// Emits _OBJC_PROTOCOL_$_DeepARDelegate for the simulator stub.
// The real DeepAR.framework binary is device-only, so this symbol has to
// come from the stub when the plugin is linked for the simulator.
@protocol DeepARDelegate <NSObject>
@optional
- (void)didInitialize;
@end

@interface DeepARProtocolAnchor : NSObject <DeepARDelegate>
@end

@implementation DeepARProtocolAnchor

- (void)didInitialize {
}

@end

__attribute__((used)) static Protocol *DeepARDelegateProtocol(void) {
  return @protocol(DeepARDelegate);
}
