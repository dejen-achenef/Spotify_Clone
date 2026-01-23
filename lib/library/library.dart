import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../player/player_screen.dart';
import '../providers/song_provider.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  final _style = const TextStyle(
    fontSize: 27,
  );
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: AppBar(
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) => setState(() {}),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'az', child: Text('Sort A-Z')),
                  PopupMenuItem(value: 'recent', child: Text('Sort by Recently Added')),
                ],
              )
            ],
            bottom: TabBar(
              tabs: [
                Text(
                  "Liked Songs",
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "Liked Locals",
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Consumer<SongProvider>(builder: (context, songProvider, child) {
          List<Song> likedSongs = songProvider.likedSongs;
          List<Song> likedLocals = songProvider.likedLocals;
          return TabBarView(
            children: [
              LikedSongs(songs: likedSongs),
              LikedLocals(songs: likedLocals),
            ],
          );
        }),
      ),
    );
  }
}

class LikedSongs extends StatefulWidget {
  const LikedSongs({
    Key? key,
    required this.songs,
  }) : super(key: key);
  final List<Song> songs;
  @override
  State<LikedSongs> createState() => _LikedSongsState();
}

class _LikedSongsState extends State<LikedSongs> {
 String _sort = 'recent';
  late List<Song> songs;
  late SongProvider songProv;

  @override
  void initState() {
    super.initState();
    songProv = Provider.of<SongProvider>(context, listen: false);
    fetchSongs();
  }

 void _applySort() {
   if (_sort == 'az') {
     songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
   }
 }

  void fetchSongs() async {
    songProv.fetchSongsFromStorage();
    //songs = songProv.likedSongs;
    songs = [...widget.songs];
    _applySort();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    //fetchSongs();
    return Consumer<SongProvider>(
      builder: (context, songProvider, child) => SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                 const Text('Sort:'),
                 const SizedBox(width: 8),
                 DropdownButton<String>(
                   value: _sort,
                   items: const [
                     DropdownMenuItem(value: 'recent', child: Text('Recently Added')),
                     DropdownMenuItem(value: 'az', child: Text('A-Z')),
                   ],
                   onChanged: (v) {
                     if (v == null) return;
                     setState(() {
                       _sort = v;
                       fetchSongs();
                     });
                   },
                 ),
               ],
             ),
             const SizedBox(height: 8),
             Expanded(
               child: songs.isEmpty
              ? const Center(
                  child: Text('No Liked Songs so far'),
                )
              : ListView.separated(
                  itemBuilder: (context, index) => ListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PlayerScreen(
                            song: songs[index],
                          ),
                        ),
                      );
                    },
                    title: Row(
                      children: [
                        Text(
                          songs[index].title,
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 0,
                          ),
                          width: 8,
                          height: 1,
                          color: Colors.white,
                        ),
                        Text(
                          songs[index].artist,
                        ),
                      ],
                    ),
                    subtitle: Text(songs[index].genre),
                  ),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 20),
                  itemCount: songs.length,
                ),
             ),
        ),
      ),
    );
  }
}

class LikedLocals extends StatefulWidget {
  const LikedLocals({
    Key? key,
    required this.songs,
  }) : super(key: key);
  final List<Song> songs;
  @override
  State<LikedLocals> createState() => _LikedLocalsState();
}

class _LikedLocalsState extends State<LikedLocals> {
  late List<Song> locals;
  late SongProvider songProv;

  @override
  void initState() {
    super.initState();
    songProv = Provider.of<SongProvider>(context, listen: false);
    fetchLocals();
  }

  void fetchLocals() async {
    songProv.fetchLocalsFromStorage();
    //locals = songProv.likedLocals;
    locals = widget.songs;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    fetchLocals();
    return Consumer<SongProvider>(
      builder: (context, songProvider, child) => SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: locals.isEmpty
              ? const Center(
                  child: Text('No Liked Local Songs so far'),
                )
              : ListView.separated(
                  itemBuilder: (context, index) => ListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PlayerScreen(
                            song: locals[index],
                            isLocal: true,
                          ),
                        ),
                      );
                    },
                    title: Row(
                      children: [
                        Text(
                          locals[index].title,
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 0,
                          ),
                          width: 8,
                          height: 1,
                          color: Colors.white,
                        ),
                        Text(
                          locals[index].artist,
                        ),
                      ],
                    ),
                    subtitle: Text(locals[index].genre),
                  ),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 20),
                  itemCount: locals.length,
                ),
        ),
      ),
    );
  }
}
