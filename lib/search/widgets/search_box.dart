import 'package:flutter/material.dart';
import '../recent_searches_service.dart';

class SearchBox extends StatefulWidget {
  const SearchBox({Key? key}) : super(key: key);

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> _recent = [];
  bool _showRecent = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && mounted) {
        setState(() => _showRecent = false);
      }
    });
    _loadRecent();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final service = RecentSearchesService();
    final items = await service.getRecentSearches();
    if (!mounted) return;
    setState(() {
      _recent = items;
    });
  }

  Future<void> _onSubmit(String value) async {
    final service = RecentSearchesService();
    await service.addSearchTerm(value.trim());
    await _loadRecent();
    setState(() => _showRecent = false);
    // TODO: Hook into actual search logic
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 40,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(
                  Icons.search,
                  color: Colors.black,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Artists, songs or podcasts',
                    ),
                    onChanged: (_) => setState(() => _showRecent = true),
                    onSubmitted: _onSubmit,
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.black),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _showRecent = false);
                    },
                  ),
              ],
            ),
          ),
        ),
        if (_showRecent && _recent.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Recent searches'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: _recent
                .map((term) => ActionChip(
                      label: Text(term),
                      onPressed: () => _onSubmit(term),
                    ))
                .toList(),
          ),
          TextButton(
            onPressed: () async {
              final service = RecentSearchesService();
              await service.clear();
              await _loadRecent();
              setState(() => _showRecent = false);
            },
            child: const Text('Clear recent'),
          )
        ]
      ],
    );
  }
}
