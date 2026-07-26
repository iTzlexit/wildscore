/// IUCN Red List category.
enum ConservationStatus {
  leastConcern(label: 'Least Concern', code: 'LC', isThreatened: false),
  nearThreatened(label: 'Near Threatened', code: 'NT', isThreatened: false),
  vulnerable(label: 'Vulnerable', code: 'VU', isThreatened: true),
  endangered(label: 'Endangered', code: 'EN', isThreatened: true),
  criticallyEndangered(
    label: 'Critically Endangered',
    code: 'CR',
    isThreatened: true,
  );

  const ConservationStatus({
    required this.label,
    required this.code,
    required this.isThreatened,
  });

  final String label;
  final String code;
  final bool isThreatened;
}
