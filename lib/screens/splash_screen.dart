import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../utils/constants.dart';

/// Splash screen with animated logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin { //SingleTickerProviderStateMixin يوفر Ticker للرسوم المتحركة.
  // Animation controller
  late AnimationController _animationController;  // AnimationController: يتحكم في مدة الرسوم المتحركة وتوقيتها.  
  late Animation<double> _fadeAnimation;  // لتحديد تدرج التلاشي (opacity).  تأثير الاختفاء والظهور
  late Animation<double> _scaleAnimation; //  لتحديد تدرج التحجيم (scale).  تأثير التكبير والتصغير للشعار

  @override
  void initState() {
    super.initState();
    _initAnimations(); // تُهيئ متحكمات الرسوم المتحركة.
    // Use addPostFrameCallback to avoid setState during build
    //addPostFrameCallback 	:"نفّذ الكود بعد أن تصبح الشاشة مرئية فعليًا."
    //تنفيذ دالة المصادقة بعد التاكد من ظهور شاشة السبلاش
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState(); // يتحقق من حالة المصادقة وينتقل وفقًا لذلك.  
    });
  }

  /// Initialize animations
  void _initAnimations() {  
    _animationController = AnimationController(
      vsync: this,  // vsync: this: يربط متحكم الرسوم المتحركة بـ State
      duration: const Duration(milliseconds: 1500),// مدة الرسوم المتحركة 1.5 ثانية
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,// parent: _animationController: يربط الرسوم المتحركة بـ AnimationController
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),// curve: const Interval(0.0, 0.5, curve: Curves.easeIn): يحدد وقت الظهور
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward(); //بدء تشغيل الرسوم المتحركة.
  }

  /// Check authentication state and navigate accordingly
  Future<void> _checkAuthState() async {
    final authController = context.read<AuthController>(); // authController: يحصل على متحكم المصادقة.
    // Initialize auth controller
    await authController.initialize(); // يقوم بتهيئة متحكم المصادقة.

    // Wait for splash animation
    //  Future.delayed: ينتظر لمدة محددة.
    await Future.delayed(kSplashDuration); // ينتظر لمدة الرسوم المتحركة.

    if (!mounted) return; // mounted: يتحقق من أن الشاشة مرئية قبل الانتقال واذا لم يكن الشاشة مرئية يخرج فورا . 

    // Navigate based on auth state
    if (authController.isLoggedIn) {   // إذا كان المستخدم مسجلاً، ينتقل إلى الشاشة الرئيسية.
      Navigator.pushReplacementNamed(context, kRouteHome); // Navigator.pushReplacementNamed: ينتقل إلى الشاشة الرئيسية.    
    } else {
      Navigator.pushReplacementNamed(context, kRouteWelcome); // إذا لم يكن المستخدم مسجلاً، ينتقل إلى شاشة الترحيب.
    }
  }

  @override
  void dispose() {
    //  تحرير الموارد المستخدمة بواسطة متحكم الرسوم المتحركة لمنع تسرب الذاكرة.
    _animationController.dispose(); //  
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryColor, kPrimaryDarkColor],
          ),
        ),
        child: Center(
          /*ListenableBuilder :هو Widget يعيد بناء نفسه كلما تغيّر الـ Listenable المرتبط به.
          أي كائن يمكن الاستماع له.          
          لا يسبب إعادة build كاملة للشاشة
          يعيد بناء الجزء الداخلي فقط*/      
          child: ListenableBuilder(
            listenable: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          size: 60,
                          color: kPrimaryColor,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // App name
                      const Text(
                        kAppName,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        'Connect with everyone',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Loading indicator
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
