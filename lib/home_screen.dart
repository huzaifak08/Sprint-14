import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int currentSprint = 1;
  final int totalSprints = 14;
  int secondsRemaining = 60;
  bool isActive = false;
  bool isPaused = false;
  Timer? timer;

  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
  }

  void startSprint() {
    setState(() {
      isActive = true;
      isPaused = false;
    });

    _rotationController.forward(from: _rotationController.value);

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
      } else {
        handleSprintComplete();
      }
    });
  }

  void pauseSprint() {
    timer?.cancel();
    _rotationController.stop();
    setState(() {
      isPaused = true;
    });
  }

  void stopSprint() {
    timer?.cancel();
    _rotationController.reset();
    setState(() {
      isActive = false;
      isPaused = false;
      secondsRemaining = 60;
    });
  }

  void handleSprintComplete() {
    timer?.cancel();
    _rotationController.reset();

    if (currentSprint < totalSprints) {
      setState(() {
        currentSprint++;
        isActive = false;
        isPaused = false;
        secondsRemaining = 60;
      });
      _showSprintCompleteDialog();
    } else {
      setState(() {
        isActive = false;
        isPaused = false;
        secondsRemaining = 60;
      });
      _showAllDoneDialog();
    }
  }

  void _showSprintCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A73E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Sprint Complete!",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Ready for Sprint $currentSprint?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "LET'S GO",
              style: TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllDoneDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A73E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Mission Accomplished",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "You have completed all 14 sprints!",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => currentSprint = 1);
              Navigator.pop(context);
            },
            child: const Text(
              "RESTART",
              style: TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4285F4), Color(0xFF1A73E8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Beautiful Header with Logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "SPRINT $currentSprint OF $totalSprints",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Progress Area
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Mirrored clockwise progress
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                          value: secondsRemaining / 60,
                          strokeWidth: 12,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Rotating Rocket
                    RotationTransition(
                      turns: _rotationController,
                      child: const SizedBox(
                        width: 300,
                        height: 300,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Icon(
                            Icons.rocket_launch,
                            color: Colors.orangeAccent,
                            size: 48,
                          ),
                        ),
                      ),
                    ),

                    // Countdown Text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$secondsRemaining",
                          style: const TextStyle(
                            fontSize: 90,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "SECONDS",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 3,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isActive)
                      _buildActionButton(
                        label: "LAUNCH SPRINT",
                        color: Colors.orangeAccent,
                        onPressed: startSprint,
                        width: 220,
                      )
                    else ...[
                      _buildActionButton(
                        label: isPaused ? "RESUME" : "PAUSE",
                        color: Colors.white,
                        textColor: const Color(0xFF1A73E8),
                        onPressed: isPaused ? startSprint : pauseSprint,
                      ),
                      const SizedBox(width: 20),
                      _buildActionButton(
                        label: "ABORT",
                        color: Colors.redAccent.withOpacity(0.9),
                        onPressed: stopSprint,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    Color textColor = Colors.white,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          elevation: 10,
          shadowColor: Colors.black38,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }
}
