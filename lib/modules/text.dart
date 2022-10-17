import 'package:custom_image_editor/utils/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:custom_image_editor/data/layer.dart';
import 'package:custom_image_editor/custom_image_editor.dart';

import 'colors_picker.dart';

class TextEditorImage extends StatefulWidget {
  const TextEditorImage({Key? key}) : super(key: key);

  @override
  _TextEditorImageState createState() => _TextEditorImageState();
}

class _TextEditorImageState extends State<TextEditorImage> {
  TextEditingController name = TextEditingController();
  Color currentColor = CustomColors.white;
  double slider = 25.0;
  TextAlign align = TextAlign.left;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Theme(
      data: CustomImageEditor.theme,
      child: Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: Icon(FontAwesomeIcons.alignLeft,
                  color: align == TextAlign.left
                      ? CustomColors.white
                      : CustomColors.white.withAlpha(80)),
              onPressed: () {
                setState(() {
                  align = TextAlign.left;
                });
              },
            ),
            IconButton(
              icon: Icon(FontAwesomeIcons.alignCenter,
                  color: align == TextAlign.center
                      ? CustomColors.white
                      : CustomColors.white.withAlpha(80)),
              onPressed: () {
                setState(() {
                  align = TextAlign.center;
                });
              },
            ),
            IconButton(
              icon: Icon(FontAwesomeIcons.alignRight,
                  color: align == TextAlign.right
                      ? CustomColors.white
                      : CustomColors.white.withAlpha(80)),
              onPressed: () {
                setState(() {
                  align = TextAlign.right;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.check,color: CustomColors.white),
              onPressed: () {
                Navigator.pop(
                  context,
                  TextLayerData(
                    background: Colors.transparent,
                    text: name.text,
                    color: currentColor,
                    size: slider.toDouble(),
                    align: align,
                  ),
                );
              },
              color: CustomColors.black,
              padding: const EdgeInsets.all(15),
            )
          ],
        ),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(children: [
              Expanded(
                child: TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(10),
                    hintText: 'Insert Your Message',
                    hintStyle: TextStyle(color: CustomColors.grey,fontSize: 20),
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  minLines: 5,
                  maxLines: 99999,
                  textAlign: align,
                  style: TextStyle(
                    color: currentColor,
                    fontSize: slider,

                  ),
                  autofocus: true,
                ),
              ),
              Container(
                color: Colors.transparent,
                child: Column(
                  children: [
                    //   SizedBox(height: 20.0),
                    Container(
                      color: CustomColors.black,
                      child: Column(
                        children: [
                          const SizedBox(height: 10.0),
                          Center(
                            child: Text(
                              i18n('Size Adjust').toUpperCase(),
                              style: const TextStyle(color: CustomColors.white),
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Slider(
                              activeColor: CustomColors.white,
                              inactiveColor: CustomColors.grey,
                              value: slider,
                              min: 0.0,
                              max: 100.0,
                              onChangeEnd: (v) {
                                setState(() {
                                  slider = v;
                                });
                              },
                              onChanged: (v) {
                                setState(() {
                                  slider = v;
                                });
                              }),
                        ],
                      ),
                    ),
                    Text(
                      i18n('Slider Color'),
                      style: const TextStyle(color: CustomColors.white),
                    ),
                      SizedBox(height: 10.0),
                    BarColorPicker(
                      width: MediaQuery.of(context).size.width * 0.8,
                      thumbColor: CustomColors.white,
                      cornerRadius: 10,
                      pickMode: PickMode.color,
                      colorListener: (int value) {
                        setState(() {
                          currentColor = Color(value);
                        });
                      },
                    ),
                      SizedBox(height: 20.0),
                    Text(
                      i18n('Slider White Black Color'),
                      style: const TextStyle(color: CustomColors.white),
                    ),
                      SizedBox(height: 10.0),
                    BarColorPicker(
                      width: MediaQuery.of(context).size.width * 0.8,
                      thumbColor: CustomColors.white,
                      cornerRadius: 10,
                      pickMode: PickMode.grey,
                      colorListener: (int value) {
                        setState(() {
                          currentColor = Color(value);
                        });
                      },
                    ),
                    SizedBox(height: 20.0),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
