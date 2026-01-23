import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spotify_clone/providers/the_auth.dart';
import 'package:spotify_clone/profile/profile.dart';
import 'package:spotify_clone/providers/song_provider.dart';

class HeaderRow extends StatefulWidget {
  HeaderRow({Key? key}) : super(key: key);

  @override
  _HeaderRowState createState() => _HeaderRowState();
}

class _HeaderRowState extends State<HeaderRow> {
  String _displayName(BuildContext context) {
    final auth = context.read<Auth>();
    final name = auth.authedUser.name;
    if (name.isNotEmpty) return name;
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        15,
        20,
        15,
        15,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Hello, ${_displayName(context)}',
                style: GoogleFonts.montserrat(
                  textStyle: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Consumer<SongProvider>(
                builder: (context, sp, _) => sp.isCurrentlyPlaying
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.music_note, size: 14),
                            SizedBox(width: 4),
                            Text('Now Playing'),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Open Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
