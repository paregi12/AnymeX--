import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for SystemNavigator
import '../services/local_auth_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final bool isSettingPin;

  const LockScreen({
    super.key, 
    required this.onUnlock, 
    this.isSettingPin = false
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = "";
  
  void _onKeyPress(String value) async {
    setState(() {
      if (_pin.length < 4) _pin += value;
    });

    if (_pin.length == 4) {
      if (widget.isSettingPin) {
        // Case 1: Creating a NEW PIN
        await LocalAuthService().setPin(_pin);
        widget.onUnlock();
      } else {
        // Case 2: Unlocking the App
        bool isValid = await LocalAuthService().verifyPin(_pin);
        if (isValid) {
          widget.onUnlock();
        } else {
          // Wrong PIN: Shake effect or Clear
          setState(() => _pin = "");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Wrong PIN"), 
              backgroundColor: Colors.red,
              duration: Duration(milliseconds: 500),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope ensures the user cannot press "Back" to bypass the lock
    return PopScope(
      canPop: false, // PREVENT BACK BUTTON
      onPopInvoked: (didPop) {
        if (didPop) return;
        // If they try to go back while locked, minimize/close the app instead
        if (!widget.isSettingPin) {
           SystemNavigator.pop(); 
        } else {
           // If they are just in Settings trying to set it up, let them go back
           Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black, // Dark mode matches AnymeX
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isSettingPin ? Icons.lock_open : Icons.lock, 
                size: 60, 
                color: Colors.white
              ),
              const SizedBox(height: 30),
              Text(
                widget.isSettingPin ? "Create Passcode" : "Enter Passcode",
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 30),
              
              // The Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 15, height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length ? Colors.blueAccent : Colors.grey[800],
                  ),
                )),
              ),
              const SizedBox(height: 50),
              
              // The Numpad
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: 12, // 0-9, empty, delete
                  itemBuilder: (context, index) {
                    if (index == 9) return const SizedBox(); // Empty left of 0
                    if (index == 11) { // Delete button
                      return IconButton(
                        icon: const Icon(Icons.backspace_outlined, color: Colors.white),
                        onPressed: () {
                          if (_pin.isNotEmpty) {
                            setState(() => _pin = _pin.substring(0, _pin.length - 1));
                          }
                        },
                      );
                    }
                    // Numbers
                    String num = (index == 10) ? "0" : "${index + 1}";
                    return TextButton(
                      onPressed: () => _onKeyPress(num),
                      style: TextButton.styleFrom(shape: const CircleBorder()),
                      child: Text(num, style: const TextStyle(fontSize: 26, color: Colors.white)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
