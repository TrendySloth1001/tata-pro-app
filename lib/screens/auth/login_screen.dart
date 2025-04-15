import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:math' as math;
import '../main_container.dart';
import '../../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _rememberMe = false;
  bool _canCheckBiometrics = false;

  // Add new variables for electron control
  bool _electronsDirected = false;
  final List<Electron> _electrons = List.generate(20, (index) => Electron());
  late AnimationController _electronAnimationController;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _electronAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..repeat();

    // Start animations
    _controller.forward();
    
    // Initialize electron positions
    for (var electron in _electrons) {
      electron.position = Offset(
        math.Random().nextDouble() * 400,
        math.Random().nextDouble() * 800,
      );
    }

    // Initialize biometrics with error handling
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics.timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      if (mounted) {
        setState(() => _canCheckBiometrics = canCheck);
      }
    } catch (e) {
      debugPrint('Error initializing biometrics: $e');
      if (mounted) {
        setState(() => _canCheckBiometrics = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _electronAnimationController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainContainer()),
        );
      }
    } on PlatformException catch (e) {
      debugPrint('Error using biometrics: $e');
    }
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainContainer()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Electron Layer
          AnimatedBuilder(
            animation: _electronAnimationController,
            builder: (context, child) {
              _updateElectrons();
              return CustomPaint(
                size: Size.infinite,
                painter: ElectronPainter(
                  electrons: _electrons,
                  directed: false, // Always false now
                ),
              );
            },
          ),
          // Existing Login Content
          SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.darkPrimaryColor.withOpacity(0.2),
                    AppTheme.backgroundColor,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: FadeTransition(
                    opacity: _fadeInAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 40),
                        _buildLoginForm(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateElectrons() {
    final size = MediaQuery.of(context).size;
    final random = math.Random();

    for (var electron in _electrons) {
      // Random movement
      electron.position = Offset(
        electron.position.dx + (random.nextDouble() - 0.5) * 2,
        electron.position.dy + (random.nextDouble() - 0.5) * 2,
      );

      // Wrap around screen
      if (electron.position.dy < -20) electron.position = Offset(electron.position.dx, size.height + 20);
      if (electron.position.dy > size.height + 20) electron.position = Offset(electron.position.dx, -20);
      if (electron.position.dx < -20) electron.position = Offset(size.width + 20, electron.position.dy);
      if (electron.position.dx > size.width + 20) electron.position = Offset(-20, electron.position.dy);
    }
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.darkSecondaryColor.withOpacity(0.5),
              width: 2,
            ),
            gradient: RadialGradient(
              colors: [
                AppTheme.darkSecondaryColor.withOpacity(0.2),
                AppTheme.backgroundColor.withOpacity(0.1),
              ],
            ),
          ),
          child: Icon(
            Icons.electric_bolt,
            size: 48,
            color: AppTheme.darkSecondaryColor,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'TATA',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
            color: Colors.white,
          ),
        ),
        Text(
          'Smart Grid',
          style: TextStyle(
            fontSize: 20,
            color: AppTheme.darkSecondaryColor,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 30.0, end: 0.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkSecondaryColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAnimatedHeader(),
                const SizedBox(height: 24),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                _buildRememberMeRow(),
                _buildForgotPasswordButton(),
                const SizedBox(height: 24),
                _buildLoginButton(),
                if (_canCheckBiometrics) _buildBiometricButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedHeader() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkSecondaryColor,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(
          Icons.email_outlined,
          color: AppTheme.darkSecondaryColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(
          Icons.lock_outline,
          color: AppTheme.darkSecondaryColor,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: AppTheme.darkSecondaryColor,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildRememberMeRow() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) => setState(() => _rememberMe = value!),
          checkColor: Colors.black,
          fillColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? AppTheme.darkSecondaryColor
                : Colors.transparent,
          ),
        ),
        const Text(
          'Remember Me',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () {
        // Add forgot password flow
        showDialog(
          context: context,
          builder: (context) => _buildForgotPasswordDialog(),
        );
      },
      child: Text(
        'Forgot Password?',
        style: TextStyle(
          color: AppTheme.darkSecondaryColor,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return FilledButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.darkSecondaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildBiometricButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: OutlinedButton.icon(
        onPressed: _authenticateWithBiometrics,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: AppTheme.darkSecondaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.fingerprint),
        label: const Text('Login with Biometrics'),
      ),
    );
  }

  AlertDialog _buildForgotPasswordDialog() {
    return AlertDialog(
      backgroundColor: AppTheme.backgroundColor,
      title: Row(
        children: [
          Icon(Icons.lock_reset, color: AppTheme.darkSecondaryColor),
          const SizedBox(width: 8),
          const Text('Reset Password'),
        ],
      ),
      content: TextField(
        decoration: InputDecoration(
          labelText: 'Email Address',
          prefixIcon: Icon(
            Icons.email_outlined,
            color: AppTheme.darkSecondaryColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            // Implement password reset
            Navigator.pop(context);
            _showResetEmailSentDialog();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.darkSecondaryColor,
          ),
          child: const Text('Send Reset Link'),
        ),
      ],
    );
  }

  void _showResetEmailSentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: Icon(
          Icons.mark_email_read,
          color: AppTheme.darkSecondaryColor,
          size: 48,
        ),
        content: const Text(
          'Password reset link has been sent to your email address.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.darkSecondaryColor,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class Electron {
  Offset position;
  double size;

  Electron()
      : position = Offset.zero,
        size = math.Random().nextDouble() * 2 + 1;
}

class ElectronPainter extends CustomPainter {
  final List<Electron> electrons;
  final bool directed; // Keep for compatibility

  ElectronPainter({required this.electrons, required this.directed});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connections first
    _drawConnections(canvas, size);
    
    // Then draw electrons
    for (var electron in electrons) {
      _drawElectron(canvas, electron);
    }
  }

  void _drawConnections(Canvas canvas, Size size) {
    const maxDistance = 150.0; // Maximum distance for connection
    
    for (int i = 0; i < electrons.length; i++) {
      for (int j = i + 1; j < electrons.length; j++) {
        final distance = (electrons[i].position - electrons[j].position).distance;
        
        if (distance < maxDistance) {
          // Calculate opacity based on distance
          final opacity = (1 - (distance / maxDistance)) * 0.5;
          
          // Draw connection line with glow
          final paint = Paint()
            ..color = AppTheme.darkSecondaryColor.withOpacity(opacity * 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

          canvas.drawLine(
            electrons[i].position,
            electrons[j].position,
            paint,
          );
          
          // Draw actual line
          paint
            ..color = AppTheme.darkSecondaryColor.withOpacity(opacity)
            ..maskFilter = null
            ..strokeWidth = 0.5;

          canvas.drawLine(
            electrons[i].position,
            electrons[j].position,
            paint,
          );
        }
      }
    }
  }

  void _drawElectron(Canvas canvas, Electron electron) {
    // Draw glow
    final glowPaint = Paint()
      ..color = AppTheme.darkSecondaryColor.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    canvas.drawCircle(electron.position, electron.size * 3, glowPaint);
    
    // Draw electron
    final paint = Paint()
      ..color = AppTheme.darkSecondaryColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(electron.position, electron.size, paint);
  }

  @override
  bool shouldRepaint(covariant ElectronPainter oldDelegate) => true;
}
