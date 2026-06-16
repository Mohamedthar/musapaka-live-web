import 'package:flutter/material.dart';

extension TextEditingControllerX on TextEditingController {
  void setText(String value) {
    text = value;
    selection = TextSelection.fromPosition(TextPosition(offset: value.length));
  }
}
