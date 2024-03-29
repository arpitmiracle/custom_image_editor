import 'package:custom_image_editor/utils/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:custom_image_editor/data/data.dart';
import 'package:custom_image_editor/data/layer.dart';
import 'package:custom_image_editor/custom_image_editor.dart';

class Emojies extends StatefulWidget {
  const Emojies({Key? key}) : super(key: key);

  @override
  _EmojiesState createState() => _EmojiesState();
}

class _EmojiesState extends State<Emojies> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0.0),
      height: 400,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        color: CustomColors.black,
        boxShadow: [
          BoxShadow(
            blurRadius: 10.9,
            color: Color.fromRGBO(0, 0, 0, 0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              i18n('Select Emoji'),
              style: const TextStyle(color: CustomColors.white),
            ),
          ]),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(0.0),
            child: GridView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              scrollDirection: Axis.vertical,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: 0.0,
                maxCrossAxisExtent: 60.0,
              ),
              children: emojis.map((String emoji) {
                return GridTile(
                    child: GestureDetector(
                  onTap: () {
                    Navigator.pop(
                      context,
                      EmojiLayerData(
                        text: emoji,
                        size: 32.0,
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.zero,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 35),
                    ),
                  ),
                ));
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}
