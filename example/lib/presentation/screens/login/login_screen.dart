import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart'; // Adjust the import based on your project structure
import 'package:ism_video_reel_player_example/res/res.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController mobileController = TextEditingController();
  var countryCode = '+${DefaultValues.defaultCountryDialCode}';
  String? errorMessage;
  bool isMobileValid = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(StartLoginEvent());
    mobileController.addListener(_validateMobile);
  }

  @override
  void dispose() {
    mobileController.removeListener(_validateMobile);
    mobileController.dispose();
    super.dispose();
  }

  void _validateMobile() {
    final mobileNumber = mobileController.text;
    // Simple validation for mobile number (10 digits)
    if (mobileNumber.isEmpty || !RegExp(r'^[0-9]{10}$').hasMatch(mobileNumber)) {
      setState(() {
        errorMessage = 'Please enter a valid mobile number (10 digits)';
        isMobileValid = false;
      });
    } else {
      setState(() {
        errorMessage = null;
        isMobileValid = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set the status bar color
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.blueAccent,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Flutter Logo
                  const AppImage.svg(AssetConstants.icAppLogo),
                  const SizedBox(height: 20),
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: IntlPhoneField(
                          controller: mobileController,
                          decoration: InputDecoration(
                            labelText: 'Mobile Number',
                            labelStyle: const TextStyle(color: Colors.blueAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.blueAccent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            errorText: errorMessage, // Show error message
                          ),
                          initialCountryCode: DefaultValues.defaultCountryIsoCode, // Set default country code
                          onChanged: (phone) {
                            // Handle phone number change
                            countryCode = phone.countryCode;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isMobileValid
                        ? () {
                            context.read<AuthBloc>().add(LoginEvent(
                                isLoading: true, mobileNumber: mobileController.text, countryCode: countryCode));
                          }
                        : null, // Disable button if mobile is not valid
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Send OTP',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
