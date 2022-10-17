#import "CustomImageEditorPlugin.h"
#if __has_include(<custom_image_editor/custom_image_editor-Swift.h>)
#import <custom_image_editor/custom_image_editor-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "custom_image_editor-Swift.h"
#endif

@implementation CustomImageEditorPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCustomImageEditorPlugin registerWithRegistrar:registrar];
}
@end
