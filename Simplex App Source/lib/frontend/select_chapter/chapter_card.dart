import 'package:cached_network_image/cached_network_image.dart';
// import 'package:simplex_chapter_x/frontend/nav/navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:simplex_chapter_x/app_info.dart';

class ChapterCard extends StatelessWidget {
  final String bgImg;
  final String name;
  final String clubImg;
  final String clubID;

  const ChapterCard({
    super.key,
    required this.bgImg,
    required this.name,
    required this.clubImg,
    required this.clubID,
  });

  ChapterCard.fromDocumentSnapshot(DocumentSnapshot<Object?> doc, {super.key})
      : clubID = doc.id,
        name = doc.get("name") as String,
        bgImg =
            'https://firebasestorage.googleapis.com/v0/b/mad2-5df9e.appspot.com/o/454531818_520016530728357_6259979388890006873_n%20(2).png?alt=media&token=a1d8f4bd-ad26-45a1-918f-f8d2788673f2',
        clubImg = doc.get("logo") as String;

  static Future<List<ChapterCard>> getCards() async {
    if (AppInfo.currentUser.chapters == null) {
      print('User has no chapters');
      return [];
    }

    List<String> ids = AppInfo.currentUser.chapters;
    List<ChapterCard> cards = [];
    DocumentSnapshot chapter;

    for (String id in ids) {
      print(id);
      chapter = await AppInfo.database.collection("chapters").doc(id).get();
      cards.add(ChapterCard.fromDocumentSnapshot(chapter));
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 15, 0, 0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Container(
              height: 161,
              width: 275,
              decoration: BoxDecoration(
                color: Colors.white,
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: CachedNetworkImageProvider(bgImg),
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 2,
                    color: Color(0x19000000),
                    offset: Offset(0, 1),
                  )
                ],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(25, 0, 20, 25),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(0),
                            child: CachedNetworkImage(
                              imageUrl: clubImg,
                              height: 22,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            color: Colors.white,
                            fontSize: 15,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
