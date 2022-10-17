import 'package:custom_image_editor/utils/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:custom_image_editor/data/layer.dart';
import 'package:custom_image_editor/custom_image_editor.dart';

class ImageLayerOverlay extends StatefulWidget {
  final int index;
  final ImageLayerData layerData;
  final Function onUpdate;

  const ImageLayerOverlay({
    Key? key,
    required this.layerData,
    required this.index,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _ImageLayerOverlayState createState() => _ImageLayerOverlayState();
}

class _ImageLayerOverlayState extends State<ImageLayerOverlay> {
  double slider = 0.0;

  @override
  void initState() {
    //  slider = widget.sizevalue;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        color: CustomColors.black87,
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(10), topLeft: Radius.circular(10)),
      ),
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
              value: widget.layerData.scale,
              min: 0,
              max: 2,
              divisions: 100,
              onChangeEnd: (v) {
                setState(() {
                  widget.layerData.scale = v.toDouble();
                  widget.onUpdate();
                });
              },
              onChanged: (v) {
                setState(() {
                  slider = v;
                  // print(v.toDouble());
                  widget.layerData.scale = v.toDouble();
                  widget.onUpdate();
                });
              }),
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
    );
  }
}
