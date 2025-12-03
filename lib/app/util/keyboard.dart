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

    return Material(
      type: MaterialType.transparency, // ✅ TAMBAHKAN Material wrapper
      child: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          width: 280,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header dengan tombol close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Keyboard',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close, color: textColor, size: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Keyboard grid
              Column(
                children: [
                  // Row 1: 7, 8, 9
                  Row(
                    children: [
                      _buildKey('7', keyColor, textColor),
                      const SizedBox(width: 6),
                      _buildKey('8', keyColor, textColor),
                      const SizedBox(width: 6),
                      _buildKey('9', keyColor, textColor),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Row 2: 4, 5, 6
                  Row(
                    children: [
                      _buildKey('4', keyColor, textColor),
                      const SizedBox(width: 6),
                      _buildKey('5', keyColor, textColor),
                      const SizedBox(width: 6),
                      _buildKey('6', keyColor, textColor),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Row 3: 1, 2, 3
                  Row(
                    children: [
                      _buildKey('1', keyColor, textColor),
                      const SizedBox(width: 6),
                      _buildKey('2', keyColor, textColor),
                      const SizedBox(width: 6),
                      _buildKey('3', keyColor, textColor),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Row 4: decimal/empty, 0, backspace
                  Row(
                    children: [
                      if (allowDecimal)
                        _buildKey('.', keyColor, textColor)
                      else
                        _buildEmptyKey(),
                      const SizedBox(width: 6),
                      _buildKey('0', keyColor, textColor),
                      const SizedBox(width: 6),
                      _buildBackspaceKey(keyColor, textColor),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String value, Color? backgroundColor, Color textColor) {
    return Expanded(
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        elevation: 1,
        child: InkWell(
          onTap: () => onKeyPressed(value),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 45,
            alignment: Alignment.center,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey(Color? backgroundColor, Color textColor) {
    return Expanded(
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        elevation: 1,
        child: InkWell(
          onTap: onBackspace,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 45,
            alignment: Alignment.center,
            child: Icon(Icons.backspace_outlined, color: textColor, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyKey() {
    return const Expanded(child: SizedBox(height: 45));
  }
}

// Extension dengan custom positioning
extension KeyboardBottomSheet on BuildContext {
  void showTvKeyboard({
    required Function(String) onKeyPressed,
    required VoidCallback onBackspace,
    required bool isDarkMode,
    bool allowDecimal = false,
  }) {
    showGeneralDialog(
      context: this,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(this).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return TvOnscreenKeyboard(
          onKeyPressed: onKeyPressed,
          onBackspace: onBackspace,
          onClose: () => Navigator.pop(context),
          isDarkMode: isDarkMode,
          allowDecimal: allowDecimal,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}
