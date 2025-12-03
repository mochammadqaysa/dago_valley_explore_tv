import 'package:dago_valley_explore_tv/app/config/app_colors.dart';
import 'package:dago_valley_explore_tv/app/extensions/color.dart';
import 'package:dago_valley_explore_tv/app/services/local_storage.dart';
import 'package:dago_valley_explore_tv/app/util/keyboard.dart';
import 'package:dago_valley_explore_tv/data/models/house_model.dart';
import 'package:dago_valley_explore_tv/presentation/controllers/cashcalculator/cashcalculator_controller.dart';
import 'package:dago_valley_explore_tv/presentation/controllers/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class CashcalculatorPage extends StatefulWidget {
  const CashcalculatorPage({Key? key}) : super(key: key);

  @override
  State<CashcalculatorPage> createState() => _CashcalculatorPageState();
}

class _CashcalculatorPageState extends State<CashcalculatorPage> {
  HouseModel? selectedModel;
  PaymentMethod paymentMethod = PaymentMethod.kprSyariah;
  final TextEditingController _diskonRpController = TextEditingController();
  final TextEditingController _diskonPersenController = TextEditingController();
  final TextEditingController _dpController = TextEditingController();

  final FocusNode _diskonRpFocus = FocusNode();
  final FocusNode _diskonPersenFocus = FocusNode();
  final FocusNode _dpFocus = FocusNode();

  bool tanpaDp = false;
  double? diskonNominal;
  double? diskonPersen;
  double? customDp;
  int tenor = 5;
  double marginPersen = 11.0;
  double marginSyariah = 0.0;
  double marginDeveloper = 0.0;

  TextEditingController? _activeController;

  final controller = CashcalculatorController();
  final currencyFormatter = NumberFormat("#,##0", "id_ID");
  final LocalStorageService _storage = Get.find<LocalStorageService>();

  List<int> get tenorOptions {
    if (paymentMethod == PaymentMethod.kprSyariah) {
      return [5, 10, 15, 20];
    } else {
      return [1, 2, 3, 4];
    }
  }

  @override
  void initState() {
    super.initState();
    final cachedKpr = _storage.kprCalculators;

    marginSyariah = cachedKpr?.first.marginBankSyariahValue ?? 11.0;
    marginDeveloper = cachedKpr?.first.marginDeveloperValue ?? 5.25;

    marginPersen = paymentMethod == PaymentMethod.kprSyariah
        ? marginSyariah
        : marginDeveloper;
  }

  @override
  void dispose() {
    _diskonRpController.dispose();
    _diskonPersenController.dispose();
    _dpController.dispose();
    _diskonRpFocus.dispose();
    _diskonPersenFocus.dispose();
    _dpFocus.dispose();
    super.dispose();
  }

  // ✅ Show keyboard dengan custom TvOnscreenKeyboard
  void _showKeyboard(
    TextEditingController controller, {
    bool allowDecimal = false,
  }) {
    setState(() => _activeController = controller);

    final themeController = Get.find<ThemeController>();

    context.showTvKeyboard(
      isDarkMode: themeController.isDarkMode,
      allowDecimal: allowDecimal,
      onKeyPressed: (value) => _handleKeyPress(value),
      onBackspace: () => _handleBackspace(),
    );
  }

  // ✅ Handle key press
  void _handleKeyPress(String value) {
    if (_activeController == null) return;

    final currentText = _activeController!.text
        .replaceAll('. ', '')
        .replaceAll(',', '')
        .trim();

    String newText;

    if (value == '.') {
      // Decimal point - only for percentage field
      if (_activeController == _diskonPersenController) {
        if (!currentText.contains('.')) {
          newText = currentText.isEmpty ? '0.' : currentText + '.';
        } else {
          return;
        }
      } else {
        return; // Don't allow decimal for rupiah fields
      }
    } else {
      // Number keys
      if (currentText == '0' && value == '0') return;
      if (currentText == '0' && value != '. ') {
        newText = value;
      } else {
        newText = currentText + value;
      }
    }

    // Update fields
    if (_activeController == _dpController) {
      _updateDpField(newText);
    } else if (_activeController == _diskonRpController) {
      _updateDiskonRpField(newText);
    } else if (_activeController == _diskonPersenController) {
      _updateDiskonPersenField(newText);
    }
  }

  // ✅ Handle backspace
  void _handleBackspace() {
    if (_activeController == null) return;

    final currentText = _activeController!.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();

    if (currentText.isEmpty) return;

    String newText = currentText.substring(0, currentText.length - 1);

    // Update fields
    if (_activeController == _dpController) {
      _updateDpField(newText);
    } else if (_activeController == _diskonRpController) {
      _updateDiskonRpField(newText);
    } else if (_activeController == _diskonPersenController) {
      _updateDiskonPersenField(newText);
    }
  }

  void _updateDpField(String value) {
    if (value.isEmpty) {
      setState(() => customDp = null);
      _dpController.clear();
      return;
    }

    double? val = double.tryParse(value);
    if (val != null && val >= 0) {
      setState(() => customDp = val);
      String formattedText = currencyFormatter.format(val.toInt());
      _dpController.value = TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }
  }

  void _updateDiskonRpField(String value) {
    if (value.isEmpty) {
      setState(() => diskonNominal = null);
      _diskonRpController.clear();
      return;
    }

    double? val = double.tryParse(value);
    if (val != null && val >= 0) {
      setState(() {
        diskonNominal = val;
        diskonPersen = null;
      });
      String formattedText = currencyFormatter.format(val.toInt());
      _diskonRpController.value = TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }
  }

  void _updateDiskonPersenField(String value) {
    if (value.isEmpty) {
      setState(() => diskonPersen = null);
      _diskonPersenController.clear();
      return;
    }

    double? val = double.tryParse(value);
    if (val != null && val >= 0 && val <= 100) {
      setState(() {
        diskonPersen = val;
        diskonNominal = null;
      });
      _diskonPersenController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    final result = selectedModel != null
        ? controller.compute(
            model: selectedModel!,
            method: paymentMethod,
            tanpaDp: tanpaDp,
            diskonNominal: diskonNominal,
            diskonPersen: diskonPersen,
            tenorYears: tenor,
            marginPersen: marginPersen,
            customDp: customDp,
          )
        : null;

    return Obx(() {
      final cardColor = themeController.isDarkMode
          ? Colors.grey[900]
          : AppColors.white;

      final textColor = themeController.isDarkMode
          ? Colors.white
          : Colors.black;

      return Scaffold(
        body: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Kalkulator - 60%
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32.0,
                    horizontal: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 8,
                        child: Card(
                          elevation: 0,
                          color: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: ListView(
                              children: [
                                Text(
                                  'mortgage_simulation'.tr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'mortgage_simulation_desc'.tr,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'model_and_type'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  height: 35,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButton<HouseModel>(
                                    isExpanded: true,
                                    value: selectedModel,
                                    hint: Text(
                                      'choose_house_model'.tr,
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                    dropdownColor: cardColor,
                                    focusColor: cardColor,
                                    underline: const SizedBox(),
                                    items: houseModels.map((m) {
                                      return DropdownMenuItem(
                                        value: m,
                                        child: Text(
                                          '${m.displayName} - Rp.   ${_formatCurrencyDisplay(m.hargaCash.round())}',
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        selectedModel = v;
                                        customDp = null;
                                        _dpController.clear();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 5),

                                Text(
                                  'payment_method'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<PaymentMethod>(
                                        title: Text(
                                          'sharia_bank_mortgage'.tr,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                        value: PaymentMethod.kprSyariah,
                                        groupValue: paymentMethod,
                                        onChanged: (v) {
                                          setState(() {
                                            paymentMethod = v!;
                                            tanpaDp = false;
                                            tenor = 5;
                                            marginPersen = marginSyariah;
                                            customDp = null;
                                            _dpController.clear();
                                          });
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<PaymentMethod>(
                                        title: Text(
                                          'developer_mortgage'.tr,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                        value: PaymentMethod.developer,
                                        groupValue: paymentMethod,
                                        onChanged: (v) {
                                          setState(() {
                                            paymentMethod = v!;
                                            tenor = 4;
                                            marginPersen = marginDeveloper;
                                            customDp = null;
                                            _dpController.clear();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'tenor'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 5),

                                Slider(
                                  value: tenor.toDouble(),
                                  divisions: tenorOptions.length - 1,
                                  min: tenorOptions.first.toDouble(),
                                  max: tenorOptions.last.toDouble(),
                                  label: '$tenor ${'years'.tr}',
                                  onChanged: (v) =>
                                      setState(() => tenor = v.round()),
                                ),
                                Center(
                                  child: Text(
                                    '$tenor ${'years'.tr}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                                if (paymentMethod == PaymentMethod.developer)
                                  SizedBox(
                                    height: 35,
                                    child: Row(
                                      children: [
                                        Text(
                                          'no_down_payment'.tr,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Switch(
                                            value: tanpaDp,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            onChanged: (v) {
                                              setState(() {
                                                tanpaDp = v;
                                                customDp = null;
                                                _dpController.clear();
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // === Kolom DP ===
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'DP',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 35,
                                            child: TextField(
                                              controller: _dpController,
                                              focusNode: _dpFocus,
                                              readOnly: true,
                                              enabled: selectedModel != null,
                                              decoration: InputDecoration(
                                                hintText: selectedModel == null
                                                    ? 'choose_house_model_first'
                                                          .tr
                                                    : 'Rp ${_formatCurrencyDisplay(controller.calculateDp(harga: selectedModel!.hargaCash.toDouble(), method: paymentMethod, tanpaDp: tanpaDp).round())}',
                                                hintStyle: TextStyle(
                                                  color:
                                                      themeController.isDarkMode
                                                      ? Colors.grey[600]
                                                      : Colors.grey[500],
                                                  fontSize: 10,
                                                ),
                                                prefixText: 'Rp ',
                                                prefixStyle: TextStyle(
                                                  color: textColor,
                                                  fontSize: 10,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                filled: true,
                                                fillColor: customDp != null
                                                    ? (themeController
                                                              .isDarkMode
                                                          ? Colors.blue[900]
                                                                ?.withOpacity(
                                                                  0.3,
                                                                )
                                                          : Colors.blue[50])
                                                    : (themeController
                                                              .isDarkMode
                                                          ? Colors.grey[800]
                                                          : Colors.grey[200]),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                isDense: true,
                                                suffixIcon: customDp != null
                                                    ? IconButton(
                                                        iconSize: 18,
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            BoxConstraints(),
                                                        icon: Icon(
                                                          Icons.close,
                                                          color: textColor,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            customDp = null;
                                                            _dpController
                                                                .clear();
                                                          });
                                                        },
                                                        tooltip:
                                                            'Reset ke default',
                                                      )
                                                    : null,
                                              ),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: textColor,
                                                fontWeight: customDp != null
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                              // ✅ Show keyboard saat tap
                                              onTap: () {
                                                if (selectedModel != null) {
                                                  _showKeyboard(_dpController);
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // Hidden fields
                                    Expanded(
                                      flex: 1,
                                      child: Offstage(
                                        offstage: true,
                                        child: SizedBox(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 1,
                                      child: Offstage(
                                        offstage: true,
                                        child: SizedBox(),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),
                                Text(
                                  'discount'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 35,
                                        child: TextField(
                                          controller: _diskonRpController,
                                          focusNode: _diskonRpFocus,
                                          readOnly: true,
                                          enabled: diskonPersen == null,
                                          decoration: InputDecoration(
                                            labelText: '${'discount'.tr} (Rp)',
                                            labelStyle: TextStyle(fontSize: 10),
                                            border: const OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                            isDense: true,
                                            suffixIcon: diskonNominal != null
                                                ? IconButton(
                                                    iconSize: 18,
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        BoxConstraints(),
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                    onPressed: () {
                                                      _diskonRpController
                                                          .clear();
                                                      setState(() {
                                                        diskonNominal = null;
                                                      });
                                                    },
                                                  )
                                                : null,
                                          ),
                                          style: TextStyle(
                                            color: themeController.isDarkMode
                                                ? Colors.grey
                                                : Colors.black,
                                            fontSize: 10,
                                          ),
                                          // ✅ Show keyboard saat tap
                                          onTap: diskonPersen == null
                                              ? () => _showKeyboard(
                                                  _diskonRpController,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SizedBox(
                                        height: 35,
                                        child: TextField(
                                          controller: _diskonPersenController,
                                          focusNode: _diskonPersenFocus,
                                          readOnly: true,
                                          enabled: diskonNominal == null,
                                          decoration: InputDecoration(
                                            labelText: '${'discount'.tr} (%)',
                                            labelStyle: TextStyle(fontSize: 10),
                                            border: const OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                            isDense: true,
                                            suffixIcon: diskonPersen != null
                                                ? IconButton(
                                                    iconSize: 18,
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        BoxConstraints(),
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                    onPressed: () {
                                                      _diskonPersenController
                                                          .clear();
                                                      setState(() {
                                                        diskonPersen = null;
                                                      });
                                                    },
                                                  )
                                                : null,
                                          ),
                                          style: TextStyle(
                                            color: themeController.isDarkMode
                                                ? Colors.grey
                                                : Colors.black,
                                            fontSize: 10,
                                          ),
                                          // ✅ Show keyboard dengan decimal support
                                          onTap: diskonNominal == null
                                              ? () => _showKeyboard(
                                                  _diskonPersenController,
                                                  allowDecimal: true,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      if (selectedModel != null && result != null)
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            width: double.infinity,
                            child: Card(
                              color: cardColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Angsuran / Bulan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        'Rp ${(diskonNominal != null || diskonPersen != null) ? _formatCurrencyDisplay(result.cicilanBulananSetelahDiskon.round()) : _formatCurrencyDisplay(result.cicilanBulanan.round())}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (diskonNominal != null ||
                                          diskonPersen != null)
                                        Column(
                                          children: [
                                            Text(
                                              'Rp ${_formatCurrencyDisplay(result.totalPembayaran.round())}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                decorationColor: Colors.red,
                                                decorationThickness: 2,
                                                color: textColor,
                                              ),
                                            ),
                                            Text(
                                              'Rp ${_formatCurrencyDisplay(result.hargaSetelahDiskon.round())}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Text(
                                          'Rp ${_formatCurrencyDisplay(result.totalPembayaran.round())}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: textColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Panel Kanan - Tabel Angsuran (unchanged)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32.0,
                    horizontal: 8.0,
                  ),
                  child: Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    child: DefaultTabController(
                      length: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          children: [
                            Material(
                              color: cardColor,
                              child: TabBar(
                                labelColor: textColor,
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: Colors.green.shade700,
                                tabs: [
                                  Tab(text: 'summary'.tr),
                                  Tab(text: 'installment_table'.tr),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // Summary tab (unchanged)
                                  SingleChildScrollView(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${'terms_n_conditions'.tr}:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...List.generate(
                                          _ringkasanList.length,
                                          (index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${index + 1}.   ',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      color:
                                                          themeController
                                                              .isDarkMode
                                                          ? Colors.grey
                                                          : Colors.black,
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      _ringkasanList[index].tr,
                                                      textAlign:
                                                          TextAlign.justify,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color:
                                                            themeController
                                                                .isDarkMode
                                                            ? Colors.grey
                                                            : Colors.black,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Table tab (unchanged)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child:
                                        selectedModel == null || result == null
                                        ? Center(
                                            child: Text(
                                              'Pilih model & hitung terlebih dahulu',
                                              style: TextStyle(
                                                color:
                                                    themeController.isDarkMode
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                            ),
                                          )
                                        : _buildScheduleTable(
                                            result,
                                            themeController,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  String _formatCurrencyDisplay(int v) {
    return currencyFormatter.format(v);
  }

  Widget _buildScheduleTable(
    CalculatorResult result,
    ThemeController themeController,
  ) {
    final schedule = result.scheduleTable;
    final startLabel = schedule.first['label'];
    final endLabel = schedule.last['label'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Periode: $startLabel - $endLabel',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: themeController.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              child: DataTable(
                border: TableBorder.all(color: Colors.grey, width: 1),
                columnSpacing: 12,
                columns: const [
                  DataColumn(
                    label: Text(
                      'No',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Angsuran',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Sisa Hutang',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
                rows: schedule
                    .map(
                      (r) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              '${r['no']}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              'Rp ${_formatCurrencyDisplay((r['angsuran'] as num).toDouble().round())}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              'Rp ${_formatCurrencyDisplay((r['sisaHutang'] as num).toDouble().round())}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final List<String> _ringkasanList = [
  'terms_one',
  'terms_two',
  'terms_three',
  'terms_four',
  'terms_five',
  'terms_six',
  'terms_seven',
  'terms_eight',
  'terms_nine',
  'terms_ten',
  'terms_eleven',
  'terms_twelve',
];
