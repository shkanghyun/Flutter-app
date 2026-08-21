import 'package:flutter/material.dart';
import 'package:subway/stations.dart';

class StationSearchSheet extends StatefulWidget {
  const StationSearchSheet({super.key, required this.onSelect});

  final ValueChanged<Station> onSelect;

  @override
  State<StationSearchSheet> createState() => _StationSearchSheetState();
}

class _StationSearchSheetState extends State<StationSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = stations
        .where((station) => station.matches(_query))
        .toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9DFED),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search stations',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF1F4FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final station = results[index];
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 5,
                      ),
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: station.color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.subway_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                      title: Text(
                        station.englishName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        station.lines.map((line) => line.name).join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelect(station);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}