part of 'landing_bloc.dart';

abstract class LandingEvents {}

class LandingStartEvent extends LandingEvents {}

class LandingNavigationEvent extends LandingEvents {
  LandingNavigationEvent({required this.navbarType});

  final NavbarType navbarType;
}
