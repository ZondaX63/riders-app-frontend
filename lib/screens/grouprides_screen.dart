import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GroupRidesScreen extends StatefulWidget {
	const GroupRidesScreen({super.key});

	@override
	State<GroupRidesScreen> createState() => _GroupRidesScreenState();
}

class _GroupRidesScreenState extends State<GroupRidesScreen> {
	final List<String> _filters = ['Yakındakiler', 'Bu Hafta', 'Benim Yakınlarım', 'Popüler'];
	int _selectedFilter = 0;

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Group Rides'),
				actions: [
					IconButton(onPressed: () {}, icon: const Icon(Icons.search))
				],
			),
			body: Column(
				children: [
					const SizedBox(height: 12),
					SingleChildScrollView(
						scrollDirection: Axis.horizontal,
						padding: const EdgeInsets.symmetric(horizontal: 16),
						child: Row(
							children: List.generate(_filters.length, (i) {
								final selected = i == _selectedFilter;
								return Padding(
									padding: const EdgeInsets.only(right: 8.0),
									child: ChoiceChip(
										label: Text(_filters[i]),
										selected: selected,
										onSelected: (_) => setState(() => _selectedFilter = i),
										selectedColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
										labelStyle: TextStyle(color: selected ? AppTheme.primaryOrange : Colors.white),
										shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
										backgroundColor: AppTheme.lightGrey,
									),
								);
							}),
						),
					),
					const SizedBox(height: 8),
					Expanded(
						child: ListView.separated(
							padding: const EdgeInsets.all(16),
							itemCount: 8,
							separatorBuilder: (_, __) => const SizedBox(height: 12),
							itemBuilder: (context, index) => _RideCard(index: index),
						),
					),
				],
			),
			floatingActionButton: FloatingActionButton.extended(
				onPressed: () {},
				icon: const Icon(Icons.add),
				label: const Text('Create Ride'),
			),
		);
	}
}

class _RideCard extends StatelessWidget {
	final int index;
	const _RideCard({required this.index});

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				color: AppTheme.lightGrey,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					ClipRRect(
						borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
						child: AspectRatio(
							aspectRatio: 16/9,
							child: Image.network(
								'https://lh3.googleusercontent.com/aida-public/AB6AXuARSJCKIgBNIN6uvNSCKcSR00GebqpGYURwdE3pinP4b4L2ReG6PjzLFAOAg-JsBKiKY1YcE1ITh79msY2GcnFh1ayJlwguGcQ7H5XbFFyF_lCgfkeqdjpIkTb9wg_kdi3rOcnFA8gb4rWGcjalY-3mofcZWpg8gejtm-Ix7VLNjICCk9LXe58s4vC2c1mu6rfBUl57hE0961qFFH5FeVkYlA8UPaBtUPuwtGalifVqT1SlbIX4E5yzbIpRYLebupxeqDy4BxT_aVQ',
								fit: BoxFit.cover,
							),
						),
					),
					Padding(
						padding: const EdgeInsets.all(16),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Row(
									children: [
										Expanded(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													const Text('Coastal Highway Run', style: TextStyle(fontWeight: FontWeight.w700)),
													const SizedBox(height: 4),
													Text('San Francisco, CA • 150 miles', style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
												],
											),
										),
									const Icon(Icons.people_alt_outlined, color: Colors.white70),
									const SizedBox(width: 6),
									const Text('12', style: TextStyle(fontWeight: FontWeight.w600)),
								],
							),
							const SizedBox(height: 10),
							Row(children: [
								const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
								const SizedBox(width: 6),
								Text('Sun, Oct 27 @ 9:00 AM', style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
								const SizedBox(width: 16),
								const Icon(Icons.place, size: 16, color: Colors.white70),
								const SizedBox(width: 6),
								Text('San Francisco, CA', style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
							]),
							const SizedBox(height: 12),
							Row(children: [
								Expanded(
									child: OutlinedButton.icon(
										onPressed: () {},
										icon: const Icon(Icons.info_outline),
										label: const Text('Details'),
										style: OutlinedButton.styleFrom(
											side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
											foregroundColor: Colors.white,
											shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
										),
									),
								),
								const SizedBox(width: 10),
								Expanded(
									child: ElevatedButton.icon(
										onPressed: () {},
										icon: const Icon(Icons.check_circle_outline),
										label: const Text('Join'),
									),
								)
							])
						],
					),
					),
				],
			),
		);
	}
}



