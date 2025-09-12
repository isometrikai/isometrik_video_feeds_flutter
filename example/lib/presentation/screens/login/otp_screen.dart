import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    Key? key,
    required this.mobile,
    required this.otpId,
    required this.loginType,
    required this.countryCode,
  }) : super(key: key);
  final String mobile;
  final String otpId;
  final String loginType;
  final String countryCode;

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  int _start = 60;
  late Timer _timer;
  bool isOtpValid = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    otpController.addListener(_validateOtp);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void _validateOtp() {
    final otp = otpController.text;
    setState(() {
      isOtpValid = otp.length == 4 &&
          RegExp(r'^\d{4}$').hasMatch(otp); // Enable button if OTP is 4 digits
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    otpController.removeListener(_validateOtp);
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set the status bar color
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.blueAccent,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Enter OTP'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'We have sent an OTP to your mobile number',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.mobile,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: otpController,
                  decoration: InputDecoration(
                    labelText: 'OTP',
                    labelStyle: const TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4, // Limit input to 4 digits
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isOtpValid
                      ? () {
                          context.read<AuthBloc>().add(
                                VerifyOtpEvent(
                                  isLoading: true,
                                  mobileNumber: widget.mobile,
                                  otp: otpController.text,
                                  otpId: widget.otpId,
                                ),
                              );
                        }
                      : null, // Disable button if OTP is not valid
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Verify OTP',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Resend OTP in $_start seconds'),
                if (_start == 0)
                  TextButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(SendOtpEvent(
                          isLoading: true, mobileNumber: widget.mobile));
                      setState(() {
                        _start = 60; // Reset timer
                        _startTimer(); // Restart timer
                      });
                    },
                    child: const Text('Resend OTP',
                        style: TextStyle(color: Colors.blueAccent)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
