import 'package:flutter/material.dart';
import '../../../../core/storage/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
// Kiểm tra lại tên file AuthRepoImp.dart của bạn nếu IDE báo đỏ dòng import này nhé
import '../../data/datasources/AuthAPI.dart';
import '../../data/repositories/AuthRepo.dart';

class loginWidget extends StatefulWidget {
  const loginWidget({super.key});

  @override
  State<loginWidget> createState() => _loginWidgetState();
}

class _loginWidgetState extends State<loginWidget> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AuthRepo _authRepo;

  @override
  void initState() {
    super.initState();
    _authRepo = AuthRepo();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Ẩn bàn phím khi bấm đăng nhập
    FocusScope.of(context).unfocus();

    final identifier = _emailController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ tên đăng nhập/email và mật khẩu'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authRepo.login(
        nickname: identifier,
        password: password,
      );
      AuthSession.instance.setFromUserJson(result);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập thành công!')),
      );

      // TODO: Lưu token/user từ `result` vào auth_session.dart rồi chuyển trang chính
      // Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Nền gradient sử dụng token của Keepoo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primarySoft,
                  AppColors.background,
                  AppColors.primarySurface,
                ],
              ),
            ),
          ),

          // 2. Các khối tròn trang trí góc trên bên trái
          Positioned(
            top: -45,
            left: -45,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
          _buildDot(top: 115, left: 105, size: 12),
          _buildDot(top: 155, left: 20, size: 11),

          // 3. Chấm tròn mờ bên trái nút Đăng nhập
          Positioned(
            top: 470,
            left: 24,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.7),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // 4. Các khối tròn trang trí góc dưới bên phải
          Positioned(
            bottom: -55,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.55),
                    AppColors.primary,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -75,
            right: 45,
            child: Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.7),
                    AppColors.primary,
                  ],
                ),
              ),
            ),
          ),
          _buildDot(bottom: 125, right: 95, size: 11),

          // 5. Nội dung chính
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),

                  // Phần Header: Logo Keepoo + Card Welcome Back
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Cột Logo bên trái
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Keepoo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primarySurface,
                              border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.85),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 14),

                      // Card Welcome Back bên phải
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primarySurface,
                                AppColors.primarySoft,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.borderStrong.withValues(alpha: 0.6),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Column(
                            children: [
                              Text(
                                'Welcome Back!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Làm chủ tài chính, làm chủ\ntương lai',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.slate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 44),

                  // Ô nhập Tên đăng nhập hoặc email
                  _buildInputField(
                    controller: _emailController,
                    hintText: 'Tên đăng nhập hoặc email',
                    prefixIcon: Icons.person_outline_rounded,
                  ),

                  const SizedBox(height: 20),

                  // Ô nhập Mật khẩu
                  _buildInputField(
                    controller: _passwordController,
                    hintText: 'Mật khẩu',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onTogglePassword: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  // Quên mật khẩu?
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Điều hướng sang password_reset_page.dart
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Nút Đăng nhập chính (có trạng thái loading)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          : const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),

                  // Dải phân cách "Hoặc"
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.borderStrong,
                          thickness: 1.2,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Hoặc',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.placeholder,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.borderStrong,
                          thickness: 1.2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Nút Đăng nhập với Google
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.borderStrong.withValues(alpha: 0.55),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // TODO: Gọi google_sign_in_data_source.dart
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/Google Logo.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'Đăng nhập với google',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 38),

                  // Dòng Chưa có tài khoản? Đăng ký ngay ->
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Chưa có tài khoản?',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.white, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.borderStrong.withValues(alpha: 0.55),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              // TODO: Điều hướng sang registration_page.dart
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Đăng ký ngay',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hỗ trợ tạo chấm tròn xanh trang trí
  Widget _buildDot({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // Widget hỗ trợ tạo ô TextField bo tròn
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderStrong,
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 14.5,
          color: AppColors.navy,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.placeholder,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          prefixIcon: Icon(
            prefixIcon,
            color: AppColors.primary,
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
            onPressed: onTogglePassword,
            icon: Icon(
              obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.slate,
              size: 21,
            ),
          )
              : null,
        ),
      ),
    );
  }
}