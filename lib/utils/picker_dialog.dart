import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

Future showPickerDialog(BuildContext context,{required Color color})async{
  Color pickedColor = color;
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Pick a color!'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: color,
            onColorChanged: (value) {
              pickedColor = value;
            },
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Done'),
            onPressed: () {
              Navigator.of(context).pop(pickedColor);
            },
          ),
        ],
      );
    },
  );
}