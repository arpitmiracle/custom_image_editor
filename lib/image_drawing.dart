
import 'package:custom_image_editor/utils/custom_colors.dart';
import 'package:custom_image_editor/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hand_signature/signature.dart';

import 'custom_image_editor.dart';
import 'data/image_item.dart';

/// Show image drawing surface over image
class ImageEditorDrawing extends StatefulWidget {
  final Uint8List image;

  const ImageEditorDrawing({
    Key? key,
    required this.image,
  }) : super(key: key);

  @override
  State<ImageEditorDrawing> createState() => _ImageEditorDrawingState();
}

class _ImageEditorDrawingState extends State<ImageEditorDrawing> {
  ImageItem image = ImageItem();

  Color pickerColor = CustomColors.white;
  Color currentColor = CustomColors.white;

  final control = HandSignatureControl(
    threshold: 3.0,
    smoothRatio: 0.65,
    velocityRange: 2.0,
  );

  List<CubicPath> undoList = [];
  bool skipNextEvent = false;

  List<Color> colorList = [
    CustomColors.black,
    CustomColors.white,
    CustomColors.blue,
    CustomColors.green,
    CustomColors.pink,
    CustomColors.purple,
    CustomColors.brown,
    CustomColors.indigo,
    CustomColors.indigo,
  ];

  void changeColor(Color color) {
    currentColor = color;
    setState(() {});
  }

  @override
  void initState() {
    image.load(widget.image);
    control.addListener(() {
      if (control.hasActivePath) return;

      if (skipNextEvent) {
        skipNextEvent = false;
        return;
      }

      undoList = [];
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: CustomImageEditor.theme,
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                Navigator.pop(context);
              },
            ).paddingSymmetric(horizontal: 8),
            const Spacer(),
            IconButton(
              icon: Icon(
                Icons.undo,
                color: control.paths.isNotEmpty ? CustomColors.white : CustomColors.white.withAlpha(80),
              ),
              onPressed: () {
                if (control.paths.isEmpty) return;
                skipNextEvent = true;
                undoList.add(control.paths.last);
                control.stepBack();
                setState(() {});
              },
            ).paddingSymmetric(horizontal: 8),
            IconButton(
              icon: Icon(
                Icons.redo,
                color: undoList.isNotEmpty ? CustomColors.white : CustomColors.white.withAlpha(80),
              ),
              onPressed: () {
                if (undoList.isEmpty) return;

                control.paths.add(undoList.removeLast());
                setState(() {});
              },
            ).paddingSymmetric(horizontal: 8),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                if (control.paths.isEmpty) return Navigator.pop(context);
                var data = await control.toImage(color: currentColor);

                return Navigator.pop(context, data!.buffer.asUint8List());
              },
            ).paddingSymmetric(horizontal: 8),
          ],
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: currentColor == CustomColors.black ? CustomColors.white : CustomColors.black,
          child: HandSignature(
            control: control,
            color: currentColor,
            width: 1.0,
            maxWidth: 10.0,
            type: SignatureDrawType.shape,
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(blurRadius: 10),
              ],
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                ColorButton(
                  color: CustomColors.yellow,
                  onTap: (color) {
                    showModalBottomSheet(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          topLeft: Radius.circular(10),
                        ),
                      ),
                      barrierColor: CustomColors.black.withOpacity(0.15),
                      context: context,
                      builder: (context) {
                        return Container(
                          color: CustomColors.black87,
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.only(top: 16),
                              child: HueRingPicker(
                                pickerColor: pickerColor,
                                onColorChanged: changeColor,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                for (int i = 0; i < colorList.length; i++)
                  ColorButton(
                    color: colorList[i],
                    onTap: (color) => changeColor(color),
                    isSelected: colorList[i] == currentColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Button used in bottomNavigationBar in ImageEditorDrawing
class ColorButton extends StatelessWidget {
  final Color color;
  final Function onTap;
  final bool isSelected;
  const ColorButton({
    Key? key,
    required this.color,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: 34,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 23),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? CustomColors.white : CustomColors.white54,
          width: isSelected ? 2 : 1,
        ),
      ),
    ).onTap(() {
      onTap(color);
    });
  }
}
