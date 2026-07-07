import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inquiry_provider.dart';

class CreateInquiryScreen extends StatefulWidget {
  const CreateInquiryScreen({super.key});

  @override
  State<CreateInquiryScreen> createState() => _CreateInquiryScreenState();
}

class _CreateInquiryScreenState extends State<CreateInquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _cityController = TextEditingController();
  
  // Controllers for adding a manual item
  final _itemTitleController = TextEditingController();
  final _itemUnitController = TextEditingController();
  final _itemQtyController = TextEditingController();

  // Custom Color Palette
  final Color royalBlue = const Color(0xFF4169E1);
  final Color amberOrange = const Color(0xFFF59E0B);
  final Color burgundy = const Color(0xFF4A0E17);
  final Color white = const Color(0xFFFFFFFF);

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _cityController.dispose();
    _itemTitleController.dispose();
    _itemUnitController.dispose();
    _itemQtyController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<InquiryProvider>(context, listen: false);
    
    // We mock a bearer token for testing or use a real JWT from verification state.
    // In production, this would be retrieved from your AuthProvider.
    const mockToken = "mock_jwt_token_for_joftojoor_testing";

    final result = await provider.submitInquiry(
      token: mockToken,
      title: _titleController.text,
      description: _descController.text,
      city: _cityController.text,
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'استعلام با موفقیت ثبت شد!',
            style: TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Reset form on success
      _titleController.clear();
      _descController.clear();
      _cityController.clear();
      provider.clearSelectedFile();
      provider.clearManualItems();
    } else if (provider.errorMessage != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'خطا در ثبت استعلام',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: burgundy, fontWeight: FontWeight.bold),
          ),
          content: Text(
            provider.errorMessage!,
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('متوجه شدم'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InquiryProvider>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: royalBlue,
          title: const Text(
            'ایجاد استعلام جدید جفت‌وجور',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Field
                _buildSectionHeader('مشخصات استعلام'),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _titleController,
                  label: 'عنوان استعلام',
                  hint: 'مثال: جوشکاری اسکلت ساختمان مسکونی ۴ طبقه',
                  validator: (value) => value == null || value.trim().isEmpty ? 'لطفاً عنوان را وارد کنید' : null,
                ),
                const SizedBox(height: 15),

                // City Field
                _buildTextField(
                  controller: _cityController,
                  label: 'شهر محل پروژه',
                  hint: 'مثال: کرمان',
                  validator: (value) => value == null || value.trim().isEmpty ? 'لطفاً شهر محل پروژه را وارد کنید' : null,
                ),
                const SizedBox(height: 15),

                // Description Field
                _buildTextField(
                  controller: _descController,
                  label: 'توضیحات تکمیلی پروژه',
                  hint: 'توضیحات درباره زمان شروع، جزئیات جوشکاری و شرایط کارگاه...',
                  maxLines: 4,
                  validator: (value) => value == null || value.trim().isEmpty ? 'لطفاً توضیحات را وارد کنید' : null,
                ),
                const SizedBox(height: 20),

                // Toggle Card
                _buildToggleCard(provider),
                const SizedBox(height: 20),

                // Conditional Layout: Blueprint Upload Area vs Manual Items Input
                if (provider.hasBlueprint)
                  _buildBlueprintUploadArea(provider)
                else
                  _buildManualItemsArea(provider),

                const SizedBox(height: 35),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: royalBlue,
                      foregroundColor: white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'ثبت و ارسال استعلام',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 24,
          decoration: BoxDecoration(
            color: amberOrange,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: burgundy,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: royalBlue, width: 2),
        ),
      ),
    );
  }

  Widget _buildToggleCard(InquiryProvider provider) {
    return Card(
      elevation: 1,
      color: white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: SwitchListTile(
        title: const Text(
          'من لیست اقلام ندارم، مایل به آپلود پلان ساختمان هستم',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        value: provider.hasBlueprint,
        onChanged: (val) {
          provider.setHasBlueprint(val);
        },
        activeThumbColor: royalBlue,
      ),
    );
  }

  Widget _buildBlueprintUploadArea(InquiryProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('آپلود نقشه ساختمان'),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            await provider.pickBlueprintFile();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: royalBlue.withValues(alpha: 0.5), style: BorderStyle.solid),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 60,
                  color: royalBlue,
                ),
                const SizedBox(height: 15),
                if (provider.selectedFileName == null) ...[
                  const Text(
                    'انتخاب و آپلود پلان یا فایل فنی ساختمان',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'فرمت‌های مجاز: PDF, DWG, PNG, JPG (حداکثر ۱۵ مگابایت)',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ] else ...[
                  Text(
                    provider.selectedFileName!,
                    style: TextStyle(fontWeight: FontWeight.bold, color: burgundy, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      provider.clearSelectedFile();
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'حذف فایل انتخابی',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualItemsArea(InquiryProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ثبت دستی اقلام استعلام'),
        const SizedBox(height: 15),
        
        // Item fields container
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildTextField(
                controller: _itemTitleController,
                label: 'عنوان کالا یا خدمات جوشکاری',
                hint: 'مثال: جوشکاری اسکلت دروازه اصلی',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _itemUnitController,
                      label: 'واحد',
                      hint: 'عدد، متر، کیلوگرم',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: _buildTextField(
                      controller: _itemQtyController,
                      label: 'تعداد/مقدار',
                      hint: '۱۰',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final title = _itemTitleController.text.trim();
                    final unit = _itemUnitController.text.trim();
                    final qty = double.tryParse(_itemQtyController.text.trim()) ?? 0.0;

                    if (title.isEmpty || unit.isEmpty || qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('لطفاً مشخصات قلم کالا را به طور صحیح وارد کنید.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    provider.addManualItem(title, unit, qty);
                    _itemTitleController.clear();
                    _itemUnitController.clear();
                    _itemQtyController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amberOrange,
                    foregroundColor: white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('افزودن به لیست اقلام'),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // List of items added
        if (provider.manualItems.isNotEmpty) ...[
          const Text(
            'اقلام اضافه شده:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.manualItems.length,
            itemBuilder: (context, index) {
              final item = provider.manualItems[index];
              return Card(
                elevation: 0,
                color: white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('مقدار: ${item.quantity} ${item.unit}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      provider.removeManualItem(index);
                    },
                  ),
                ),
              );
            },
          ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'هیچ قلمی ثبت نشده است. لطفاً اقلام پروژه را ثبت کنید.',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }
}
