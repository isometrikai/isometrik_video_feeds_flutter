#include "include/ism_video_reel_player/ism_video_reel_player_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ism_video_reel_player_plugin.h"

void IsmVideoReelPlayerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ism_video_reel_player::IsmVideoReelPlayerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
