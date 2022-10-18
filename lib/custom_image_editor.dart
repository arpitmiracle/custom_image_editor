import 'dart:async';
import 'dart:io';
import 'package:custom_image_editor/data/layer.dart';
import 'package:custom_image_editor/image_cropper.dart';
import 'package:custom_image_editor/utils/extensions.dart';
import 'package:custom_image_editor/utils/page_route.dart';
import 'package:custom_image_editor/utils/picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:custom_image_editor/data/image_item.dart';
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
import 'image_drawing.dart';
import 'modules/all_stickers.dart';
import 'modules/colors_picker.dart';
import 'utils/custom_colors.dart';

export 'package:custom_image_editor/utils/page_route.dart';

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
                  setState(() {});
                },
              ).paddingSymmetric(horizontal: 8),
            if (images.length < widget.maxLength && widget.allowCamera)
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () async {
                  var selected = await picker.pickImage(source: ImageSource.camera);

                  if (selected == null) return;

                  images.add(ImageItem(selected));
                  setState(() {});
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
                            FadePageRoute(
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
                                  FadePageRoute(
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

          var binaryIntList = await screenshotController.capture(pixelRatio: pixelRatio);

          layers.clear();
          undoLayers.clear();
          removedLayers.clear();
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
        if (layerItem is BackgroundLayerData && layerItem.isSticker == false) {
          return BackgroundLayer(
            layerData: layerItem,
            onUpdate: () {
              setState(() {});
            },
          );
        }

        // Background layer
        if (layerItem is BackgroundLayerData && layerItem.isSticker == true) {
          return BackgroundStickerLayer(
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
                      FadePageRoute(
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
                      FadePageRoute(
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
                                          style: const TextStyle(color: CustomColors.white),
                                        )),
                                    const Divider(),
                                    const SizedBox(height: 10.0),
                                    Text(
                                      i18n('Slider Color'),
                                      style: const TextStyle(color: CustomColors.white),
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
                                            i18n('Custom'),
                                            style: const TextStyle(color: CustomColors.white)
                                        ),
                                        onPressed: () async {
                                         var color = await showPickerDialog(context,color: blurLayer.color);
                                         if(color != null){
                                           setS(() {
                                             setState(() {
                                               blurLayer.color = color;
                                             });
                                           });
                                         }
                                        },
                                      )
                                    ]),
                                    Text(
                                      i18n('Blur Radius'),
                                      style: const TextStyle(color: CustomColors.white),
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
                                          style: const TextStyle(color: CustomColors.white),
                                        ),
                                        onPressed: () {
                                          setS(() {
                                            setState(() {
                                              blurLayer.radius = 0;
                                            });
                                          });
                                        },
                                      )
                                    ]),
                                    const SizedBox(height: 5.0),
                                    Text(
                                      i18n('Color Opacity'),
                                      style: const TextStyle(color: CustomColors.white),
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
                                          style: const TextStyle(color: CustomColors.white),
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
                      enableDrag: true
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
                  icon: Icons.filter_vintage,
                  text: 'Sticker',
                  onTap: () async {

                    String? stickerPath = await Navigator.push(
                      context,
                      FadePageRoute(
                        builder: (context) => Stickers(),
                      ),
                    );

                    if (stickerPath == null) return;

                    removedLayers.clear();
                    undoLayers.clear();
                    var data = await rootBundle.load(stickerPath);

                    var layer = BackgroundLayerData(
                      file: ImageItem(
                         data.buffer.asUint8List()
                      ),
                      isSticker: true
                    );

                    layers.add(layer);

                    await layer.file.status;

                    setState(() {});
                  },
                ),
                BottomButton(
                  icon: Icons.photo,
                  text: 'Filter',
                  onTap: () async {
                    resetTransformation();

                    var data = await screenshotController.capture(
                        pixelRatio: pixelRatio);

                    Uint8List? editedImage = await Navigator.push(
                      context,
                      FadePageRoute(
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
                      FadePageRoute(
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
