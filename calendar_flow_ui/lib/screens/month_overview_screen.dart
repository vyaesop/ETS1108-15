import 'package:flutter/material.dart';

import '../mock_data.dart';

class MonthOverviewScreen extends StatelessWidget {
  final ValueChanged<int> onMonthTap;

  const MonthOverviewScreen({super.key, required this.onMonthTap});

  @override
  Widget build(BuildContext context) {
    final months = const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const BackButton(),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search dates or events',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.08,
                ),
                itemBuilder: (context, index) {
                  final color = MockData.monthPalette[index];
                  return InkWell(
                    onTap: () => onMonthTap(index),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(months[index], style: TextStyle(color: Colors.white.withOpacity(.95), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _MiniCalendar(color: Colors.white.withOpacity(.85)),
                        ],
                      ),
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

class _MiniCalendar extends StatelessWidget {
  final Color color;

  const _MiniCalendar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: 'SMTWTFS'.split('').map((e) => Text(e, style: TextStyle(color: color, fontSize: 9))).toList()),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 35,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemBuilder: (_, index) => Center(
                child: Text(
                  index % 31 == 0 ? '' : '${(index % 31) + 1}',
                  style: TextStyle(fontSize: 8, color: color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
