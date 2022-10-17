import 'package:custom_image_editor/data/image_item.dart';
import 'package:custom_image_editor/utils/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:custom_image_editor/data/data.dart';
import 'package:custom_image_editor/data/layer.dart';
import 'package:custom_image_editor/custom_image_editor.dart';
import 'package:flutter/services.dart';

class Stickers extends StatefulWidget {
  const Stickers({Key? key}) : super(key: key);

  @override
  _StickersState createState() => _StickersState();
}

class _StickersState extends State<Stickers> {

  List<String> stickers = [
    'assets/bubbles/bubble_1.png',
    'assets/bubbles/bubble_2.png',
    'assets/bubbles/bubble_3.png',
    'assets/bubbles/bubble_4.png',
    'assets/bubbles/bubble_5.png',
    'assets/bubbles/bubble_6.png',
    'assets/bubbles/bubble_7.png',
    'assets/bubbles/bubble_8.png',
    'assets/bubbles/bubble_9.png',
  ];

  @override
  Widget build(BuildContext context) {
    return  Theme(
      data: CustomImageEditor.theme,
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: Text(
            i18n('Select Sticker',),
            style: const TextStyle(color: CustomColors.white,fontSize: 16),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(10.0),
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.vertical,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: 10.0,
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                ),
                itemCount: stickers.length,
                itemBuilder: (context, index) {
                  return GridTile(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(
                            context,
                            stickers[index],
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.zero,
                          child: Image.asset(
                            stickers[index],
                          ),
                        ),
                      ));
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
