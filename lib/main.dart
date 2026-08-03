import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyCAS7hjqo9H2Xe0lX5d8o74Qcpv7o5yoGw",
    authDomain: "overthinker-companion-8c4fc.firebaseapp.com",
    projectId: "overthinker-companion-8c4fc",
    storageBucket: "overthinker-companion-8c4fc.firebasestorage.app",
    messagingSenderId: "579088854719",
    appId: "1:579088854719:web:c7704b850c11c80bae600a",
    measurementId: "G-05B9GQNWJY",
  );

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(options: firebaseOptions);
    } else {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint("Default Firebase initialization failed, falling back to programmatic options: $e");
        await Firebase.initializeApp(options: firebaseOptions);
      }
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(const OverthinkerApp());
}

enum CompanionPersona {
  empatheticListener('Empathetic Listener', '🤗', 'Gentle, supportive, and active listener.'),
  mindfulnessMentor('Mindfulness Mentor', '🧘‍♂️', 'Calming guidance focused on present moment awareness.'),
  cbtAnalyst('CBT Thought Analyst', '🧠', 'Structured questions to challenge cognitive distortions.'),
  stoicGuide('Wise Stoic Guide', '🏛️', 'Rational perspectives on focusing only on what you can control.');

  final String name;
  final String avatar;
  final String description;

  const CompanionPersona(this.name, this.avatar, this.description);
}

class OverthinkerApp extends StatelessWidget {
  const OverthinkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Overthinker Companion',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF9C89B8),
          secondary: Color(0xFFF0E6EF),
          tertiary: Color(0xFF7A7287),
          surface: Color(0xFFFFFFFF),
          onSurface: Colors.black,
          primaryContainer: Color(0xFFF0E6EF),
          onPrimaryContainer: Colors.black,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// =============================================================================
// AUTH GATE — routes to Login or Main App based on auth state
// =============================================================================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const MainNavigationScaffold();
        }
        return const LoginScreen();
      },
    );
  }
}

// =============================================================================
// LOGIN SCREEN
// =============================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _authErrorMessage(e.code);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password. Please try again.';
      case 'invalid-credential': return 'Invalid email or password.';
      case 'user-disabled': return 'This account has been disabled.';
      case 'too-many-requests': return 'Too many attempts. Please try again later.';
      default: return 'Login failed. Please check your details.';
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    bool isSending = false;
    String? resetError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF0E6EF), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF9C89B8)),
                  ),
                  const SizedBox(width: 10),
                  Text('Reset Password', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your registered email address and we\'ll send you a password reset link.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF7A7287)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(color: Color(0xFF7A7287), fontSize: 13),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF9C89B8), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF9F7FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFF0E6EF))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFF0E6EF))),
                    ),
                  ),
                  if (resetError != null) ...[
                    const SizedBox(height: 8),
                    Text(resetError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7A7287))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C89B8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty || !RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(email)) {
                            setModalState(() => resetError = 'Please enter a valid email address.');
                            return;
                          }
                          setModalState(() { isSending = true; resetError = null; });
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Password reset link sent! Check your email inbox and Spam/Junk folder. 📧', style: TextStyle(color: Colors.black)),
                                backgroundColor: Color(0xFFF0E6EF),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            setModalState(() {
                              isSending = false;
                              resetError = e.message ?? 'Failed to send reset email.';
                            });
                          } catch (e) {
                            setModalState(() {
                              isSending = false;
                              resetError = 'An error occurred. Please try again.';
                            });
                          }
                        },
                  child: isSending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Send Link', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Branding
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF9C89B8).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/Overthinker Comanion.png',
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/logo.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: const Color(0xFF9C89B8),
                          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 48),
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn().scale(),
                const SizedBox(height: 20),
                Text(
                  'Overthinker Companion',
                  style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 6),
                Text(
                  'Your safe space to breathe and be heard.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF7A7287)),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 36),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _AuthField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(v.trim())) return 'Enter a valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF9C89B8), size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF9C89B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                            ],
                          ),
                        ).animate().fadeIn().shakeX(),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9C89B8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isLoading ? null : _signIn,
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Sign In', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE0D8EC))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7A7287), fontSize: 13)),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE0D8EC))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9C89B8),
                      side: const BorderSide(color: Color(0xFF9C89B8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: Text('Create an Account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SIGNUP SCREEN
// =============================================================================
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _selectedFaith = 'Islam';
  final List<String> _faithOptions = [
    'Islam',
    'Christianity',
    'Hinduism',
    'Buddhism',
    'Judaism',
    'Spiritual / Universal',
  ];

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await credential.user?.updateDisplayName(_nameController.text.trim());
      // Save user profile with age & faith to Firestore
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'faith': _selectedFaith,
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _authErrorMessage(e.code);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return 'An account already exists with this email.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'weak-password': return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed': return 'Email/password signup is not enabled.';
      default: return 'Signup failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF9C89B8)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Create Account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome! 🌸',
                style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
              ).animate().fadeIn().slideX(begin: -0.2),
              const SizedBox(height: 6),
              Text(
                'Create your private companion account.',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF7A7287)),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _AuthField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Name is required';
                        if (v.trim().length < 2) return 'Name must be at least 2 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _AuthField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Age is required';
                        final age = int.tryParse(v.trim());
                        if (age == null || age < 10 || age > 120) return 'Please enter a valid age (10-120)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // Faith Selection Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF0E6EF)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedFaith,
                          decoration: const InputDecoration(
                            labelText: 'Faith / Spiritual Background',
                            labelStyle: TextStyle(color: Color(0xFF7A7287), fontSize: 14),
                            prefixIcon: Icon(Icons.auto_awesome_rounded, color: Color(0xFF9C89B8), size: 20),
                            border: InputBorder.none,
                          ),
                          items: _faithOptions.map((faith) {
                            String emoji = '🌿';
                            if (faith == 'Islam') emoji = '🕌';
                            if (faith == 'Christianity') emoji = '✝️';
                            if (faith == 'Hinduism') emoji = '🕉️';
                            if (faith == 'Buddhism') emoji = '☸️';
                            if (faith == 'Judaism') emoji = '✡️';
                            return DropdownMenuItem(
                              value: faith,
                              child: Text('$emoji  $faith', style: GoogleFonts.plusJakartaSans(color: Colors.black, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedFaith = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AuthField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(v.trim())) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _AuthField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF9C89B8), size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include at least one uppercase letter';
                        if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _AuthField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF9C89B8), size: 20),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your password';
                        if (v != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                          ],
                        ),
                      ).animate().fadeIn().shakeX(),
                    const SizedBox(height: 20),
                    // Password requirements hint
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E6EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Password must have:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF7A7287))),
                          const SizedBox(height: 4),
                          _PasswordHint(text: 'At least 6 characters', met: _passwordController.text.length >= 6),
                          _PasswordHint(text: 'One uppercase letter (A-Z)', met: RegExp(r'[A-Z]').hasMatch(_passwordController.text)),
                          _PasswordHint(text: 'One number (0-9)', met: RegExp(r'[0-9]').hasMatch(_passwordController.text)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C89B8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isLoading ? null : _signUp,
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Create Account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Already have an account? Sign In', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF9C89B8), fontSize: 14)),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable styled auth text field
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.black, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7A7287), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF9C89B8), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF0E6EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF0E6EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF9C89B8), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}

// Password requirement hint row
class _PasswordHint extends StatelessWidget {
  final String text;
  final bool met;
  const _PasswordHint({required this.text, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 14, color: met ? const Color(0xFF9C89B8) : Colors.grey),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: met ? const Color(0xFF9C89B8) : Colors.grey)),
        ],
      ),
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;
  CompanionPersona _selectedPersona = CompanionPersona.empatheticListener;

  final List<Map<String, dynamic>> _moodLogs = [
    {'day': 'Mon', 'mood': 'Calm', 'level': 8, 'streak': 1},
    {'day': 'Tue', 'mood': 'Overthinking', 'level': 4, 'streak': 2},
    {'day': 'Wed', 'mood': 'Peaceful', 'level': 9, 'streak': 3},
    {'day': 'Thu', 'mood': 'Anxious', 'level': 3, 'streak': 4},
    {'day': 'Today', 'mood': 'Calm', 'level': 7, 'streak': 5},
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        moodLogs: _moodLogs,
        onMoodLogged: (mood, level) {
          setState(() {
            _moodLogs.add({
              'day': 'Today',
              'mood': mood,
              'level': level,
              'streak': _moodLogs.last['streak'] + 1,
            });
          });
        },
        onOpenChat: (persona) {
          setState(() {
            _selectedPersona = persona;
            _currentIndex = 1; // Switch to AI Chat tab
          });
        },
        onOpenTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      ChatScreen(
        currentPersona: _selectedPersona,
        onBack: () {
          setState(() {
            _currentIndex = 0; // Return to Home
          });
        },
        onPersonaChanged: (persona) {
          setState(() {
            _selectedPersona = persona;
          });
        },
      ),
      const GroundingAndBreathingScreen(),
      const SupportWallScreen(),
      const PrivateVaultScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFF0E6EF), width: 0.8)),
        ),
        child: NavigationBar(
          backgroundColor: const Color(0xFFFFFFFF),
          selectedIndex: _currentIndex,
          indicatorColor: const Color(0xFFF0E6EF),
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined, color: Color(0xFF7A7287)),
              selectedIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF9C89B8)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined, color: Color(0xFF7A7287)),
              selectedIcon: Icon(Icons.forum_rounded, color: Color(0xFF9C89B8)),
              label: 'AI Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.spa_outlined, color: Color(0xFF7A7287)),
              selectedIcon: Icon(Icons.spa_rounded, color: Color(0xFF9C89B8)),
              label: 'Grounding',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_alt_outlined, color: Color(0xFF7A7287)),
              selectedIcon: Icon(Icons.people_alt_rounded, color: Color(0xFF9C89B8)),
              label: 'Community',
            ),
            NavigationDestination(
              icon: Icon(Icons.lock_outline_rounded, color: Color(0xFF7A7287)),
              selectedIcon: Icon(Icons.lock_rounded, color: Color(0xFF9C89B8)),
              label: 'Vault',
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. HOME SCREEN WITH QUICK MOOD TRACKING
// -----------------------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> moodLogs;
  final Function(String, int) onMoodLogged;
  final Function(CompanionPersona)? onOpenChat;
  final Function(int)? onOpenTab;

  const HomeScreen({super.key, required this.moodLogs, required this.onMoodLogged, this.onOpenChat, this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/Overthinker Comanion.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/logo.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.psychology_rounded, size: 40, color: Color(0xFF9C89B8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back 👋',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF7A7287)),
                          ),
                          Text(
                            FirebaseAuth.instance.currentUser?.displayName ?? 'Overthinker Companion',
                            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Sign out button
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFF9C89B8)),
                    tooltip: 'Sign Out',
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ],
              ).animate().fadeIn().slideY(begin: -0.2),

              const SizedBox(height: 20),

              // Daily Faith Affirmation Verses Card
              const _DailyFaithAffirmationCard(),

              const SizedBox(height: 20),

              // Interactive Mood Logging Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0E6EF), Color(0xFFE8DDFB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF9C89B8).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log Your Emotional State',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track consistency & identify overthinking triggers over time',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MoodTile(emoji: '😰', label: 'Anxious', score: 3, onTap: () => _logMood(context, 'Anxious', 3)),
                        _MoodTile(emoji: '🌀', label: 'Spiraling', score: 4, onTap: () => _logMood(context, 'Spiraling', 4)),
                        _MoodTile(emoji: '😐', label: 'Neutral', score: 6, onTap: () => _logMood(context, 'Neutral', 6)),
                        _MoodTile(emoji: '🌿', label: 'Calm', score: 8, onTap: () => _logMood(context, 'Calm', 8)),
                        _MoodTile(emoji: '✨', label: 'Peaceful', score: 10, onTap: () => _logMood(context, 'Peaceful', 10)),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms).scale(),

              const SizedBox(height: 16),

              // Gamified Mind Arcade Banner
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GamifiedArcadeScreen()));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7A7287), Color(0xFF9C89B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF9C89B8).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gamified Mind Arcade 🎮', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('Bubble Popper, Thought Shredder & Mind Match', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms).slideX(),
              ),

              const SizedBox(height: 28),

              Text(
                'Self-Care Modules',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 14),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
                children: [
                  _FeatureTile(
                    title: 'Empathetic AI',
                    subtitle: 'Real-time Chat',
                    icon: Icons.psychology_rounded,
                    color: const Color(0xFF9C89B8),
                    onTap: () => onOpenTab?.call(1),
                  ),
                  _FeatureTile(
                    title: 'Mind Arcade 🎮',
                    subtitle: 'Thought Games',
                    icon: Icons.sports_esports_rounded,
                    color: const Color(0xFF9C89B8),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamifiedArcadeScreen())),
                  ),
                  _FeatureTile(
                    title: '5-4-3-2-1 Sensory',
                    subtitle: 'Grounding Technique',
                    icon: Icons.remove_red_eye_rounded,
                    color: const Color(0xFF9C89B8),
                    onTap: () => onOpenTab?.call(2),
                  ),
                  _FeatureTile(
                    title: 'Diaphragmatic',
                    subtitle: 'Breathing Routine',
                    icon: Icons.air_rounded,
                    color: const Color(0xFF9C89B8),
                    onTap: () => onOpenTab?.call(2),
                  ),
                  _FeatureTile(
                    title: 'Support Wall',
                    subtitle: 'Community Prayers',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF9C89B8),
                    onTap: () => onOpenTab?.call(3),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  void _logMood(BuildContext context, String mood, int level) {
    onMoodLogged(mood, level);
    
    CompanionPersona nextPersona;
    if (level <= 4) {
      nextPersona = CompanionPersona.cbtAnalyst; // For Anxious or Spiraling
    } else if (level <= 6) {
      nextPersona = CompanionPersona.empatheticListener; // For Neutral
    } else {
      nextPersona = CompanionPersona.mindfulnessMentor; // For Calm or Peaceful
    }

    if (onOpenChat != null) {
      onOpenChat!(nextPersona);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged "$mood" mood! AI is ready to chat. ✨', style: const TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFF0E6EF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  final String emoji;
  final String label;
  final int score;
  final VoidCallback onTap;

  const _MoodTile({required this.emoji, required this.label, required this.score, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF9C89B8).withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.black)),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _FeatureTile({required this.title, required this.subtitle, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF7A7287))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. AI COMPANION CHAT & CUSTOM PERSONA SWITCHER
// -----------------------------------------------------------------------------
class ChatScreen extends StatefulWidget {
  final CompanionPersona currentPersona;
  final ValueChanged<CompanionPersona> onPersonaChanged;
  final VoidCallback? onBack;

  const ChatScreen({super.key, required this.currentPersona, required this.onPersonaChanged, this.onBack});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _groqApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: 'YOUR_GROQ_API_KEY_HERE');
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  String get _systemPrompt {
    const languageInstruction = 'LANGUAGE & TRANSLATION RULE: You support both English and Roman Urdu / Roman Hindi (Hinglish). Automatically match the user\'s language. If the user writes in Roman Urdu/Hindi (e.g., "mujhe bohot anxiety ho rahi hai", "samajh nahi aa raha kya karoon"), reply in natural, compassionate, and comforting Roman Urdu / Hindi. If the user writes in English, reply in English.';

    switch (widget.currentPersona) {
      case CompanionPersona.empatheticListener:
        return 'You are a warm, empathetic, and non-judgmental companion for people dealing with anxiety and overthinking. '
            'Your role is to listen deeply, validate feelings, and provide gentle emotional support. '
            'You never minimize or dismiss feelings. You ask thoughtful follow-up questions to help the user feel truly heard. '
            'Speak in a calm, caring, and compassionate tone. Keep responses concise (2-4 sentences) and conversational. $languageInstruction';
      case CompanionPersona.mindfulnessMentor:
        return 'You are a mindfulness and meditation guide helping people manage anxiety and overthinking. '
            'Your role is to guide users toward present-moment awareness, breathing techniques, and grounding exercises. '
            'Use calming, gentle language. Occasionally suggest simple mindfulness practices (e.g., deep breathing, body scan). '
            'Help the user slow down their racing thoughts. Keep responses concise (2-4 sentences) and soothing. $languageInstruction';
      case CompanionPersona.cbtAnalyst:
        return 'You are a Cognitive Behavioral Therapy (CBT) thought analyst helping people challenge and reframe negative thought patterns. '
            'Your role is to ask Socratic questions to help users identify cognitive distortions (e.g., catastrophizing, all-or-nothing thinking). '
            'Guide them to examine evidence for and against their anxious thoughts and arrive at a more balanced perspective. '
            'Be structured but compassionate. Keep responses concise (2-4 sentences). $languageInstruction';
      case CompanionPersona.stoicGuide:
        return 'You are a Stoic philosopher companion inspired by Marcus Aurelius, Epictetus, and Seneca. '
            'Your role is to help users focus only on what is within their control and accept what is not. '
            'Offer rational, grounding perspectives on anxiety and overthinking using Stoic wisdom. '
            'Be calm, measured, and wise. Occasionally quote relevant Stoic maxims. Keep responses concise (2-4 sentences). $languageInstruction';
    }
  }

  @override
  void initState() {
    super.initState();
    _resetPersonaWelcome();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetPersonaWelcome() {
    _messages.clear();
    _messages.add({
      'sender': 'ai',
      'text': 'Hello! I am your ${widget.currentPersona.name} ${widget.currentPersona.avatar}. What thoughts are on your mind right now?'
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isTyping) return;
    final text = _controller.text.trim();
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    // Build conversation history for context
    final List<Map<String, String>> conversationHistory = [
      {'role': 'system', 'content': _systemPrompt},
    ];
    for (final msg in _messages) {
      if (msg['sender'] == 'user') {
        conversationHistory.add({'role': 'user', 'content': msg['text']!});
      } else if (msg['sender'] == 'ai') {
        conversationHistory.add({'role': 'assistant', 'content': msg['text']!});
      }
    }

    try {
      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': conversationHistory,
          'max_tokens': 300,
          'temperature': 0.8,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices'][0]['message']['content'] as String;
        setState(() {
          _isTyping = false;
          _messages.add({'sender': 'ai', 'text': aiText.trim()});
        });
      } else {
        setState(() {
          _isTyping = false;
          _messages.add({'sender': 'ai', 'text': 'I\'m having a little trouble connecting right now. Please try again in a moment. 💜'});
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({'sender': 'ai', 'text': 'It seems like there\'s a network issue. Please check your connection and try again.'});
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF9C89B8), size: 20),
          tooltip: 'Back to Home',
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Companion Chat', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            Text('${widget.currentPersona.avatar} ${widget.currentPersona.name}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF9C89B8))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF9C89B8)),
            tooltip: 'Switch Persona',
            onPressed: _showPersonaSelectorModal,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFFFFFFF),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CompanionPersona.values.map((persona) {
                  final isSelected = persona == widget.currentPersona;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      selectedColor: const Color(0xFF9C89B8),
                      backgroundColor: const Color(0xFFF0E6EF),
                      label: Text('${persona.avatar} ${persona.name}'),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        widget.onPersonaChanged(persona);
                        setState(() {
                          _resetPersonaWelcome();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                // Typing indicator bubble
                if (_isTyping && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(18),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                        ],
                        border: Border.all(color: const Color(0xFFF0E6EF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TypingDot(delay: 0),
                          const SizedBox(width: 4),
                          _TypingDot(delay: 200),
                          const SizedBox(width: 4),
                          _TypingDot(delay: 400),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 200.ms);
                }

                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF9C89B8) : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                      ],
                      border: isUser ? null : Border.all(color: const Color(0xFFF0E6EF)),
                    ),
                    child: Text(
                      msg['text']!,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: isUser ? Colors.white : Colors.black),
                    ),
                  ),
                ).animate().fadeIn(duration: 150.ms).slideY(begin: 0.1);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFFFFFFF),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.black),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isTyping,
                    decoration: InputDecoration(
                      hintText: _isTyping ? 'Thinking...' : 'Talk through your anxiety or thoughts...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFFFFFFF),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFF0E6EF))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFF0E6EF))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: _isTyping ? Colors.grey.shade300 : const Color(0xFF9C89B8)),
                  icon: _isTyping
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _isTyping ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPersonaSelectorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Custom Companion Persona', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 4),
              Text('Select the conversational style you need right now', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF7A7287))),
              const SizedBox(height: 16),
              ...CompanionPersona.values.map((persona) {
                return ListTile(
                  leading: Text(persona.avatar, style: const TextStyle(fontSize: 24)),
                  title: Text(persona.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)),
                  subtitle: Text(persona.description, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF7A7287))),
                  trailing: widget.currentPersona == persona ? const Icon(Icons.check_circle, color: Color(0xFF9C89B8)) : null,
                  onTap: () {
                    widget.onPersonaChanged(persona);
                    Navigator.pop(context);
                    setState(() {
                      _resetPersonaWelcome();
                    });
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// Animated typing indicator dot
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
    _animation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF9C89B8),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 3. INTERACTIVE GROUNDING & DIAPHRAGMATIC BREATHING EXERCISES
// -----------------------------------------------------------------------------
class GroundingAndBreathingScreen extends StatefulWidget {
  const GroundingAndBreathingScreen({super.key});

  @override
  State<GroundingAndBreathingScreen> createState() => _GroundingAndBreathingScreenState();
}

class _GroundingAndBreathingScreenState extends State<GroundingAndBreathingScreen> with SingleTickerProviderStateMixin {
  int _activeTab = 0; // 0: 5-4-3-2-1 Sensory Grounding, 1: Diaphragmatic Breathing
  int _groundingStep = 0;

  final List<Map<String, dynamic>> _sensorySteps = [
    {'step': 5, 'sense': 'SEE', 'instruction': 'Acknowledge 5 things you can see around you.', 'icon': Icons.visibility_rounded},
    {'step': 4, 'sense': 'TOUCH', 'instruction': 'Acknowledge 4 things you can physically feel/touch.', 'icon': Icons.back_hand_rounded},
    {'step': 3, 'sense': 'HEAR', 'instruction': 'Acknowledge 3 distinct sounds in your environment.', 'icon': Icons.hearing_rounded},
    {'step': 2, 'sense': 'SMELL', 'instruction': 'Acknowledge 2 scents or fresh air around you.', 'icon': Icons.air_rounded},
    {'step': 1, 'sense': 'TASTE', 'instruction': 'Acknowledge 1 thing you can taste right now.', 'icon': Icons.restaurant_rounded},
  ];

  late AnimationController _breathingController;
  bool _isBreathingRunning = false;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        title: Text('Grounding & Breathing', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF0E6EF), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _activeTab == 0 ? const Color(0xFF9C89B8) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text('5-4-3-2-1 Sensory', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: _activeTab == 0 ? Colors.white : Colors.black)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _activeTab == 1 ? const Color(0xFF9C89B8) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text('Diaphragmatic', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: _activeTab == 1 ? Colors.white : Colors.black)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _activeTab == 0 ? _buildSensoryGroundingView() : _buildDiaphragmaticBreathingView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSensoryGroundingView() {
    final current = _sensorySteps[_groundingStep];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFF0E6EF),
            child: Icon(current['icon'], size: 50, color: const Color(0xFF9C89B8)),
          ),
          const SizedBox(height: 24),
          Text(
            'STEP ${_groundingStep + 1} OF 5',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF7A7287)),
          ),
          const SizedBox(height: 8),
          Text(
            'Acknowledge ${current['step']} Things You ${current['sense']}',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Text(
            current['instruction'],
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_groundingStep > 0)
                OutlinedButton(
                  onPressed: () => setState(() => _groundingStep--),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF9C89B8))),
                  child: const Text('Previous', style: TextStyle(color: Colors.black)),
                ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C89B8)),
                onPressed: () {
                  setState(() {
                    if (_groundingStep < _sensorySteps.length - 1) {
                      _groundingStep++;
                    } else {
                      _groundingStep = 0;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('5-4-3-2-1 Sensory Grounding Complete! ✨', style: TextStyle(color: Colors.black)), backgroundColor: Color(0xFFF0E6EF)),
                      );
                    }
                  });
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  _groundingStep == 4 ? 'Finish Exercise' : 'Next Step',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiaphragmaticBreathingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _breathingController,
            builder: (context, child) {
              final scale = 1.0 + (_breathingController.value * 0.4);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF9C89B8).withValues(alpha: 0.8),
                        const Color(0xFFF0E6EF).withValues(alpha: 0.2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9C89B8).withValues(alpha: 0.3 * _breathingController.value),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.air_rounded, size: 70, color: Colors.white),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          Text(
            _isBreathingRunning ? 'Deep Belly Breathing...' : 'Diaphragmatic Breathing',
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'Breathe deep into belly • Inhale 4s • Exhale 4s',
            style: GoogleFonts.plusJakartaSans(color: Colors.black54),
          ),
          const SizedBox(height: 36),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C89B8),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            onPressed: () {
              setState(() {
                if (_isBreathingRunning) {
                  _breathingController.stop();
                  _isBreathingRunning = false;
                } else {
                  _breathingController.repeat(reverse: true);
                  _isBreathingRunning = true;
                }
              });
            },
            icon: Icon(_isBreathingRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
            label: Text(_isBreathingRunning ? 'Pause Routine' : 'Start Diaphragmatic Routine', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. PRAYER & SUPPORT WALL SCREEN
// -----------------------------------------------------------------------------
class SupportWallScreen extends StatefulWidget {
  const SupportWallScreen({super.key});

  @override
  State<SupportWallScreen> createState() => _SupportWallScreenState();
}

class _SupportWallScreenState extends State<SupportWallScreen> {
  final TextEditingController _controller = TextEditingController();

  void _addPost() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('posts').add({
        'author': user?.displayName ?? 'Anonymous',
        'userId': user?.uid ?? 'anonymous',
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your thought was shared with the community. ❤️', style: TextStyle(color: Colors.black)),
            backgroundColor: Color(0xFFF0E6EF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        title: Text('Prayer & Support Wall', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFFFFFF),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Share your journey, support, or ask for prayers...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFFFFFFF),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFF0E6EF))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFF0E6EF))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF9C89B8)),
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _addPost,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Error loading posts: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No posts yet. Be the first to share! 🌸',
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7A7287), fontSize: 14),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final author = data['author'] ?? 'Anonymous';
                    final text = data['text'] ?? '';
                    return Card(
                      color: const Color(0xFFFFFFFF),
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFF0E6EF)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: const Color(0xFFF0E6EF),
                                  child: const Icon(Icons.person, size: 16, color: Color(0xFF9C89B8)),
                                ),
                                const SizedBox(width: 8),
                                Text(author, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF7A7287), fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(text, style: GoogleFonts.plusJakartaSans(color: Colors.black, fontSize: 15)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.favorite_border_rounded, size: 16, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text('Support', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5. PRIVATE VAULT SCREEN
// -----------------------------------------------------------------------------
class PrivateVaultScreen extends StatefulWidget {
  const PrivateVaultScreen({super.key});

  @override
  State<PrivateVaultScreen> createState() => _PrivateVaultScreenState();
}

class _PrivateVaultScreenState extends State<PrivateVaultScreen> {
  final TextEditingController _vaultController = TextEditingController();

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _deleteThought(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('vault_entries')
          .doc(docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thought released and deleted forever. 🌬️', style: TextStyle(color: Colors.black)),
            backgroundColor: Color(0xFFF0E6EF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to release thought: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _dumpThought() async {
    final text = _vaultController.text.trim();
    if (text.isEmpty || _userId.isEmpty) return;

    try {
      // Store under user's UID sub-collection to avoid composite index requirement
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('vault_entries')
          .add({
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _vaultController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thought safely locked in your Private Vault. 🔒', style: TextStyle(color: Colors.black)),
            backgroundColor: Color(0xFFF0E6EF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save to vault: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        title: Text('Private Vault', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0E6EF)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock_rounded, color: Color(0xFF9C89B8), size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'A safe, 100% private space to dump your deepest thoughts and let them go.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7A7287), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _vaultController,
              maxLines: 4,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Dump your thoughts here...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF0E6EF))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF0E6EF))),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C89B8), elevation: 0),
                onPressed: _dumpThought,
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                label: Text('Dump Thought', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_userId)
                    .collection('vault_entries')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text('Error loading vault: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Your Vault is empty. Write down thoughts to release them.',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7A7287), fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final text = data['text'] ?? '';
                      final docId = docs[index].id;
                      return Card(
                        color: const Color(0xFFFFFFFF),
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFF0E6EF)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(text, style: GoogleFonts.plusJakartaSans(color: Colors.black, fontSize: 14)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                onPressed: () => _deleteThought(docId),
                                tooltip: 'Release this thought',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DAILY FAITH AFFIRMATION CARD & VERSES REPOSITORY
// =============================================================================
class _DailyFaithAffirmationCard extends StatefulWidget {
  const _DailyFaithAffirmationCard();

  @override
  State<_DailyFaithAffirmationCard> createState() => _DailyFaithAffirmationCardState();
}

class _DailyFaithAffirmationCardState extends State<_DailyFaithAffirmationCard> {
  int _verseIndex = 0;

  static const Map<String, List<Map<String, String>>> _faithVerses = {
    'Islam': [
      {
        'verse': '“Unquestionably, by the remembrance of Allah hearts find rest.”',
        'ref': 'Quran 13:28',
        'theme': 'Peace & Rest',
      },
      {
        'verse': '“For indeed, with hardship comes ease. Indeed, with hardship comes ease.”',
        'ref': 'Quran 94:5-6',
        'theme': 'Hope & Relief',
      },
      {
        'verse': '“Allah does not charge a soul except with that within its capacity.”',
        'ref': 'Quran 2:286',
        'theme': 'Inner Strength',
      },
      {
        'verse': '“And He found you lost and guided you.”',
        'ref': 'Quran 93:7',
        'theme': 'Guidance',
      },
      {
        'verse': '“Call upon Me; I will respond to you.”',
        'ref': 'Quran 40:60',
        'theme': 'Comfort',
      },
    ],
    'Christianity': [
      {
        'verse': '“Cast all your anxiety on Him because He cares for you.”',
        'ref': '1 Peter 5:7',
        'theme': 'Surrender & Care',
      },
      {
        'verse': '“Be still, and know that I am God.”',
        'ref': 'Psalm 46:10',
        'theme': 'Stillness',
      },
      {
        'verse': '“Peace I leave with you; my peace I give you. Do not let your hearts be troubled and do not be afraid.”',
        'ref': 'John 14:27',
        'theme': 'Divine Peace',
      },
      {
        'verse': '“The Lord is my strength and my shield; in Him my heart trusts, and I am helped.”',
        'ref': 'Psalm 28:7',
        'theme': 'Protection',
      },
    ],
    'Hinduism': [
      {
        'verse': '“You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions.”',
        'ref': 'Bhagavad Gita 2.47',
        'theme': 'Detachment from Worry',
      },
      {
        'verse': '“A person is made by their belief. As they believe, so they are.”',
        'ref': 'Bhagavad Gita 17.3',
        'theme': 'Mindful Belief',
      },
      {
        'verse': '“Perform your duties equipoised, abandoning all attachment to success or failure.”',
        'ref': 'Bhagavad Gita 2.48',
        'theme': 'Equanimity',
      },
    ],
    'Buddhism': [
      {
        'verse': '“Peace comes from within. Do not seek it without.”',
        'ref': 'Dhammapada',
        'theme': 'Inner Calm',
      },
      {
        'verse': '“The mind is everything. What you think, you become.”',
        'ref': 'Buddha',
        'theme': 'Mind Awareness',
      },
      {
        'verse': '“In the end, only three things matter: how much you loved, how gently you lived, and how gracefully you let go of things not meant for you.”',
        'ref': 'Buddhist Wisdom',
        'theme': 'Releasing Control',
      },
    ],
    'Judaism': [
      {
        'verse': '“The Lord is my light and my salvation; whom shall I fear?”',
        'ref': 'Psalm 27:1',
        'theme': 'Courage & Light',
      },
      {
        'verse': '“Gam zu l’tovah — This too is for the best.”',
        'ref': 'Talmudic Maxim',
        'theme': 'Trust & Patience',
      },
      {
        'verse': '“Trust in the Lord with all your heart and lean not on your own understanding.”',
        'ref': 'Proverbs 3:5',
        'theme': 'Faith & Rest',
      },
    ],
    'Spiritual / Universal': [
      {
        'verse': '“This present moment is your anchor. Inhale peace, exhale tension.”',
        'ref': 'Mindful Reflection',
        'theme': 'Present Moment',
      },
      {
        'verse': '“You do not have to control your thoughts. You just have to stop letting them control you.”',
        'ref': 'Universal Wisdom',
        'theme': 'Thought Release',
      },
      {
        'verse': '“Be gentle with yourself. You are doing the best you can right now.”',
        'ref': 'Self-Compassion',
        'theme': 'Kindness',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        String userFaith = 'Islam';
        int userAge = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          userFaith = data?['faith'] ?? 'Islam';
          userAge = data?['age'] ?? 0;
        }

        final verses = _faithVerses[userFaith] ?? _faithVerses['Islam']!;
        final currentVerse = verses[_verseIndex % verses.length];

        String faithIcon = '🕌';
        if (userFaith == 'Christianity') faithIcon = '✝️';
        if (userFaith == 'Hinduism') faithIcon = '🕉️';
        if (userFaith == 'Buddhism') faithIcon = '☸️';
        if (userFaith == 'Judaism') faithIcon = '✡️';
        if (userFaith == 'Spiritual / Universal') faithIcon = '🌿';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF9C89B8).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C89B8).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0E6EF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(faithIcon, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DAILY AFFIRMATION VERSE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: const Color(0xFF9C89B8),
                            ),
                          ),
                          Text(
                            '$userFaith Guidance ${userAge > 0 ? "• Age $userAge" : ""}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF7A7287),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF9C89B8), size: 20),
                    tooltip: 'Next Verse',
                    onPressed: () {
                      setState(() {
                        _verseIndex = (_verseIndex + 1) % verses.length;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                currentVerse['verse']!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E6EF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentVerse['theme']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF9C89B8),
                      ),
                    ),
                  ),
                  Text(
                    currentVerse['ref']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A7287),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1);
      },
    );
  }
}

// =============================================================================
// DAILY AFFIRMATION CARD & VERSES
// =============================================================================
class _DailyAffirmationCard extends StatefulWidget {
  const _DailyAffirmationCard();

  @override
  State<_DailyAffirmationCard> createState() => _DailyAffirmationCardState();
}

class _DailyAffirmationCardState extends State<_DailyAffirmationCard> {
  int _affirmationIndex = 0;

  static const List<String> _affirmations = [
    "My mind is calm, and my thoughts are clear.",
    "I release the need to control everything and trust the process.",
    "I am safe and secure in this present moment.",
    "I am stronger than my anxious thoughts.",
    "I choose peace, clarity, and self-compassion over overthinking.",
    "I am doing the best I can right now, and that is enough.",
    "I trust myself to handle whatever challenges come my way.",
    "I am worthy of peace, happiness, and a quiet mind.",
    "Slow down. Breathe. Let go of what I cannot control.",
    "This moment is a fresh start. I choose to focus on the present."
  ];

  @override
  Widget build(BuildContext context) {
    final affirmation = _affirmations[_affirmationIndex % _affirmations.length];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF9C89B8).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C89B8).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E6EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Color(0xFF9C89B8), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY AFFIRMATION',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: const Color(0xFF9C89B8),
                        ),
                      ),
                      Text(
                        'Positive Self-Talk',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF7A7287),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF9C89B8), size: 20),
                tooltip: 'Next Affirmation',
                onPressed: () {
                  setState(() {
                    _affirmationIndex = (_affirmationIndex + 1) % _affirmations.length;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '“$affirmation”',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: Colors.black87,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

// =============================================================================
// FOCUS TAPPING (PATTERN INTERRUPT) SCREEN
// =============================================================================
class FocusTappingScreen extends StatefulWidget {
  const FocusTappingScreen({super.key});

  @override
  State<FocusTappingScreen> createState() => _FocusTappingScreenState();
}

class _FocusTappingScreenState extends State<FocusTappingScreen> with SingleTickerProviderStateMixin {
  int _tapCount = 0;
  final int _targetTaps = 20;
  bool _completed = false;
  
  double _xPos = 0.5;
  double _yPos = 0.5;
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_completed) return;
    
    // Play light haptic feedback
    HapticFeedback.lightImpact();
    
    setState(() {
      _tapCount++;
      if (_tapCount >= _targetTaps) {
        _completed = true;
        _pulseController.stop();
      } else {
        // Move to a new random position (0.1 to 0.9 to keep it on screen)
        final time = DateTime.now().millisecondsSinceEpoch;
        _xPos = (time % 80) / 100.0 + 0.1;
        _yPos = ((time / 10).floor() % 80) / 100.0 + 0.1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF9C89B8)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _completed
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF9C89B8), size: 80).animate().scale().fadeIn(),
                  const SizedBox(height: 24),
                  Text(
                    'Loop Broken.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),
                  Text(
                    'Take a deep breath.\nYou are safe in this moment.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, color: const Color(0xFF7A7287)),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C89B8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Return Home', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            )
          : Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        'Focus Tapping',
                        style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the circle $_targetTaps times to break the loop.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF7A7287)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$_tapCount / $_targetTaps',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF9C89B8)),
                      ),
                    ],
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final circleSize = 80.0;
                    final maxLeft = constraints.maxWidth - circleSize;
                    final maxTop = constraints.maxHeight - circleSize - 100; // Leave space for text
                    
                    final left = _xPos * maxLeft;
                    // Clamp top to be below the text area
                    final top = 120 + _yPos * (maxTop - 120 > 0 ? maxTop - 120 : 0);

                    return Positioned(
                      left: left.clamp(0.0, maxLeft),
                      top: top.clamp(120.0, constraints.maxHeight - circleSize),
                      child: GestureDetector(
                        onTap: _onTap,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale = 1.0 + (_pulseController.value * 0.15);
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9C89B8),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF9C89B8).withValues(alpha: 0.4),
                                      blurRadius: 20 * _pulseController.value,
                                      spreadRadius: 5 * _pulseController.value,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

// =============================================================================
// GAMIFIED MIND ARCADE (PATTERN INTERRUPT & THOUGHT DISPLACEMENT)
// =============================================================================

class GamifiedArcadeScreen extends StatefulWidget {
  const GamifiedArcadeScreen({super.key});

  @override
  State<GamifiedArcadeScreen> createState() => _GamifiedArcadeScreenState();
}

class _GamifiedArcadeScreenState extends State<GamifiedArcadeScreen> {
  int _selectedTab = 0; // 0: Bubble Popper, 1: Mind Match

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF9C89B8), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gamified Mind Arcade 🎮',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0E6EF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _ArcadeTabButton(
                  label: '🫧 Pop Worry',
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                _ArcadeTabButton(
                  label: '🃏 Mind Match',
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: const [
                ThoughtBubblePopperGame(),
                MindfulMemoryMatchGame(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcadeTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ArcadeTabButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF9C89B8) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. THOUGHT BUBBLE POPPER GAME
// -----------------------------------------------------------------------------
class ThoughtBubblePopperGame extends StatefulWidget {
  const ThoughtBubblePopperGame({super.key});

  @override
  State<ThoughtBubblePopperGame> createState() => _ThoughtBubblePopperGameState();
}

class _ThoughtBubblePopperGameState extends State<ThoughtBubblePopperGame> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  int _currentIndex = 0;
  bool _isCurrentPopped = false;
  int _score = 0;

  final List<Map<String, String>> _thoughtPairs = [
    {
      'thought': 'What if I fail?',
      'reframe': '✨ Reframe: Failure is just feedback. You learn and grow every single day.',
    },
    {
      'thought': 'Everyone is judging me',
      'reframe': '✨ Reframe: People are focused on themselves. You are free to be you.',
    },
    {
      'thought': 'I must solve this NOW',
      'reframe': '✨ Reframe: Most things can wait. Step back and give yourself space.',
    },
    {
      'thought': 'What if something goes wrong?',
      'reframe': '✨ Reframe: You have handled tough days before. You can handle today too.',
    },
    {
      'thought': 'I am not doing enough',
      'reframe': '✨ Reframe: Your worth is not tied to endless productivity. Rest matters.',
    },
    {
      'thought': 'I can\'t stop overthinking',
      'reframe': '✨ Reframe: You are dismantling these thoughts one by one! You are in control.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _popCurrentBubble() {
    if (_isCurrentPopped) return;
    HapticFeedback.heavyImpact();

    setState(() {
      _isCurrentPopped = true;
      _score += 100;
    });
  }

  void _nextThought() {
    setState(() {
      _currentIndex++;
      _isCurrentPopped = false;
    });
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _isCurrentPopped = false;
      _score = 0;
    });
  }

  bool get _allCompleted => _currentIndex >= _thoughtPairs.length;

  @override
  Widget build(BuildContext context) {
    if (_allCompleted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Color(0xFFF0E6EF), shape: BoxShape.circle),
                child: const Icon(Icons.spa_rounded, color: Color(0xFF9C89B8), size: 64),
              ).animate().scale().fadeIn(),
              const SizedBox(height: 20),
              Text(
                'Mind Cleared! 🌿',
                style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 8),
              Text(
                'You popped all 6 intrusive thoughts one by one!\nTake a slow, deep breath and feel the peace return.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF7A7287)),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C89B8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _restart,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text('Start Over 🫧', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              ).animate().fadeIn(delay: 350.ms),
            ],
          ),
        ),
      );
    }

    final currentPair = _thoughtPairs[_currentIndex];
    final thoughtText = currentPair['thought']!;
    final reframeText = currentPair['reframe']!;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Progress bar and score header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pop the Worry Bubble 🫧', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                  Text('Thought ${_currentIndex + 1} of ${_thoughtPairs.length}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF7A7287))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E6EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Score: $_score',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF9C89B8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Linear Progress Indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _thoughtPairs.length,
              backgroundColor: const Color(0xFFF0E6EF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C89B8)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),

          // Bubble Canvas Area
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  final bobbingOffset = Offset(0, 12 * (_floatController.value - 0.5));

                  return !_isCurrentPopped
                      ? Transform.translate(
                          offset: bobbingOffset,
                          child: GestureDetector(
                            onTap: _popCurrentBubble,
                            child: Container(
                              width: 190,
                              height: 190,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF9C89B8).withValues(alpha: 0.3),
                                    const Color(0xFFF0E6EF).withValues(alpha: 0.9),
                                  ],
                                  center: const Alignment(-0.3, -0.3),
                                ),
                                border: Border.all(color: const Color(0xFF9C89B8), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF9C89B8).withValues(alpha: 0.25),
                                    blurRadius: 18,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '“$thoughtText”',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'TAP TO POP 💥',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: const Color(0xFF9C89B8),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF0E6EF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF9C89B8), size: 54),
                            ).animate().scale().fadeIn(),
                            const SizedBox(height: 16),
                            Text(
                              'Thought Popped! 💥',
                              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                            ).animate().fadeIn(delay: 100.ms),
                            const SizedBox(height: 16),

                            // Reframe Message Card
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0E6EF),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFF9C89B8).withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9C89B8), size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      reframeText,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                            const SizedBox(height: 28),

                            // Next Thought Button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9C89B8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _nextThought,
                              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                              label: Text(
                                _currentIndex + 1 < _thoughtPairs.length ? 'Next Thought 🫧' : 'Finish 🌿',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ).animate().fadeIn(delay: 300.ms),
                          ],
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// -----------------------------------------------------------------------------
// 3. MINDFUL MEMORY MATCH GAME
// -----------------------------------------------------------------------------
class MindfulMemoryMatchGame extends StatefulWidget {
  const MindfulMemoryMatchGame({super.key});

  @override
  State<MindfulMemoryMatchGame> createState() => _MindfulMemoryMatchGameState();
}

class _MemoryCardData {
  final int id;
  final String emoji;
  final String label;
  bool isFlipped = false;
  bool isMatched = false;

  _MemoryCardData({
    required this.id,
    required this.emoji,
    required this.label,
  });
}

class _MindfulMemoryMatchGameState extends State<MindfulMemoryMatchGame> {
  final List<_MemoryCardData> _cards = [];
  int? _firstSelectedIndex;
  bool _isProcessing = false;
  int _moves = 0;
  int _matchesCount = 0;

  final List<Map<String, String>> _pairs = [
    {'emoji': '🧘', 'label': 'Meditation'},
    {'emoji': '🌸', 'label': 'Lotus'},
    {'emoji': '🌊', 'label': 'Ocean'},
    {'emoji': '🕊️', 'label': 'Peace'},
    {'emoji': '🍃', 'label': 'Fresh Leaf'},
    {'emoji': '☀️', 'label': 'Sunlight'},
  ];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _cards.clear();
    _firstSelectedIndex = null;
    _isProcessing = false;
    _moves = 0;
    _matchesCount = 0;

    final List<_MemoryCardData> temp = [];
    int idCounter = 0;

    for (final pair in _pairs) {
      temp.add(_MemoryCardData(id: idCounter++, emoji: pair['emoji']!, label: pair['label']!));
      temp.add(_MemoryCardData(id: idCounter++, emoji: pair['emoji']!, label: pair['label']!));
    }

    temp.shuffle();
    setState(() {
      _cards.addAll(temp);
    });
  }

  void _onCardTap(int index) {
    if (_isProcessing) return;
    final card = _cards[index];
    if (card.isFlipped || card.isMatched) return;

    HapticFeedback.lightImpact();

    setState(() {
      card.isFlipped = true;
    });

    if (_firstSelectedIndex == null) {
      _firstSelectedIndex = index;
    } else {
      _moves++;
      final firstCard = _cards[_firstSelectedIndex!];
      if (firstCard.emoji == card.emoji) {
        // Matched!
        HapticFeedback.mediumImpact();
        setState(() {
          firstCard.isMatched = true;
          card.isMatched = true;
          _firstSelectedIndex = null;
          _matchesCount++;
        });
      } else {
        // Not matched - flip back after delay
        _isProcessing = true;
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            setState(() {
              firstCard.isFlipped = false;
              card.isFlipped = false;
              _firstSelectedIndex = null;
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  bool get _isGameComplete => _matchesCount == _pairs.length;

  @override
  Widget build(BuildContext context) {
    return _isGameComplete
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(color: Color(0xFFF0E6EF), shape: BoxShape.circle),
                    child: const Icon(Icons.psychology_alt_rounded, color: Color(0xFF9C89B8), size: 64),
                  ).animate().scale().fadeIn(),
                  const SizedBox(height: 20),
                  Text(
                    'Working Memory Engaged! 🧠',
                    style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Completed in $_moves moves!\nBy focusing on card matching, your brain shifted focus away from rumination.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF7A7287)),
                  ).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C89B8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _startNewGame,
                    icon: const Icon(Icons.replay_rounded, color: Colors.white),
                    label: Text('Play Mind Match Again', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                  ).animate().fadeIn(delay: 350.ms),
                ],
              ),
            ),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mindful Memory Match 🃏', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                        Text('Find all 6 pairs to ground your working memory', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF7A7287))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E6EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Moves: $_moves',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF9C89B8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    final showFace = card.isFlipped || card.isMatched;

                    return GestureDetector(
                      onTap: () => _onCardTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: showFace ? const Color(0xFFFFFFFF) : const Color(0xFF9C89B8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: card.isMatched ? Colors.green.shade300 : const Color(0xFFF0E6EF),
                            width: card.isMatched ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: showFace
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(card.emoji, style: const TextStyle(fontSize: 32)),
                                    const SizedBox(height: 4),
                                    Text(
                                      card.label,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF7A7287)),
                                    ),
                                  ],
                                )
                              : const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }
}

