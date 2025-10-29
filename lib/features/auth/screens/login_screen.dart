import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/lottie_widget.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/widgets/social_iconbutton.dart';
import 'package:krishi_link/src/core/components/material_ui/pop_up.dart';
import 'package:krishi_link/src/core/constants/constants.dart';
import 'package:krishi_link/src/core/constants/lottie_assets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _otpFormKey = GlobalKey<FormState>();
  final _credentialFormKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  late TabController _tabController;

  final AuthController authController = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      // Clear form when switching tabs
      _identifierController.clear();
      if (_tabController.index == 0) {
        _passwordController.clear();
      }
      setState(() {});
    }
  }

  Future<void> _sendOtpLogin() async {
    if (!_otpFormKey.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    final isEmail = GetUtils.isEmail(identifier);
    final isPhone = RegExp(r'^(?:\+977|977)?9[678]\d{8}$').hasMatch(identifier);

    if (!isEmail && !isPhone) {
      PopupService.show(
        type: PopupType.error,
        title: 'validation_error'.tr,
        message: 'enter_valid_email_or_nepali_phone'.tr,
      );
      return;
    }

    try {
      await authController.sendOtp(identifier);
      Get.toNamed('/otp-verify', arguments: {'identifier': identifier});
    } catch (e) {
      final errorMessage =
          e.toString().toLowerCase().contains('format')
              ? 'user_not_found_with_credentials'.tr
              : 'failed_to_send_otp'.tr;

      PopupService.show(
        type: PopupType.error,
        title: 'login_failed'.tr,
        message: errorMessage,
      );
    }
  }

  Future<void> _passwordLogin() async {
    if (!_credentialFormKey.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    debugPrint('[LoginScreen] Starting password login');
    debugPrint('[LoginScreen] identifier: $identifier');
    debugPrint('[LoginScreen] password: $password');

    final requestBody = {'EmailorPhone': identifier, 'Password': password};
    debugPrint('[LoginScreen] Request body: $requestBody');

    try {
      debugPrint('[LoginScreen] Calling authController.passwordLogin...');
      await authController.passwordLogin(identifier, password);
      debugPrint('[LoginScreen] passwordLogin call finished');
      debugPrint(
        '[LoginScreen] currentUser: ${authController.currentUser.value}',
      );
    } catch (e) {
      debugPrint('[LoginScreen] Login error: $e');
      PopupService.showSnackbar(
        type: PopupType.error,
        message: 'some_error_occurred_try_again'.tr,
        title: 'error'.tr,
      );
    }
  }

  void _navigateBasedOnRole(String role) {
    // 🔹 TODO: Implement role-based navigation properly
    if (role == 'admin') {
      Get.offAllNamed('/admin-dashboard');
    } else if (role == 'farmer') {
      Get.offAllNamed('/farmer-dashboard');
    } else {
      Get.offAllNamed('/buyer-dashboard');
    }
  }

  bool _isValidEmail(String input) => GetUtils.isEmail(input);

  bool _isValidNepaliPhone(String input) =>
      RegExp(r'^(?:\+977|977)?9[678]\d{8}$').hasMatch(input);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final maxWidth = isTablet ? 500.0 : size.width * 0.9;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              Theme.of(
                context,
              ).colorScheme.secondaryContainer.withValues(alpha: 0.2),
              Theme.of(context).colorScheme.surface,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 40 : 20,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeaderSection(isTablet),
                    SizedBox(height: isTablet ? 40 : 30),
                    _buildLoginCard(isTablet),
                    SizedBox(height: isTablet ? 35 : 25),
                    _buildSocialLoginSection(),
                    SizedBox(height: isTablet ? 30 : 20),
                    _buildRegistrationLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI SECTIONS BELOW ---
  Widget _buildHeaderSection(bool isTablet) {
    return Column(
      children: [
        LottieWidget(
          height: isTablet ? 250 : 180,
          path: LottieAssets.farmer,
          repeat: true,
        ),
        SizedBox(height: isTablet ? 20 : 16),
        Text(
          'welcome_to_krishilink'.tr,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 32 : 28,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'nepals_agricultural_network'.tr,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: isTablet ? 18 : 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isTablet) {
    return Card(
      elevation: 12,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAuthTypeSelector(isTablet),
            SizedBox(height: isTablet ? 24 : 20),
            _buildFormContent(isTablet),
            SizedBox(height: isTablet ? 28 : 24),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthTypeSelector(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isTablet ? 16 : 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: isTablet ? 16 : 14,
        ),
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: [
          Tab(
            height: isTablet ? 70 : 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sms_outlined, size: isTablet ? 28 : 24),
                SizedBox(height: isTablet ? 8 : 6),
                Text('otp_login'.tr),
              ],
            ),
          ),
          Tab(
            height: isTablet ? 70 : 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: isTablet ? 28 : 24),
                SizedBox(height: isTablet ? 8 : 6),
                Text('password_login'.tr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(bool isTablet) {
    return SizedBox(
      height:
          _tabController.index == 0
              ? (isTablet ? 140 : 140)
              : (isTablet ? 200 : 180),
      child: TabBarView(
        controller: _tabController,
        children: [_buildOtpForm(isTablet), _buildCredentialForm(isTablet)],
      ),
    );
  }

  Widget _buildOtpForm(bool isTablet) {
    return Form(
      key: _otpFormKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: TextFormField(
              controller: _identifierController,
              style: TextStyle(fontSize: isTablet ? 16 : 14),
              decoration: _inputDecoration(
                label: 'email_or_phone_number'.tr,
                hint: 'example_email_or_phone'.tr,
                icon: Icons.alternate_email,
                isTablet: isTablet,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => _sendOtpLogin(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'email_or_phone_required'.tr;
                }
                if (!_isValidEmail(value) && !_isValidNepaliPhone(value)) {
                  return 'enter_valid_email_or_nepali_phone'.tr;
                }
                return null;
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: isTablet ? 16 : 12),
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: isTablet ? 20 : 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: Text(
                    'otp_send_hint'.tr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialForm(bool isTablet) {
    return Form(
      key: _credentialFormKey,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          children: [
            TextFormField(
              controller: _identifierController,
              style: TextStyle(fontSize: isTablet ? 16 : 14),
              decoration: _inputDecoration(
                label: 'email_phone'.tr,
                hint: 'enter_email_or_phone'.tr,
                icon: Icons.person_outline,
                isTablet: isTablet,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'email_or_phone_required'.tr;
                }
                return null;
              },
            ),
            SizedBox(height: isTablet ? 20 : 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscureText,
              style: TextStyle(fontSize: isTablet ? 16 : 14),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _passwordLogin(),
              decoration: _inputDecoration(
                label: 'password'.tr,
                hint: 'enter_password'.tr,
                icon: Icons.lock_outline,
                isTablet: isTablet,
                suffix: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Theme.of(context).colorScheme.primary,
                    size: isTablet ? 24 : 20,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'password_required'.tr;
                }
                if (value.length < 8) return 'password_min_8'.tr;
                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                  return 'password_one_upper'.tr;
                }
                if (!RegExp(r'[a-z]').hasMatch(value)) {
                  return 'password_one_lower'.tr;
                }
                if (!RegExp(r'[0-9]').hasMatch(value)) {
                  return 'password_one_number'.tr;
                }
                if (!RegExp(
                  r'[!@#\$&*~%^()_+\-=\[\]{};:"\\|,.<>\/?]',
                ).hasMatch(value)) {
                  return 'password_one_special'.tr;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required bool isTablet,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: isTablet ? 16 : 14),
      prefixIcon: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: isTablet ? 24 : 20,
      ),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: TextStyle(fontSize: isTablet ? 14 : 12),
      border: _inputBorder(),
      enabledBorder: _inputBorder(),
      focusedBorder: _inputBorder(focused: true),
      errorBorder: _inputBorder(error: true),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 20 : 16,
      ),
    );
  }

  InputBorder _inputBorder({bool focused = false, bool error = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color:
            error
                ? Theme.of(context).colorScheme.error
                : focused
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        width: focused ? 2 : 1,
      ),
    );
  }

  Widget _buildLoginButton() {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return Obx(() {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: isTablet ? 58 : 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: authController.isLoading.value ? 0 : 4,
            shadowColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed:
              authController.isLoading.value
                  ? null
                  : _tabController.index == 0
                  ? _sendOtpLogin
                  : _passwordLogin,
          child:
              authController.isLoading.value
                  ? SizedBox(
                    width: isTablet ? 24 : 20,
                    height: isTablet ? 24 : 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _tabController.index == 0 ? Icons.sms : Icons.login,
                        size: isTablet ? 22 : 18,
                      ),
                      SizedBox(width: isTablet ? 12 : 8),
                      Text(
                        _tabController.index == 0
                            ? 'send_otp'.tr
                            : 'sign_in'.tr,
                      ),
                    ],
                  ),
        ),
      );
    });
  }

  Widget _buildSocialLoginSection() {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
              child: Text(
                'or_continue_with'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 20 : 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SocialIconButton(
              iconPath: AssetPaths.googleLogo,
              onTap: () => _handleSocialLogin('google'),
            ),
            SizedBox(width: isTablet ? 24 : 16),
            SocialIconButton(
              iconPath: AssetPaths.facebookLogo,
              onTap: () => _handleSocialLogin('facebook'),
            ),
            if (Theme.of(context).platform == TargetPlatform.iOS) ...[
              SizedBox(width: isTablet ? 24 : 16),
              SocialIconButton(
                onTap: () => _handleSocialLogin('apple'),
                iconPath: AssetPaths.appleLogo,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _handleSocialLogin(String provider) async {
    try {
      switch (provider.toLowerCase()) {
        case 'google':
          await authController.signInWithGoogle();
          break;
        case 'facebook':
          await authController.signInWithFacebook();
          break;
        case 'apple':
          await authController.signInWithApple();
          break;
        default:
          throw Exception('Unsupported provider: $provider');
      }

      if (authController.currentUser.value != null) {
        _navigateBasedOnRole(authController.currentUser.value!.role);
      }
    } catch (e) {
      debugPrint('Social login error: $e');
      PopupService.show(
        type: PopupType.error,
        title: 'login_failed'.tr,
        message: 'failed_social_login'.tr,
      );
    }
  }

  Widget _buildRegistrationLink() {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'dont_have_account'.tr,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => Get.toNamed('/register'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            textStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
          child: Text('register_here'.tr),
        ),
      ],
    );
  }
}
