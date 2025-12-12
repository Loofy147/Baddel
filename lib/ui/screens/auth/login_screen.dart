import 'package:baddel/core/services/auth_service.dart';
import 'package:baddel/core/validators/input_validator.dart';
import 'package:baddel/ui/screens/deck/home_deck_screen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();

  bool _codeSent = false;
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final phone = _phoneController.text.trim(); // Format: +213xxxxxxxxx

      try {
        if (!_codeSent) {
          // STEP 1: Send SMS
          await _authService.signInWithPhone(phone);
          setState(() => _codeSent = true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📩 Code Sent! Check SMS.")));
        } else {
          // STEP 2: Verify Code
          await _authService.verifyOtp(phone, _otpController.text.trim());
          // Success -> Go Home
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeDeckScreen()));
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("BADDEL.", style: TextStyle(color: Color(0xFF2962FF), fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 10),
              Text(
                  _codeSent ? "Enter the 6-digit code" : "Swap. Buy. Sell.\nEnter phone to start.",
                  style: const TextStyle(color: Colors.grey, fontSize: 18)),
              const SizedBox(height: 40),

              // INPUT FIELD
              TextFormField(
                controller: _codeSent ? _otpController : _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 22),
                decoration: InputDecoration(
                  labelText: _codeSent ? "OTP Code" : "Phone Number",
                  hintText: _codeSent ? "123456" : "+213 555...",
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2962FF))),
                ),
                validator: _codeSent ? InputValidator.validateOtp : InputValidator.validatePhone,
              ),

              const SizedBox(height: 40),

              // ACTION BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_codeSent ? "VERIFY & ENTER" : "GET CODE", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
