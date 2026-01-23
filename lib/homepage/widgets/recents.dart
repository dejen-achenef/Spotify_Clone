import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:spotify_clone/models/song.dart';
import 'package:spotify_clone/providers/song_provider.dart';

class Recent extends StatelessWidget {
  const Recent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, sp, _) {
        final recents = sp.recentlyPlayed;
        if (recents.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Text('Recently Played', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recents.length.clamp(0, 6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 72,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final song = recents[index];
                return _recentCard(song);
              },
            ),
          ],
        );
      },
    );
  }
}

class CardRow extends StatelessWidget {
  const CardRow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        cardsBuild(
          'https://i.pinimg.com/originals/cf/59/b9/cf59b95b507ab3a9736c269e81ddafc7.png',
          'Liked Songs',
        ),
        cardsBuild(
          'https://i.pinimg.com/originals/cf/59/b9/cf59b95b507ab3a9736c269e81ddafc7.png',
          'Liked Songs',
        ),
      ],
    );
  }
}

Card cardsBuild(String img, String txt) {
  return Card(
    color: Colors.grey.shade800,
    child: SizedBox(
      width: 165,
      child: Row(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: Image.network(
              img,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                4,
                17,
                15,
                17,
              ),
              child: Text(txt),
            ),
          )
        ],
      ),
    ),
  );
}
