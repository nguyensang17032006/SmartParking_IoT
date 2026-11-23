
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const primary = Color(0xFFF0194B);
  static const navy = Color(0xFF111A31);
  static const secondary = Color(0xFF8791A4);
  static const inputBackground = Color(0xFFF6F8FB);
  static const inputBorder = Color(0xFFE0E5EE);

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController(
    text: 'Trần Quốc Khánh',
  );

  final phoneController = TextEditingController(
    text: '0912345678',
  );

  final emailController = TextEditingController(
    text: 'khanh@example.com',
  );

  final addressController = TextEditingController(
    text: 'Quận 1, TP. Hồ Chí Minh',
  );

  DateTime? birthday = DateTime(2004, 10, 28);

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> pickBirthday() async {
    final date = await showDatePicker(
      context: context,
      initialDate: birthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      setState(() {
        birthday = date;
      });
    }
  }

  String get formattedBirthday {
    if (birthday == null) return 'Chọn ngày sinh';

    final date = birthday!;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void saveProfile() {
    if (!formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Dữ liệu hợp lệ. Chưa kết nối chức năng lưu Supabase.',
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }

  Widget buildField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: secondary,
            ),
          ),

          AppSpacing.gapXS,

          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            style: AppTextStyles.bodyMedium.copyWith(
              color: navy,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputBackground,
              contentPadding: AppSpacing.inputPadding,
              errorStyle: AppTextStyles.bodySmall.copyWith(
                color: Colors.red,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: inputBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: inputBorder,
                ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Thông tin cá nhân',
          style: AppTextStyles.titleMedium.copyWith(
            color: navy,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFFE5EAF3),
                      child: Icon(
                        Icons.person_outline,
                        size: 58,
                        color: secondary,
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(
                        AppSpacing.xs,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2475D0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                AppSpacing.gapSM,

                Text(
                  'Ảnh đại diện (chưa hỗ trợ thay ảnh)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: secondary,
                  ),
                ),

                AppSpacing.gapXXL,

                buildField(
                  label: 'Họ tên',
                  controller: nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                ),

                buildField(
                  label: 'Số điện thoại',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (!RegExp(r'^0\d{9}$')
                        .hasMatch(value ?? '')) {
                      return 'Số điện thoại phải gồm 10 chữ số';
                    }
                    return null;
                  },
                ),

                buildField(
                  label: 'Email',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (!RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(value?.trim() ?? '')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ngày sinh',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: secondary,
                    ),
                  ),
                ),

                AppSpacing.gapXS,

                InkWell(
                  onTap: pickBirthday,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: inputBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: inputBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedBirthday,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: navy,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 19,
                          color: secondary,
                        ),
                      ],
                    ),
                  ),
                ),

                AppSpacing.gapLG,

                buildField(
                  label: 'Địa chỉ',
                  controller: addressController,
                ),

                AppSpacing.gapMD,

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Lưu thay đổi',
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
