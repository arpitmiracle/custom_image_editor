import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/presets.dart';
import 'package:custom_image_editor/utils/custom_colors.dart';
import 'package:custom_image_editor/utils/extensions.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'custom_image_editor.dart';
import 'package:image_editor/image_editor.dart' as image_editor;

/// Crop given image with various aspect ratios
class ImageCropper extends StatefulWidget {
  final Uint8List image;

  const ImageCropper({Key? key, required this.image}) : super(key: key);

  @override
  _ImageCropperState createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  final GlobalKey<ExtendedImageEditorState> _controller =
  GlobalKey<ExtendedImageEditorState>();

  double? aspectRatio;
  double? aspectRatioOriginal;
  bool isLandscape = true;
  int rotateAngle = 0;

  @override
  void initState() {
    _controller.currentState?.rotate(right: true);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.currentState != null) {
      // _controller.currentState?.
    }

    return Theme(
      data: CustomImageEditor.theme,
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                var state = _controller.currentState;

                if (state == null) return;

                var data = await cropImageDataWithNativeLibrary(state: state);

                Navigator.pop(context, data);
              },
            ).paddingSymmetric(horizontal: 8),
          ],
        ),
        body: Container(
          color: CustomColors.black,
          child: ExtendedImage.memory(
            widget.image,
            cacheRawData: true,
            fit: BoxFit.contain,
            extendedImageEditorKey: _controller,
            mode: ExtendedImageMode.editor,
            initEditorConfigHandler: (state) {
              return EditorConfig(
                cropAspectRatio: aspectRatio,
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: SizedBox(
            height: 80,
            child: Column(
              children: [
                // Container(
                //   height: 48,
                //   decoration: const BoxDecoration(
                //     boxShadow: [
                //       BoxShadow(
                //         color: CustomColors.black,
                //         blurRadius: 10,
                //       ),
                //     ],
                //   ),
                //   child: ListView(
                //     scrollDirection: Axis.horizontal,
                //     children: <Widget>[
                //       IconButton(
                //         icon: Icon(
                //           Icons.portrait,
                //           color: isLandscape ? gray : CustomColors.white,
                //         ).paddingSymmetric(horizontal: 8, vertical: 4),
                //         onPressed: () {
                //           isLandscape = false;
                //           if (aspectRatioOriginal != null) {
                //             aspectRatio = 1 / aspectRatioOriginal!;
                //           }
                //           setState(() {});
                //         },
                //       ),
                //       IconButton(
                //         icon: Icon(
                //           Icons.landscape,
                //           color: isLandscape ? CustomColors.white : gray,
                //         ).paddingSymmetric(horizontal: 8, vertical: 4),
                //         onPressed: () {
                //           isLandscape = true;
                //           aspectRatio = aspectRatioOriginal!;
                //           setState(() {});
                //         },
                //       ),
                //       Slider(
                //         activeColor: CustomColors.white,
                //         inactiveColor: CustomColors.grey,
                //         value: rotateAngle.toDouble(),
                //         min: 0.0,
                //         max: 100.0,
                //         onChangeEnd: (v) {
                //           rotateAngle = v.toInt();
                //           setState(() {});
                //         },
                //         onChanged: (v) {
                //           rotateAngle = v.toInt();
                //           setState(() {});
                //         },
                //       ),
                //     ],
                //   ),
                // ),
                Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: CustomColors.black,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          Icons.portrait,
                          color: isLandscape ? CustomColors.grey : CustomColors.white,
                        ).paddingSymmetric(horizontal: 8, vertical: 4),
                        onPressed: () {
                          isLandscape = false;
                          if (aspectRatioOriginal != null) {
                            aspectRatio = 1 / aspectRatioOriginal!;
                          }
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.landscape,
                          color: isLandscape ? CustomColors.white : CustomColors.grey,
                        ).paddingSymmetric(horizontal: 8, vertical: 4),
                        onPressed: () {
                          isLandscape = true;
                          aspectRatio = aspectRatioOriginal!;
                          setState(() {});
                        },
                      ),
                      imageRatioButton(null, 'Freeform'),
                      imageRatioButton(1, 'Square'),
                      imageRatioButton(4 / 3, '4:3'),
                      imageRatioButton(5 / 4, '5:4'),
                      imageRatioButton(7 / 5, '7:5'),
                      imageRatioButton(16 / 9, '16:9'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> cropImageDataWithNativeLibrary(
      {required ExtendedImageEditorState state}) async {
    final Rect? cropRect = state.getCropRect();
    final EditActionDetails action = state.editAction!;

    final int rotateAngle = action.rotateAngle.toInt();
    final bool flipHorizontal = action.flipY;
    final bool flipVertical = action.flipX;
    final Uint8List img = state.rawImageData;

    final image_editor.ImageEditorOption option = image_editor.ImageEditorOption();

    if (action.needCrop) {
      option.addOption(image_editor.ClipOption.fromRect(cropRect!));
    }

    if (action.needFlip) {
      option.addOption(image_editor.FlipOption(
          horizontal: flipHorizontal, vertical: flipVertical));
    }

    if (action.hasRotateAngle) {
      option.addOption(image_editor.RotateOption(rotateAngle));
    }

    // final DateTime start = DateTime.now();
    final Uint8List? result = await image_editor.ImageEditor.editImage(
      image: img,
      imageEditorOption: option,
    );

    // print('${DateTime.now().difference(start)} ：total time');

    return result;
  }

  Widget imageRatioButton(double? ratio, String title) {
    return TextButton(
      onPressed: () {
        aspectRatioOriginal = ratio;
        if (aspectRatioOriginal != null && isLandscape == false) {
          aspectRatio = 1 / aspectRatioOriginal!;
        } else {
          aspectRatio = aspectRatioOriginal;
        }
        setState(() {});
      },
      child: Text(
        i18n(title),
        style: TextStyle(
          color: aspectRatioOriginal == ratio ? CustomColors.white : CustomColors.grey,
        ),
      ).paddingSymmetric(horizontal: 8, vertical: 4),
    );
  }
}

/// Return filter applied Uint8List image
class ImageFilters extends StatefulWidget {
  final Uint8List image;

  /// apply each filter to given image in background and cache it to improve UX
  final bool useCache;

  const ImageFilters({
    Key? key,
    required this.image,
    this.useCache = true,
  }) : super(key: key);

  @override
  _ImageFiltersState createState() => _ImageFiltersState();
}

class _ImageFiltersState extends State<ImageFilters> {
  ColorFilterGenerator selectedFilter = PresetFilters.none;
  double filterOpacity = 1;
  Uint8List filterAppliedImage = Uint8List.fromList([]);
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    // decodedImage = img.decodeImage(widget.image)!;
    // resizedImage = img.copyResize(decodedImage, height: 64).getBytes();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: CustomImageEditor.theme,
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                Navigator.pop(context, filterAppliedImage);
              },
            ).paddingSymmetric(horizontal: 8),
          ],
        ),
        body: Center(
          child: Screenshot(
            controller: screenshotController,
            child: Stack(
              children: [
                Image.memory(
                  widget.image,
                  fit: BoxFit.cover,
                ),
                FilterAppliedImage(
                  image: widget.image,
                  filter: selectedFilter,
                  fit: BoxFit.cover,
                  opacity: filterOpacity,
                  onProcess: (img) {
                    // print('processing done');
                    filterAppliedImage = img;
                  },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: SizedBox(
            height: 160,
            child: Column(children: [
              SizedBox(
                height: 40,
                child: selectedFilter == PresetFilters.none
                    ? Container()
                    : selectedFilter.build(
                  Slider(
                    min: 0,
                    max: 1,
                    divisions: 100,
                    value: filterOpacity,
                    onChanged: (value) {
                      filterOpacity = value;
                      setState(() {});
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    for (int i = 0; i < presetFiltersList.length; i++)
                      filterPreviewButton(
                        filter: presetFiltersList[i],
                        name: presetFiltersList[i].name,
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget filterPreviewButton({required filter, required String name}) {
    return Column(children: [
      Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(48),
          border: Border.all(
            color: CustomColors.black,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(48),
          child: FilterAppliedImage(
            image: widget.image,
            filter: filter,
            fit: BoxFit.cover,
          ),
        ),
      ),
      Text(
        i18n(name),
        style: const TextStyle(fontSize: 12),
      ),
    ]).onTap(() {
      selectedFilter = filter;
      setState(() {});
    });
  }
}

/// Short form of Image.memory wrapped in ColorFiltered
class FilterAppliedImage extends StatelessWidget {
  final Uint8List image;
  final ColorFilterGenerator filter;
  final BoxFit? fit;
  final Function(Uint8List)? onProcess;
  final double opacity;

  FilterAppliedImage({
    Key? key,
    required this.image,
    required this.filter,
    this.fit,
    this.onProcess,
    this.opacity = 1,
  }) : super(key: key) {
    // process filter in background
    if (onProcess != null) {
      // no filter supplied
      if (filter.filters.isEmpty) {
        onProcess!(image);
        return;
      }

      final image_editor.ImageEditorOption option =
      image_editor.ImageEditorOption();

      option.addOption(image_editor.ColorOption(matrix: filter.matrix));

      image_editor.ImageEditor.editImage(
        image: image,
        imageEditorOption: option,
      ).then((result) {
        if (result != null) {
          onProcess!(result);
        }
      }).catchError((err, stack) {
        // print(err);
        // print(stack);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (filter.filters.isEmpty) return Image.memory(image, fit: fit);

    return Opacity(
      opacity: opacity,
      child: filter.build(
        Image.memory(image, fit: fit),
      ),
    );
  }
}
