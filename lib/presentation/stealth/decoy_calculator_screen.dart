// lib/presentation/stealth/decoy_calculator_screen.dart
import 'package:flutter/material.dart';

class DecoyCalculatorScreen extends StatefulWidget {
  const DecoyCalculatorScreen({super.key});

  @override
  State<DecoyCalculatorScreen> createState() => _DecoyCalculatorScreenState();
}

class _DecoyCalculatorScreenState extends State<DecoyCalculatorScreen> {
  String _display = '0';
  double _num1 = 0;
  String _operand = '';
  bool _shouldResetDisplay = false;

  void _onBtnPressed(String text) {
    setState(() {
      if (text == 'C') {
        _display = '0';
        _num1 = 0;
        _operand = '';
        _shouldResetDisplay = false;
        return;
      }

      if (text == '+' || text == '-' || text == '×' || text == '÷') {
        _num1 = double.tryParse(_display) ?? 0;
        _operand = text;
        _shouldResetDisplay = true;
        return;
      }

      if (text == '=') {
        if (_operand.isEmpty) return;
        final num2 = double.tryParse(_display) ?? 0;
        double result = 0;
        if (_operand == '+') result = _num1 + num2;
        if (_operand == '-') result = _num1 - num2;
        if (_operand == '×') result = _num1 * num2;
        if (_operand == '÷') result = num2 != 0 ? _num1 / num2 : 0;

        _display = result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 2);
        _operand = '';
        _shouldResetDisplay = true;
        return;
      }

      if (_display == '0' || _shouldResetDisplay) {
        _display = text;
        _shouldResetDisplay = false;
      } else {
        _display += text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17171C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Exit Decoy Mode',
        ),
      ),
      body: Column(
        children: [
          // Display
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Text(
                _display,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Keypad
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow(['C', '±', '%', '÷']),
                const SizedBox(height: 12),
                _buildRow(['7', '8', '9', '×']),
                const SizedBox(height: 12),
                _buildRow(['4', '5', '6', '-']),
                const SizedBox(height: 12),
                _buildRow(['1', '2', '3', '+']),
                const SizedBox(height: 12),
                _buildRow(['0', '.', '=']),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> buttons) {
    return Row(
      children: buttons.map((btnText) {
        final isOperator = ['÷', '×', '-', '+', '='].contains(btnText);
        final isSpecial = ['C', '±', '%'].contains(btnText);
        final isZero = btnText == '0';

        final btnColor = isOperator
            ? const Color(0xFFFF9F0A)
            : (isSpecial ? const Color(0xFFA5A5A5) : const Color(0xFF2E2E38));
        final textColor = isSpecial ? Colors.black : Colors.white;

        return Expanded(
          flex: isZero ? 2 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => _onBtnPressed(btnText),
                child: Text(
                  btnText,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
