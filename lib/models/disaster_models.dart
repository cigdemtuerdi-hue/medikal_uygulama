/// Active disaster / crisis relief zone for Emergency Response Mode.
class DisasterZone {
  const DisasterZone({
    required this.id,
    required this.name,
    required this.state,
    required this.zipCodes,
    required this.hubName,
    required this.hubAddress,
    required this.fieldTeamContact,
    required this.priorityNeeds,
  });

  final String id;
  final String name;
  final String state;
  final List<String> zipCodes;
  final String hubName;
  final String hubAddress;
  final String fieldTeamContact;
  final List<String> priorityNeeds;

  bool coversZip(String zip) {
    final five = zip.trim().length >= 5 ? zip.trim().substring(0, 5) : zip.trim();
    return zipCodes.contains(five);
  }
}
