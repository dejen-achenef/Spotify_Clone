import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spotify_clone/homepage/services/api.dart';
import 'package:spotify_clone/providers/song_provider.dart';

import '../models/song.dart';

class PlayerScreen extends StatefulWidget {
  final String? heroTag;
  PlayerScreen({
    super.key,
    this.isLocal,
    required this.song,
  });

  final Song song;
  bool? isLocal;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late File songFile;
  bool isLiked = false;
  bool isDisliked = false;

  late SongProvider songProvider;
  @override
  void initState() {
    super.initState();
    bool isLocal = widget.isLocal ?? false;

    if (isLocal) {
      fetchSongLocal();
    } else {
      fetchSong();
    }
    songProvider = Provider.of<SongProvider>(context, listen: false);

    // initialize liked state from provider storage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exists = songProvider.likedSongs.any(
          (s) => s.artist == widget.song.artist && s.title == widget.song.title);
      setState(() {
        isLiked = exists;
      });
    });
  }

  void fetchSong() async {
    var api = Api();
    String path = await api.fetchSongFile(widget.song);
    File audioFile = File(path);

    setState(() {
      songFile = audioFile;
    });
  }

  void fetchSongLocal() async {
    var api = Api();
    String path = await api.fetchSongFileLocal(widget.song);
    File audioFile = File(path);

    setState(() {
      songFile = audioFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<SongProvider>(
        builder: (context, songProvider, child) {
          int secs = songProvider.secondsDuration;
          int mins = songProvider.minutesDuration;
          return SafeArea(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.brown,
                    Colors.brown.shade300,
                    Colors.brown.shade300,
                    Colors.black,
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              // Provider.of<SongProvider>(context, listen: false).setPlaying(
                              //   widget.song,
                              //   audioPlayer,
                              //   _position,
                              //   _duration,
                              // );
                              //songProvider.playSong(songFile);
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back_ios),
                          ),

                          const Spacer(),
                          Text(
                            'Playing Song',
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),

                          //PopupMenuButton(itemBuilder: (context)=>)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () {
                                  Share.share(
                                    'Listening to ${widget.song.title} by ${widget.song.artist}\n${widget.song.audioUrl ?? ''}',
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(songProvider.isMuted ? Icons.volume_off : Icons.volume_up),
                                onPressed: () {
                                  songProvider.toggleMute();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.timer),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => ListView(
                                      shrinkWrap: true,
                                      children: [
                                        ListTile(
                                          title: const Text('15 minutes'),
                                          onTap: () {
                                            songProvider.startSleepTimer(Duration(minutes: 15));
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Sleep timer set for 15 minutes')),
                                            );
                                          },
                                        ),
                                        ListTile(
                                          title: const Text('30 minutes'),
                                          onTap: () {
                                            songProvider.startSleepTimer(Duration(minutes: 30));
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Sleep timer set for 30 minutes')),
                                            );
                                          },
                                        ),
                                        ListTile(
                                          title: const Text('60 minutes'),
                                          onTap: () {
                                            songProvider.startSleepTimer(Duration(minutes: 60));
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Sleep timer set for 60 minutes')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      //const Spacer(),
                      const SizedBox(height: 50),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * .8,
                          height: MediaQuery.of(context).size.width * .8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                widget.song.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 10),
                                      Text(
                                        widget.song.artist,
                                        style: GoogleFonts.montserrat(
                                          textStyle: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        widget.song.title,
                                        style: GoogleFonts.montserrat(
                                          textStyle: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          songProvider.shuffle ? Icons.shuffle_on : Icons.shuffle,
                                          size: 20,
                                        ),
                                        onPressed: () => songProvider.toggleShuffle(),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          songProvider.repeatMode == RepeatMode.off
                                              ? Icons.repeat
                                              : songProvider.repeatMode == RepeatMode.all
                                                  ? Icons.repeat_on
                                                  : Icons.repeat_one_on,
                                          size: 20,
                                        ),
                                        onPressed: () => songProvider.cycleRepeatMode(),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.queue_music, size: 20),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (_) => StatefulBuilder(
                                              builder: (context, setModal) => ListView(
                                                children: [
                                                  const ListTile(title: Text('Up Next')),
                                                  ...songProvider.queue.asMap().entries.map(
                                                    (e) => ListTile(
                                                      title: Text('${e.value.title} • ${e.value.artist}'),
                                                      trailing: IconButton(
                                                        icon: const Icon(Icons.remove_circle_outline),
                                                        onPressed: () {
                                                          songProvider.queue.removeAt(e.key);
                                                          setModal(() {});
                                                          setState(() {});
                                                        },
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    bool isLocal = widget.isLocal ?? false;
                                    if (!isLiked) {
                                      if (isLocal) {
                                        songProvider.likeLocal(widget.song);
                                      } else {
                                        songProvider.likeSong(widget.song);
                                      }
                                      HapticFeedback.lightImpact();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Added to Liked Songs')),
                                      );
                                    }

                                    if (isDisliked) {
                                      isDisliked = false;
                                    }
                                    isLiked = !isLiked;
                                    setState(() {});
                                  },
                                  icon: Icon(
                                    isLiked
                                        ? Icons.thumb_up
                                        : Icons.thumb_up_outlined,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  onPressed: () {
                                    if (!isDisliked) {
                                      isLiked = !isLiked;
                                      bool isLocal = widget.isLocal ?? false;
                                      if (isLocal) {
                                        songProvider.dislikeLocal(widget.song);
                                      } else {
                                        songProvider.dislikeSong(widget.song);
                                      }
                                      HapticFeedback.lightImpact();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Removed from Liked Songs')),
                                      );
                                    }

                                    if (isLiked) {
                                      isLiked = false;
                                    }
                                    setState(() {
                                      isDisliked = !isDisliked;
                                    });
                                  },
                                  icon: Icon(
                                    isDisliked
                                        ? Icons.thumb_down
                                        : Icons.thumb_down_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Slider(
                              activeColor: Colors.white,
                              inactiveColor: Colors.grey,
                              value: songProvider.position.inSeconds.toDouble(),
                              onChanged: (double value) {
                                songProvider.onPositionChanged(value.toInt());
                              },
                              min: 0,
                              max: songProvider.duration.inSeconds.toDouble(),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  mins < 10 ? '0$mins:' : '$mins:',
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  secs < 10 ? '0$secs' : '$secs',
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.skip_previous,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      // Implement skip to previous song logic
                                    },
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    icon: Icon(
                                      songProvider.playingIcon,
                                      size: 45,
                                    ),
                                    onPressed: () {
                                      if (!songProvider.isPlaying &&
                                          !songProvider.isPaused) {
                                        songProvider.playSong(
                                            songFile, widget.song);
                                      } else if (songProvider.isPlaying) {
                                        songProvider.pauseSong();
                                      } else if (songProvider.isPaused) {
                                        songProvider.resumeSong();
                                      }
                                    },
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.skip_next,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      // Implement skip to next song logic
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
