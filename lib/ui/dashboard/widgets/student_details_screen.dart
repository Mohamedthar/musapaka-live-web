import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/student.dart';
import '../../../services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class StudentDetailsScreen extends StatefulWidget {
  final Student student;

  const StudentDetailsScreen({super.key, required this.student});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Student _student;
  final _scoreController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    if (_student.score != null) {
      _scoreController.text = _student.score.toString();
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _updateScore() async {
    final scoreText = _scoreController.text.trim();
    if (scoreText.isEmpty) {
      AppTheme.showSnack(context, 'يرجى ادخال الدرجة', color: AppTheme.errorColor);
      return;
    }

    final score = double.tryParse(scoreText);
    if (score == null) {
      AppTheme.showSnack(context, 'الدرجة يجب ان تكون رقما', color: AppTheme.errorColor);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedStudent = _student.copyWith(score: score);
      final result = await _supabaseService.updateStudent(
        _student.id!,
        updatedStudent,
      );
      setState(() => _student = result);

      if (mounted) {
        AppTheme.showSnack(context, 'تم حفظ الدرجة بنجاح');
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showSnack(context, 'حدث خطأ: $e', color: AppTheme.errorColor);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطالب'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildImagesCard(),
                  const SizedBox(height: 16),
                  _buildScoreCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              backgroundImage: _student.profileImageUrl != null
                  ? CachedNetworkImageProvider(_student.profileImageUrl!)
                  : null,
              child: _student.profileImageUrl == null
                  ? Text(
                      _student.name.isNotEmpty ? _student.name[0] : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _student.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الطالب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow('العمر', '${_student.age} سنة'),
            _buildInfoRow('هاتف ولي الأمر', _student.phone),
            if (_student.gender != null)
              _buildInfoRow('النوع', _student.gender!),
            if (_student.nationalId != null)
              _buildInfoRow('الرقم القومي', _student.nationalId!),
            if (_student.memorizerName != null && _student.memorizerName!.isNotEmpty)
              _buildInfoRow('اسم المحفظ', _student.memorizerName!),
            if (_student.memorizerPhone != null && _student.memorizerPhone!.isNotEmpty)
              _buildInfoRow('هاتف المحفظ', _student.memorizerPhone!),
            if (_student.memorizerAddress != null && _student.memorizerAddress!.isNotEmpty)
              _buildInfoRow('عنوان المحفظ', _student.memorizerAddress!),
            if (_student.location != null && _student.location!.isNotEmpty)
              _buildInfoRow('عنوان الطالب', _student.location!),
            _buildInfoRow('المستوى', _student.level),
            if (_student.score != null)
              _buildInfoRow('الدرجة', '${_student.score}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الصور',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildImageWidget(
                    _student.profileImageUrl,
                    'الصورة الشخصية',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImageWidget(
                    _student.birthCertificateUrl,
                    'شهادة الميلاد',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? url, String label) {
    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: url != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.error,
                      color: AppTheme.errorColor,
                    ),
                  ),
                )
              : const Center(
                  child: Icon(Icons.image_not_supported, size: 40),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الدرجة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _scoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ادخل الدرجة',
                      prefixIcon: Icon(Icons.star),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _updateScore,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

