import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart' as isr;
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';

class ProfileView extends StatefulWidget {
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    InjectionUtils.getBloc<ProfileBloc>().add(InitializeProfileEvent());
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) => ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Profile Tile
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View Profile'),
                onTap: () {
                  // Handle view profile action
                },
              ),
              const Divider(),

              // creat post Tile
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create Post'),
                onTap: () {
                  _createPost(context);
                },
              ),
              const Divider(),

              // scheduled post listing Tile
              ListTile(
                leading: const Icon(Icons.timelapse),
                title: const Text('Scheduled Posts'),
                onTap: () {
                  _schedulePostListing(context);
                },
              ),
              const Divider(),

              // Settings Tile
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  // Handle settings action
                },
              ),
              const Divider(),

              // Help Tile
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                onTap: () {
                  // Handle help action
                },
              ),
              const Divider(),

              // Logout Tile
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title:
                    const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () {
                  // Handle logout action
                  _showLogoutConfirmation(context);
                },
              ),
            ],
          ));

  void _createPost(BuildContext context) {
    isr.IsrAppNavigator.goToCreatePostView(context);
  }

  void _schedulePostListing(BuildContext context) {
    isr.IsrAppNavigator.navigateToSchedulePostListing(context);
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Colors.blue, backgroundColor: Colors.white),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Colors.red, backgroundColor: Colors.white),
            onPressed: () {
              InjectionUtils.getBloc<ProfileBloc>().add(LogoutEvent());
              // Handle logout logic here
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
