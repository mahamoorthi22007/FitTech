import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Section Label ───────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.brick,
            letterSpacing: 1.2,
          ),
        ),
      );
}

// ─── Mini Scroll Card ─────────────────────────────────────────────────────────
class MiniScrollCard extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback? onTap;
  const MiniScrollCard({super.key, required this.emoji, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 90,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blushLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.espresso), maxLines: 2),
            ],
          ),
        ),
      );
}

// ─── Feature Row Card ─────────────────────────────────────────────────────────
class FeatureRowCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool aiTag;
  final VoidCallback? onTap;
  const FeatureRowCard({super.key, required this.emoji, required this.title, required this.subtitle, this.aiTag = false, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: AppColors.blushLight, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.espresso)),
                      if (aiTag) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.dustyRose, borderRadius: BorderRadius.circular(8)),
                          child: const Text('AI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.brick)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 2),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.dustyRose, size: 22),
            ],
          ),
        ),
      );
}

// ─── Primary Button ───────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool fullWidth;
  const PrimaryButton({super.key, required this.label, this.onTap, this.fullWidth = true});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: SizedBox(
          width: fullWidth ? double.infinity : null,
          child: ElevatedButton(onPressed: onTap, child: Text(label)),
        ),
      );
}

// ─── Upload Zone ──────────────────────────────────────────────────────────────
class UploadZone extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onTap;
  const UploadZone({super.key, required this.emoji, required this.title, required this.subtitle, required this.buttonText, this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.dustyRose, width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.espresso)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: Text(buttonText),
            ),
          ],
        ),
      );
}

// ─── Filter Chip Row ──────────────────────────────────────────────────────────
class FilterChipRow extends StatefulWidget {
  final List<String> items;
  const FilterChipRow({super.key, required this.items});

  @override
  State<FilterChipRow> createState() => _FilterChipRowState();
}

class _FilterChipRowState extends State<FilterChipRow> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: widget.items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selected == i ? AppColors.brick : AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _selected == i ? AppColors.brick : AppColors.divider),
              ),
              child: Text(
                widget.items[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _selected == i ? AppColors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      );
}

// ─── Selectable Pill ─────────────────────────────────────────────────────────
class SelectablePillRow extends StatefulWidget {
  final List<String> items;
  final ValueChanged<String>? onSelected;
  const SelectablePillRow({super.key, required this.items, this.onSelected});

  @override
  State<SelectablePillRow> createState() => _SelectablePillRowState();
}

class _SelectablePillRowState extends State<SelectablePillRow> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(widget.items.length, (i) {
            final active = _selected == i;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = i);
                widget.onSelected?.call(widget.items[i]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.dustyRose : AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: active ? AppColors.terracotta : AppColors.divider),
                ),
                child: Text(
                  widget.items[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: active ? AppColors.brick : AppColors.textMuted,
                  ),
                ),
              ),
            );
          }),
        ),
      );
}

// ─── Top App Bar ─────────────────────────────────────────────────────────────
class SilaiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  const SilaiAppBar({super.key, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) => AppBar(
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Silai',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.espresso,
                ),
              ),
              TextSpan(
                text: ' ✦',
                style: TextStyle(fontSize: 16, color: AppColors.terracotta),
              ),
            ],
          ),
        ),
        actions: actions ??
            [
              IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
              IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.blushLight,
                  child: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.brick),
                ),
              ),
            ],
      );
}

// ─── Progress Step Bar ────────────────────────────────────────────────────────
class StepProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final String label;
  const StepProgressBar({super.key, required this.current, required this.total, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.terracotta)),
                Text('Step $current of $total', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: current / total,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.terracotta),
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
}
