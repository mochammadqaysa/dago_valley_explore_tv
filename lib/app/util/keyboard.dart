import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TvOnscreenKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback onClose;
  final bool isDarkMode;
  final bool allowDecimal;
  final String title;

  const TvOnscreenKeyboard({
    Key? key,
    required this.onKeyPressed,
    required this.onBackspace,
    required this.onClose,
    this.isDarkMode = false,
    this.allowDecimal = false,
    this.title = 'Input',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final keyColor = isDarkMode ? Colors.grey[800] : Colors.grey[200];
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Keyboard grid
          Column(
            children: [
              // Row 1: 7, 8, 9
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKey('7', keyColor, textColor),
                  _buildKey('8', keyColor, textColor),
                  _buildKey('9', keyColor, textColor),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: 4, 5, 6
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKey('4', keyColor, textColor),
                  _buildKey('5', keyColor, textColor),
                  _buildKey('6', keyColor, textColor),
                ],
              ),
              const SizedBox(height: 8),

              // Row 3: 1, 2, 3
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKey('1', keyColor, textColor),
                  _buildKey('2', keyColor, textColor),
                  _buildKey('3', keyColor, textColor),
                ],
              ),
              const SizedBox(height: 8),

              // Row 4: decimal/empty, 0, backspace
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (allowDecimal)
                    _buildKey('.', keyColor, textColor)
                  else
                    _buildEmptyKey(),
                  _buildKey('0', keyColor, textColor),
                  _buildBackspaceKey(keyColor, textColor),
                ],
              ),
              const SizedBox(height: 12),

              // Close button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'close'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value, Color? backgroundColor, Color textColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onKeyPressed(value),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 60,
              alignment: Alignment.center,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey(Color? backgroundColor, Color textColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onBackspace,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 60,
              alignment: Alignment.center,
              child: Icon(Icons.backspace_outlined, color: textColor, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyKey() {
    return const Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(height: 60),
      ),
    );
  }
}

// Extension untuk menampilkan keyboard sebagai bottom sheet
extension KeyboardBottomSheet on BuildContext {
  void showTvKeyboard({
    required Function(String) onKeyPressed,
    required VoidCallback onBackspace,
    required bool isDarkMode,
    bool allowDecimal = false,
  }) {
    showModalBottomSheet(
      context: this,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TvOnscreenKeyboard(
        onKeyPressed: onKeyPressed,
        onBackspace: onBackspace,
        onClose: () => Navigator.pop(context),
        isDarkMode: isDarkMode,
        allowDecimal: allowDecimal,
      ),
    );
  }
}
