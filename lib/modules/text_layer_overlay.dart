import 'package:custom_image_editor/utils/custom_colors.dart';
import 'package:custom_image_editor/utils/extensions.dart';
import 'package:custom_image_editor/utils/picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:custom_image_editor/data/layer.dart';
import 'package:custom_image_editor/custom_image_editor.dart';
import 'colors_picker.dart';

class TextLayerOverlay extends StatefulWidget {
  final int index;
  final TextLayerData layer;
  final Function onUpdate;

  const TextLayerOverlay({
    Key? key,
    required this.layer,
    required this.index,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _TextLayerOverlayState createState() => _TextLayerOverlayState();
}

class _TextLayerOverlayState extends State<TextLayerOverlay> {
  double slider = 0.0;

  @override
  void initState() {
    //  slider = widget.sizevalue;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: CustomColors.black87,
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(10), topLeft: Radius.circular(10)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Text(
                i18n('Size Adjust').toUpperCase(),
                style: const TextStyle(color: CustomColors.white),
              ),
            ),
            const Divider(),
            Slider(
                activeColor: CustomColors.white,
                inactiveColor: CustomColors.grey,
                value: widget.layer.size,
                min: 0.0,
                max: 100.0,
                onChangeEnd: (v) {
                  setState(() {
                    widget.layer.size = v.toDouble();
                    widget.onUpdate();
                  });
                },
                onChanged: (v) {
                  setState(() {
                    slider = v;
                    // print(v.toDouble());
                    widget.layer.size = v.toDouble();
                    widget.onUpdate();
                  });
                }),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 20),
                Text(i18n('Color'), style: const TextStyle(color: CustomColors.white))
                    .paddingLeft(16),
                Row(children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: BarColorPicker(
                      width: MediaQuery.of(context).size.width * 0.72,
                      thumbColor: CustomColors.white,
                      initialColor: widget.layer.color,
                      cornerRadius: 10,
                      pickMode: PickMode.color,
                      colorListener: (int value) {
                        setState(() {
                          widget.layer.color = Color(value);
                          widget.onUpdate();
                        });
                      },
                    ),
                  ),
                  TextButton(
                    child: Text(
                      i18n('Custom'),
                      style: const TextStyle(color: CustomColors.white)
                    ),
                    onPressed: () async {
                      var color = await showPickerDialog(context,color: widget.layer.color);
                      if(color != null){
                        setState(() {
                          widget.layer.color = color;
                          widget.onUpdate();
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                ]),
                const SizedBox(height: 20),
                Text(i18n('Background Color'),
                        style: const TextStyle(color: CustomColors.white))
                    .paddingLeft(16),
                Row(children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: BarColorPicker(
                      width: MediaQuery.of(context).size.width * 0.72,
                      initialColor: widget.layer.background,
                      thumbColor: CustomColors.white,
                      cornerRadius: 10,
                      pickMode: PickMode.color,
                      colorListener: (int value) {
                        setState(() {
                          widget.layer.background = Color(value);
                          widget.onUpdate();
                        });
                      },
                    ),
                  ),
                  TextButton(
                    child: Text(
                        i18n('Custom'),
                        style: const TextStyle(color: CustomColors.white)
                    ),
                    onPressed: () async {
                      var color = await showPickerDialog(context,color: widget.layer.background);
                      if(color != null){
                        setState(() {
                          widget.layer.background = color;
                          widget.onUpdate();
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                ]),
                const SizedBox(height: 20),
                Text(
                  i18n('Background Opacity'),
                  style: const TextStyle(color: CustomColors.white),
                ).paddingLeft(16),
                Row(children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: 255,
                      divisions: 255,
                      value: widget.layer.backgroundOpacity.toDouble(),
                      thumbColor: CustomColors.white,
                      onChanged: (double value) {
                        setState(() {
                          widget.layer.backgroundOpacity = value.toInt();
                          widget.onUpdate();
                        });
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        widget.layer.backgroundOpacity = 0;
                        widget.onUpdate();
                      });
                    },
                    child: Text(
                      i18n('Reset'),
                      style: const TextStyle(color: CustomColors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                ]),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    removedLayers.add(layers.removeAt(widget.index));

                    Navigator.pop(context);
                    widget.onUpdate();
                    // back(context);
                    // setState(() {});
                  },
                  child: Text(
                    i18n('Remove'),
                    style: const TextStyle(color: CustomColors.white),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
