import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class NavItemCubit extends Cubit<NavbarType> {
  NavItemCubit() : super(NavbarType.home);

  void onTap(NavbarType type, {bool? isFirstTime = false}) {
    emit(type);
    InjectionUtils.getRouteManagement().goToNavItem(type, isFirstTime!);
  }
}
