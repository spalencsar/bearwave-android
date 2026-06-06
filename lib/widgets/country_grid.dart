import 'package:flutter/material.dart';
import '../models/country.dart';
import '../theme/bearwave_theme.dart';

class CountryGrid extends StatelessWidget {
  final List<Country> countries;
  final ValueChanged<Country> onCountryTap;
  final bool compact;
  final ScrollPhysics? physics;

  const CountryGrid({
    super.key,
    required this.countries,
    required this.onCountryTap,
    this.compact = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = compact ? 1 : 2;
    
    return GridView.builder(
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: compact ? 3.5 : 2.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: countries.length,
      itemBuilder: (context, index) {
        final country = countries[index];
        return _buildCountryCard(country);
      },
    );
  }

  Widget _buildCountryCard(Country country) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onCountryTap(country),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: BearWaveTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BearWaveTheme.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(
                BearWaveTheme.getFlagEmoji(country.code),
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      country.name,
                      style: const TextStyle(
                        color: BearWaveTheme.textMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${country.stationCount} stations',
                      style: const TextStyle(
                        color: BearWaveTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}