import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

void main() {
  runApp(const CropYieldApp());
}

class CropYieldApp extends StatelessWidget {
  const CropYieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
      title: 'Crop Yield Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const PredictionPage(),
    ),
    );
  }
}

//Data Constants 

const List<String> countries = [
  'Angola', 'Benin', 'Burkina Faso', 'Burundi', 'Cameroon',
  'Central African Republic', 'Chad', 'DRC', 'Ethiopia', 'Ghana',
  'Kenya', 'Lesotho', 'Liberia', 'Madagascar', 'Malawi', 'Mali',
  'Mauritania', 'Mozambique', 'Niger', 'Nigeria', 'Rwanda', 'Senegal',
  'Sierra Leone', 'Somalia', 'South Africa', 'South Sudan', 'Sudan',
  'Tanzania United Republic of', 'Togo', 'Uganda', 'Zambia', 'Zimbabwe',
];

const List<String> products = [
  'Avocado', 'Banana', 'Barley', 'Beans', 'Beans (Dry)', 'Beans (Green)',
  'Beans (Phaseolus)', 'Cabbage', 'Cashew Nut', 'Cassava', 'Celery',
  'Chick Peas', 'Citrus Fruit', 'Cloves', 'Cocoa Beans', 'Coconut',
  'Coffee (Green)', 'Cotton', 'Cotton Lint', 'Cottonseed', 'Cow Peas',
  'Cucumber', 'Eggplant', 'Fonio', 'Garlic', 'Ginger', 'Grape',
  'Groundnut', 'Lentil', 'Maize', 'Maize (Green)', 'Maize (Yellow)',
  'Mango', 'Melon', 'Millet', 'Mung Bean', 'Oats', 'Oil Palm',
  'Okras', 'Onions', 'Orange', 'Papaya', 'Pea', 'Pea (Dry)',
  'Pea (Green)', 'Pepper', 'Pigeon Pea', 'Pineapple', 'Plantain',
  'Potato', 'Pumpkin', 'Rapeseed', 'Rice', 'Rice (Milled)',
  'Rice (Paddy)', 'Rubber', 'Sesame Seed', 'Sisal', 'Sorghum',
  'Soybean', 'Spinach', 'Sugarcane', 'Sunflower Seed', 'Sweet Potatoes',
  'Taro', 'Tea', 'Tobacco', 'Tomato', 'Triticale', 'Vanilla',
  'Vetch (Hungarian)', 'Watermelon', 'Wheat', 'Yams',
];

const List<String> seasons = [
  '1st Season', '2nd Season', 'Annual', 'Bas-fond', 'Cold off-season',
  'Cotton season', 'Dam retention', 'Deyr', 'Dry', 'First', 'Gu',
  'Hot off-season', 'Long', 'Main', 'Meher', 'Rice season', 'Season A',
  'Season B', 'Season C', 'Second', 'Short', 'Summer', 'Walo', 'Wet',
  'Winter',
];

const List<String> productionSystems = [
  'A1 (PS)', 'A2 (PS)', 'All (PS)', 'Bas-fonds rainfed (PS)', 'CA (PS)',
  'Commercial (PS)', 'Communal (PS)', 'LSCF (PS)', 'Mechanized (PS)',
  'OR (PS)', 'Plaine/Bas-fond irrigated (PS)', 'Rainfed (PS)',
  'SSCF (PS)', 'Semi-Mechanized (PS)', 'Small_and_medium_scale',
  'agro_pastoral', 'dam irrigation', 'dieri', 'irrigated', 'large_scale',
  'mechanized_rainfed', 'none', 'parastatal recessional',
  'recessional (PS)', 'riverine', 'surface water', 'traditional_rainfed',
];

const List<String> monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

// Prediction Page 

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _formKey = GlobalKey<FormState>();

  // Form values
  String? _selectedCountry;
  final _adminController = TextEditingController();
  String? _selectedProduct;
  String? _selectedSeason;
  String? _selectedProductionSystem;
  final _plantingYearController = TextEditingController();
  int? _selectedPlantingMonth;
  final _harvestYearController = TextEditingController();
  int? _selectedHarvestMonth;
  final _areaController = TextEditingController();

  // State
  bool _isLoading = false;
  String? _predictionResult;
  String? _errorMessage;
  Map<String, dynamic>? _inputSummary;

  @override
  void dispose() {
    _adminController.dispose();
    _plantingYearController.dispose();
    _harvestYearController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _showToast({
    required String title,
    required String description,
    required ToastificationType type,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flatColored,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      description: Text(description),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 300),
      primaryColor: type == ToastificationType.success
          ? const Color(0xFF2E7D32)
          : type == ToastificationType.error
              ? const Color(0xFFC62828)
              : const Color(0xFFF57F17),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      closeOnClick: true,
    );
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) {
      _showToast(
        title: 'Validation Error',
        description: 'Please fix the highlighted fields.',
        type: ToastificationType.warning,
      );
      return;
    }

    // Check dropdowns
    if (_selectedCountry == null ||
        _selectedProduct == null ||
        _selectedSeason == null ||
        _selectedProductionSystem == null ||
        _selectedPlantingMonth == null ||
        _selectedHarvestMonth == null) {
      setState(() {
        _errorMessage = 'Please fill in all fields before predicting.';
        _predictionResult = null;
        _inputSummary = null;
      });
      _showToast(
        title: 'Missing Fields',
        description: 'Please fill in all dropdown fields.',
        type: ToastificationType.warning,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _predictionResult = null;
      _inputSummary = null;
    });

    final body = {
      'country': _selectedCountry,
      'admin_1': _adminController.text.trim(),
      'product': _selectedProduct,
      'season_name': _selectedSeason,
      'crop_production_system': _selectedProductionSystem,
      'planting_year': int.parse(_plantingYearController.text.trim()),
      'planting_month': _selectedPlantingMonth,
      'harvest_year': int.parse(_harvestYearController.text.trim()),
      'harvest_month': _selectedHarvestMonth,
      'area': double.parse(_areaController.text.trim()),
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://linear-regression-model-05uj.onrender.com/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _predictionResult =
              '${(data['prediction'] as num).toStringAsFixed(4)} ${data['unit'] ?? 'tons/hectare'}';
          _inputSummary = data['input_summary'] != null
              ? Map<String, dynamic>.from(data['input_summary'])
              : null;
        });
        _showToast(
          title: 'Prediction Successful',
          description:
              'Yield: ${(data['prediction'] as num).toStringAsFixed(4)} tons/hectare',
          type: ToastificationType.success,
        );
      } else {
        final data = jsonDecode(response.body);
        final msg = data['detail'] is String
            ? data['detail']
            : 'Prediction failed. Please check your inputs.';
        setState(() {
          _errorMessage = msg;
        });
        _showToast(
          title: 'Prediction Failed',
          description: msg,
          type: ToastificationType.error,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Network error. Please check your connection and try again.';
      });
      _showToast(
        title: 'Network Error',
        description: 'Please check your connection and try again.',
        type: ToastificationType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF2E7D32),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  'Crop Yield Predictor',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                    ),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Icon(
                        Icons.eco,
                        size: 48,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Body ──
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Subtitle
                      Text(
                        'Predict crop yield across Sub-Saharan Africa',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // ── Section: Location ──
                      _buildSectionCard(
                        icon: Icons.location_on,
                        title: 'Location',
                        children: [
                          _buildDropdown<String>(
                            label: 'Country',
                            value: _selectedCountry,
                            items: countries
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCountry = v),
                            validator: (v) =>
                                v == null ? 'Select a country' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _adminController,
                            decoration: const InputDecoration(
                              labelText: 'Administrative Region',
                              hintText: 'e.g. Mombasa, Nairobi',
                              prefixIcon: Icon(Icons.map),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter a region'
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Section: Crop Information ──
                      _buildSectionCard(
                        icon: Icons.grass,
                        title: 'Crop Information',
                        children: [
                          _buildDropdown<String>(
                            label: 'Crop / Product',
                            value: _selectedProduct,
                            items: products
                                .map((p) => DropdownMenuItem(
                                    value: p, child: Text(p)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedProduct = v),
                            validator: (v) =>
                                v == null ? 'Select a crop' : null,
                          ),
                          const SizedBox(height: 14),
                          _buildDropdown<String>(
                            label: 'Season',
                            value: _selectedSeason,
                            items: seasons
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedSeason = v),
                            validator: (v) =>
                                v == null ? 'Select a season' : null,
                          ),
                          const SizedBox(height: 14),
                          _buildDropdown<String>(
                            label: 'Production System',
                            value: _selectedProductionSystem,
                            items: productionSystems
                                .map((ps) => DropdownMenuItem(
                                    value: ps, child: Text(ps)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedProductionSystem = v),
                            validator: (v) =>
                                v == null ? 'Select a system' : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Section: Timing ──
                      _buildSectionCard(
                        icon: Icons.calendar_month,
                        title: 'Planting & Harvest',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _plantingYearController,
                                  decoration: const InputDecoration(
                                    labelText: 'Planting Year',
                                    hintText: '2020',
                                    prefixIcon: Icon(Icons.date_range),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    final y = int.tryParse(v);
                                    if (y == null || y < 1960 || y > 2030) {
                                      return '1960-2030';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdown<int>(
                                  label: 'Planting Month',
                                  value: _selectedPlantingMonth,
                                  items: List.generate(
                                    12,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text(monthNames[i]),
                                    ),
                                  ),
                                  onChanged: (v) => setState(
                                      () => _selectedPlantingMonth = v),
                                  validator: (v) =>
                                      v == null ? 'Select' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _harvestYearController,
                                  decoration: const InputDecoration(
                                    labelText: 'Harvest Year',
                                    hintText: '2020',
                                    prefixIcon: Icon(Icons.date_range),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    final y = int.tryParse(v);
                                    if (y == null || y < 1960 || y > 2030) {
                                      return '1960-2030';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdown<int>(
                                  label: 'Harvest Month',
                                  value: _selectedHarvestMonth,
                                  items: List.generate(
                                    12,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text(monthNames[i]),
                                    ),
                                  ),
                                  onChanged: (v) => setState(
                                      () => _selectedHarvestMonth = v),
                                  validator: (v) =>
                                      v == null ? 'Select' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Section: Area ──
                      _buildSectionCard(
                        icon: Icons.square_foot,
                        title: 'Cultivated Area',
                        children: [
                          TextFormField(
                            controller: _areaController,
                            decoration: const InputDecoration(
                              labelText: 'Area (hectares)',
                              hintText: 'e.g. 5000',
                              prefixIcon: Icon(Icons.landscape),
                              suffixText: 'ha',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final a = double.tryParse(v);
                              if (a == null || a <= 0) {
                                return 'Must be greater than 0';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Predict Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _predict,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 3,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.analytics, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      'Predict',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Result / Error Display 
                      if (_predictionResult != null) _buildResultCard(),
                      if (_errorMessage != null) _buildErrorCard(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Card Builder 

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2E7D32), size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  //  Dropdown Builder 

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      menuMaxHeight: 300,
      icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20),
    );
  }

  // Result Card

  Widget _buildResultCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 40),
            const SizedBox(height: 10),
            const Text(
              'Predicted Yield',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF388E3C),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _predictionResult!,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.center,
            ),
            if (_inputSummary != null) ...[
              const Divider(height: 24),
              ..._inputSummary!.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatKey(e.key),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '${e.value}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Error Card

  Widget _buildErrorCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFEBEE),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFC62828),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }
}
