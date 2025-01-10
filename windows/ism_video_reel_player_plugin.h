#ifndef FLUTTER_PLUGIN_ISM_VIDEO_REEL_PLAYER_PLUGIN_H_
#define FLUTTER_PLUGIN_ISM_VIDEO_REEL_PLAYER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace ism_video_reel_player {

class IsmVideoReelPlayerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  IsmVideoReelPlayerPlugin();

  virtual ~IsmVideoReelPlayerPlugin();

  // Disallow copy and assign.
  IsmVideoReelPlayerPlugin(const IsmVideoReelPlayerPlugin&) = delete;
  IsmVideoReelPlayerPlugin& operator=(const IsmVideoReelPlayerPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace ism_video_reel_player

#endif  // FLUTTER_PLUGIN_ISM_VIDEO_REEL_PLAYER_PLUGIN_H_
