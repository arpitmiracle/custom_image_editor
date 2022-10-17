
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/presets.dart';
import 'package:custom_image_editor/data/layer.dart';
import 'package:custom_image_editor/utils/extensions.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hand_signature/signature.dart';
import 'package:image_editor/image_editor.dart' as image_editor;
import 'package:custom_image_editor/data/image_item.dart';
import 'package:custom_image_editor/data/layer.dart';
import 'package:custom_image_editor/layers/background_blur_layer.dart';
import 'package:custom_image_editor/layers/background_layer.dart';
import 'package:custom_image_editor/layers/image_layer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:custom_image_editor/modules/all_emojies.dart';
import 'package:custom_image_editor/layers/emoji_layer.dart';
import 'package:custom_image_editor/modules/text.dart';
import 'package:custom_image_editor/layers/text_layer.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:math' as math;
import 'modules/colors_picker.dart';
import 'utils/custom_colors.dart';

late Size viewportSize;
double viewportRatio = 1;

List<Layer> layers = [], undoLayers = [], removedLayers = [];
Map<String, String> _translations = {};

String i18n(String sourceString) =>
    _translations[sourceString.toLowerCase()] ?? sourceString;

/// Single endpoint for MultiImageEditor & SingleImageEditor
class CustomImageEditor extends StatelessWidget {
  final Uint8List? image;
  final List? images;

  final Directory? savePath;
  final int maxLength;
  final bool allowGallery, allowCamera, allowMultiple;

  const CustomImageEditor(
      {Key? key,
        this.image,
        this.images,
        this.savePath,
        this.allowCamera = false,
        this.allowGallery = false,
        this.allowMultiple = false,
        this.maxLength = 99,
        Color? appBar})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (images != null && image == null && !allowCamera && !allowGallery) {
      throw Exception(
          'No image to work with, provide an image or allow the image picker.');
    }

    if ((image == null || images != null) && allowMultiple == true) {
      return MultiImageEditor(
        images: images ?? [],
        savePath: savePath,
        allowCamera: allowCamera,
        allowGallery: allowGallery,
        allowMultiple: allowMultiple,
        maxLength: maxLength,
      );
    } else {
      return SingleImageEditor(
        image: image,
        savePath: savePath,
        allowCamera: allowCamera,
        allowGallery: allowGallery,
      );
    }
  }

  static i18n(Map<String, String> translations) {
    translations.forEach((key, value) {
      _translations[key.toLowerCase()] = value;
    });
  }

  /// Set custom theme properties default is dark theme with CustomColors.white text
  static ThemeData theme = ThemeData(
    scaffoldBackgroundColor: CustomColors.black,
    backgroundColor: CustomColors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: CustomColors.black87,
      iconTheme: IconThemeData(color: CustomColors.white),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      toolbarTextStyle: TextStyle(color: CustomColors.white),
      titleTextStyle: TextStyle(color: CustomColors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: CustomColors.black,
    ),
    iconTheme: const IconThemeData(
      color: CustomColors.white,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: CustomColors.white),
    ),
  );
}

/// Show multiple image carousel to edit multple images at one and allow more images to be added
class MultiImageEditor extends StatefulWidget {
  final Directory? savePath;
  final List images;
  final int maxLength;
  final bool allowGallery, allowCamera, allowMultiple;

  const MultiImageEditor({
    Key? key,
    this.images = const [],
    this.savePath,
    this.allowCamera = false,
    this.allowGallery = false,
    this.allowMultiple = false,
    this.maxLength = 99,
  }) : super(key: key);

  @override
  _MultiImageEditorState createState() => _MultiImageEditorState();
}

class _MultiImageEditorState extends State<MultiImageEditor> {
  List<ImageItem> images = [];

  @override
  void initState() {
    images = widget.images.map((e) => ImageItem(e)).toList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    viewportSize = MediaQuery.of(context).size;

    return Theme(
      data: CustomImageEditor.theme,
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          automaticallyImplyLeading: false,
          actions: [
            const BackButton(),
            const Spacer(),
            if (images.length < widget.maxLength && widget.allowGallery)
              IconButton(
                icon: const Icon(Icons.photo),
                onPressed: () async {
                  var selected = await picker.pickMultiImage();

                  if (selected == null) return;

                  images.addAll(selected.map((e) => ImageItem(e)).toList());
                },
              ).paddingSymmetric(horizontal: 8),
            if (images.length < widget.maxLength && widget.allowCamera)
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () async {
                  var selected =
                  await picker.pickImage(source: ImageSource.camera);

                  if (selected == null) return;

                  images.add(ImageItem(selected));
                },
              ).paddingSymmetric(horizontal: 8),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                Navigator.pop(context, images);
              },
            ).paddingSymmetric(horizontal: 8),
          ],
        ),
        body: Column(
          children: [
            SizedBox(
              height: 332,
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    for (var image in images)
                      Stack(children: [
                        Container(
                          margin: const EdgeInsets.only(
                              top: 32, right: 32, bottom: 32),
                          width: 200,
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: CustomColors.white.withAlpha(80)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.memory(
                              image.image,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ).onTap(() async {
                          var img = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SingleImageEditor(
                                image: image,
                              ),
                            ),
                          );

                          if (img != null) {
                            image.load(img);
                            setState(() {});
                          }
                        }),
                        Positioned(
                          top: 36,
                          right: 36,
                          child: Container(
                            height: 32,
                            width: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: CustomColors.black.withAlpha(60),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              iconSize: 20,
                              padding: const EdgeInsets.all(0),
                              onPressed: () {
                                // print('removing');
                                images.remove(image);
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear_outlined),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 32,
                          left: 0,
                          child: Container(
                            height: 38,
                            width: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: CustomColors.black.withAlpha(100),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(19),
                              ),
                            ),
                            child: IconButton(
                              iconSize: 20,
                              padding: const EdgeInsets.all(0),
                              onPressed: () async {
                                Uint8List? editedImage = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ImageFilters(
                                      image: image.image,
                                    ),
                                  ),
                                );

                                if (editedImage != null) {
                                  image.load(editedImage);
                                }
                              },
                              icon: const Icon(Icons.photo_filter_sharp),
                            ),
                          ),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  final picker = ImagePicker();
}

/// Image editor with all option available
class SingleImageEditor extends StatefulWidget {
  final Directory? savePath;
  final dynamic image;
  final List? imageList;
  final bool allowCamera, allowGallery;

  const SingleImageEditor({
    Key? key,
    this.savePath,
    this.image,
    this.imageList,
    this.allowCamera = false,
    this.allowGallery = false,
  }) : super(key: key);

  @override
  _SingleImageEditorState createState() => _SingleImageEditorState();
}

class _SingleImageEditorState extends State<SingleImageEditor> {
  ImageItem currentImage = ImageItem();

  Offset offset1 = Offset.zero;
  Offset offset2 = Offset.zero;
  final scaf = GlobalKey<ScaffoldState>();

  final GlobalKey container = GlobalKey();
  final GlobalKey globalKey = GlobalKey();
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void dispose() {
    layers.clear();
    super.dispose();
  }

  List<Widget> get filterActions {
    return [
      const BackButton(),
      const Spacer(),
      IconButton(
        icon: Icon(Icons.undo,
            color:
            layers.length > 1 || removedLayers.isNotEmpty ? CustomColors.white : CustomColors.grey),
        onPressed: () {
          if (removedLayers.isNotEmpty) {
            layers.add(removedLayers.removeLast());
            setState(() {});
            return;
          }

          if (layers.length <= 1) return; // do not remove image layer

          undoLayers.add(layers.removeLast());

          setState(() {});
        },
      ).paddingSymmetric(horizontal: 8),
      IconButton(
        icon: Icon(Icons.redo, color: undoLayers.isNotEmpty ? CustomColors.white : CustomColors.grey),
        onPressed: () {
          if (undoLayers.isEmpty) return;

          layers.add(undoLayers.removeLast());

          setState(() {});
        },
      ).paddingSymmetric(horizontal: 8),
      if (widget.allowGallery)
        IconButton(
          icon: const Icon(Icons.photo),
          onPressed: () async {
            var image = await picker.pickImage(source: ImageSource.gallery);

            if (image == null) return;

            await currentImage.load(image);
          },
        ).paddingSymmetric(horizontal: 8),
      if (widget.allowCamera)
        IconButton(
          icon: const Icon(Icons.camera_alt),
          onPressed: () async {
            var image = await picker.pickImage(source: ImageSource.camera);

            if (image == null) return;

            await currentImage.load(image);
          },
        ).paddingSymmetric(horizontal: 8),
      IconButton(
        icon: const Icon(Icons.check),
        onPressed: () async {
          resetTransformation();

          var binaryIntList =
          await screenshotController.capture(pixelRatio: pixelRatio);

          Navigator.pop(context, binaryIntList);
        },
      ).paddingSymmetric(horizontal: 8),
    ];
  }

  @override
  void initState() {
    if (widget.image != null) {
      loadImage(widget.image!);
    }

    super.initState();
  }

  double flipValue = 0;
  int rotateValue = 0;

  double x = 0;
  double y = 0;
  double z = 0;

  double lastScaleFactor = 1, scaleFactor = 1;
  double widthRatio = 1, heightRatio = 1, pixelRatio = 1;

  resetTransformation() {
    scaleFactor = 1;
    x = 0;
    y = 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    viewportSize = MediaQuery.of(context).size;

    var layersStack = Stack(
      children: layers.map((layerItem) {
        // Background layer
        if (layerItem is BackgroundLayerData) {
          return BackgroundLayer(
            layerData: layerItem,
            onUpdate: () {
              setState(() {});
            },
          );
        }

        // Image layer
        if (layerItem is ImageLayerData) {
          return ImageLayer(
            layerData: layerItem,
            onUpdate: () {
              setState(() {});
            },
          );
        }

        // Background blur layer
        if (layerItem is BackgroundBlurLayerData && layerItem.radius > 0) {
          return BackgroundBlurLayer(
            layerData: layerItem,
          );
        }

        // Emoji layer
        if (layerItem is EmojiLayerData) {
          return EmojiLayer(layerData: layerItem,onUpdate: () {
            setState(() {});
          },);
        }

        // Text layer
        if (layerItem is TextLayerData) {
          return TextLayer(
            layerData: layerItem,
            onUpdate: () {
              setState(() {});
            },
          );
        }

        // Blank layer
        return Container();
      }).toList(),
    );

    widthRatio = currentImage.width / viewportSize.width;
    heightRatio = currentImage.height / viewportSize.height;
    pixelRatio = math.max(heightRatio, widthRatio);

    return Theme(
      data: CustomImageEditor.theme,
      child: Scaffold(
        key: scaf,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          automaticallyImplyLeading: false,
          actions: filterActions,
        ),
        body: GestureDetector(
          onScaleUpdate: (details) {
            // print(details);

            // move
            if (details.pointerCount == 1) {
              // print(details.focalPointDelta);
              x += details.focalPointDelta.dx;
              y += details.focalPointDelta.dy;
              setState(() {});
            }

            // scale
            if (details.pointerCount == 2) {
              // print([details.horizontalScale, details.verticalScale]);
              if (details.horizontalScale != 1) {
                scaleFactor = lastScaleFactor *
                    math.min(details.horizontalScale, details.verticalScale);
                setState(() {});
              }
            }
          },
          onScaleEnd: (details) {
            lastScaleFactor = scaleFactor;
          },
          child: Center(
            child: SizedBox(
              height: currentImage.height / pixelRatio,
              width: currentImage.width / pixelRatio,
              child: Screenshot(
                controller: screenshotController,
                child: RotatedBox(
                  quarterTurns: rotateValue,
                  child: Transform(
                    transform: Matrix4(
                      1,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                      x,
                      y,
                      0,
                      1 / scaleFactor,
                    )..rotateY(flipValue),
                    alignment: FractionalOffset.center,
                    child: layersStack,
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          height: 86 + MediaQuery.of(context).padding.bottom,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(blurRadius: 10),
            ],
          ),
          child: SafeArea(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                BottomButton(
                  icon: Icons.crop,
                  text: 'Crop',
                  onTap: () async {
                    resetTransformation();

                    var data = await screenshotController.capture(
                        pixelRatio: pixelRatio);

                    Uint8List? img = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageCropper(
                          image: data!,
                        ),
                      ),
                    );

                    if (img == null) return;

                    flipValue = 0;
                    rotateValue = 0;

                    await currentImage.load(img);
                    setState(() {});
                  },
                ),
                BottomButton(
                  icon: Icons.text_fields,
                  text: 'Text',
                  onTap: () async {
                    TextLayerData? layer = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TextEditorImage(),
                      ),
                    );

                    if (layer == null) return;

                    undoLayers.clear();
                    removedLayers.clear();

                    layers.add(layer);

                    setState(() {});
                  },
                ),
                BottomButton(
                  icon: Icons.blur_on,
                  text: 'Blur',
                  onTap: () {
                    var blurLayer = BackgroundBlurLayerData(
                      color: Colors.transparent,
                      radius: 0.0,
                      opacity: 0.0,
                    );

                    undoLayers.clear();
                    removedLayers.clear();
                    layers.add(blurLayer);
                    setState(() {});

                    showModalBottomSheet(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            topLeft: Radius.circular(10)),
                      ),
                      barrierColor: CustomColors.black.withOpacity(0.15),
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setS) {
                            return Container(
                              decoration: const BoxDecoration(
                                color: CustomColors.black87,
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(10),
                                    topLeft: Radius.circular(10)),
                              ),
                              padding: const EdgeInsets.all(15),
                              height: 300,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Center(
                                        child: Text(
                                          i18n('Slider Filter Color').toUpperCase(),
                                          style: const TextStyle(color: Colors.white),
                                        )),
                                    const Divider(),
                                    const SizedBox(height: 10.0),
                                    Text(
                                      i18n('Slider Color'),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Expanded(
                                        child: BarColorPicker(
                                          width: MediaQuery.of(context).size.width * 0.72,
                                          thumbColor: CustomColors.white,
                                          cornerRadius: 10,
                                          pickMode: PickMode.color,
                                          colorListener: (int value) {
                                            setS(() {
                                              setState(() {
                                                blurLayer.color = Color(value);
                                              });
                                            });
                                          },
                                        ),
                                      ),
                                      TextButton(
                                        child: Text(
                                          i18n('Reset'),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            setS(() {
                                              blurLayer.color =
                                                  Colors.transparent;
                                            });
                                          });
                                        },
                                      )
                                    ]),
                                    Text(
                                      i18n('Blur Radius'),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 10.0),
                                    Row(children: [
                                      Expanded(
                                        child: Slider(
                                          activeColor: CustomColors.white,
                                          inactiveColor: CustomColors.grey,
                                          value: blurLayer.radius,
                                          min: 0.0,
                                          max: 10.0,
                                          onChanged: (v) {
                                            setS(() {
                                              setState(() {
                                                blurLayer.radius = v;
                                              });
                                            });
                                          },
                                        ),
                                      ),
                                      TextButton(
                                        child: Text(
                                          i18n('Reset'),
                                        ),
                                        onPressed: () {
                                          setS(() {
                                            setState(() {
                                              blurLayer.color = CustomColors.white;
                                            });
                                          });
                                        },
                                      )
                                    ]),
                                    const SizedBox(height: 5.0),
                                    Text(
                                      i18n('Color Opacity'),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 10.0),
                                    Row(children: [
                                      Expanded(
                                        child: Slider(
                                          activeColor: CustomColors.white,
                                          inactiveColor: CustomColors.grey,
                                          value: blurLayer.opacity,
                                          min: 0.00,
                                          max: 1.0,
                                          onChanged: (v) {
                                            setS(() {
                                              setState(() {
                                                blurLayer.opacity = v;
                                              });
                                            });
                                          },
                                        ),
                                      ),
                                      TextButton(
                                        child: Text(
                                          i18n('Reset'),
                                        ),
                                        onPressed: () {
                                          setS(() {
                                            setState(() {
                                              blurLayer.opacity = 0.0;
                                            });
                                          });
                                        },
                                      )
                                    ]),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                // BottomButton(
                //   icon: FontAwesomeIcons.eraser,
                //   text: 'Eraser',
                //   onTap: () {
                //     _controller.clear();
                //     layers.removeWhere((layer) => layer['type'] == 'drawing');
                //     setState(() {});
                //   },
                // ),
                BottomButton(
                  icon: Icons.photo,
                  text: 'Filter',
                  onTap: () async {
                    resetTransformation();

                    var data = await screenshotController.capture(
                        pixelRatio: pixelRatio);

                    Uint8List? editedImage = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageFilters(
                          image: data!,
                        ),
                      ),
                    );

                    if (editedImage == null) return;

                    removedLayers.clear();
                    undoLayers.clear();

                    var layer = BackgroundLayerData(
                      file: ImageItem(editedImage),
                    );

                    layers.add(layer);

                    await layer.file.status;

                    setState(() {});
                  },
                ),
                BottomButton(
                  icon: FontAwesomeIcons.faceSmile,
                  text: 'Emoji',
                  onTap: () async {
                    EmojiLayerData? layer = await showModalBottomSheet(
                      context: context,
                      barrierColor: CustomColors.black.withOpacity(0.15),
                      backgroundColor: CustomColors.black,
                      builder: (BuildContext context) {
                        return const Emojies();
                      },
                    );

                    print("layerlayer ${layer}");

                    if (layer == null) return;

                    undoLayers.clear();
                    removedLayers.clear();
                    layers.add(layer);

                    setState(() {});
                  },
                ),
                BottomButton(
                  icon: Icons.edit,
                  text: 'Brush',
                  onTap: () async {
                    var drawing = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageEditorDrawing(
                          image: currentImage.image,
                        ),
                      ),
                    );

                    if (drawing != null) {
                      undoLayers.clear();
                      removedLayers.clear();

                      layers.add(
                        ImageLayerData(
                          image: ImageItem(drawing),
                        ),
                      );

                      setState(() {});
                    }
                  },
                ),
                BottomButton(
                  icon: Icons.flip,
                  text: 'Flip',
                  onTap: () {
                    setState(() {
                      flipValue = flipValue == 0 ? math.pi : 0;
                    });
                  },
                ),
                BottomButton(
                  icon: Icons.rotate_left,
                  text: 'Rotate left',
                  onTap: () {
                    var t = currentImage.width;
                    currentImage.width = currentImage.height;
                    currentImage.height = t;

                    rotateValue--;
                    setState(() {});
                  },
                ),
                BottomButton(
                  icon: Icons.rotate_right,
                  text: 'Rotate right',
                  onTap: () {
                    var t = currentImage.width;
                    currentImage.width = currentImage.height;
                    currentImage.height = t;

                    rotateValue++;
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final picker = ImagePicker();

  Future<void> loadImage(dynamic imageFile) async {
    await currentImage.load(imageFile);

    layers.clear();

    layers.add(BackgroundLayerData(
      file: currentImage,
    ));

    setState(() {});
  }
}

/// Button used in bottomNavigationBar in CustomImageEditor
class BottomButton extends StatelessWidget {
  final VoidCallback? onTap, onLongPress;
  final IconData icon;
  final String text;

  const BottomButton({
    Key? key,
    this.onTap,
    this.onLongPress,
    required this.icon,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          Icon(
            icon,
          ),
          const SizedBox(height: 8),
          Text(
            i18n(text),
          ),
        ],
      ).paddingSymmetric(horizontal: 16),
    );
  }
}

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