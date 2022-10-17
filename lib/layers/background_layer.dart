import 'package:custom_image_editor/custom_image_editor.dart';
import 'package:custom_image_editor/modules/sticker_layer_overlay.dart';
import 'package:custom_image_editor/utils/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:custom_image_editor/data/layer.dart';

/// Main layer
class BackgroundLayer extends StatefulWidget {
  final BackgroundLayerData layerData;
  final VoidCallback? onUpdate;

  const BackgroundLayer({
    Key? key,
    required this.layerData,
    this.onUpdate,
  }) : super(key: key);

  @override
  State<BackgroundLayer> createState() => _BackgroundLayerState();
}

class _BackgroundLayerState extends State<BackgroundLayer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.layerData.file.width.toDouble(),
      height: widget.layerData.file.height.toDouble(),
      // color: black,
      padding: EdgeInsets.zero,
      child: Image.memory(widget.layerData.file.image),
    );
  }
}


/// Background Sticker layer
class BackgroundStickerLayer extends StatefulWidget {
  final BackgroundLayerData layerData;
  final VoidCallback? onUpdate;

  const BackgroundStickerLayer({
    Key? key,
    required this.layerData,
    this.onUpdate,
  }) : super(key: key);

  @override
  _BackgroundStickerLayerState createState() => _BackgroundStickerLayerState();
}

class _BackgroundStickerLayerState extends State<BackgroundStickerLayer> {

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.layerData.offset.dx,
      top: widget.layerData.offset.dy,
      child: GestureDetector(
        onTap: () {
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
              return StickerLayerOverlay(
                index: layers.indexOf(widget.layerData),
                layer: widget.layerData,
                onUpdate: () {
                  if (widget.onUpdate != null) widget.onUpdate!();
                  setState(() {});
                },
              );
            },
          );
        },
        onScaleUpdate: (detail) {
          if (detail.pointerCount == 1) {
            widget.layerData.offset = Offset(
              widget.layerData.offset.dx + detail.focalPointDelta.dx,
              widget.layerData.offset.dy + detail.focalPointDelta.dy,
            );
          } else if (detail.pointerCount == 2) {
            // widget.layerData.size =
            //     initialSize + detail.scale * 5 * (detail.scale > 1 ? 1 : -1);
          }

          setState(() {});
        },
        child: Container(
          width: widget.layerData.stickerSize,
          height: widget.layerData.stickerSize,
          // color: black,
          padding: EdgeInsets.zero,
          child: Image.memory(widget.layerData.file.image,),
        ),
      ),
    );
  }
}