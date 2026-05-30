class ContractTerm {
  const ContractTerm({
    required this.term,
    required this.category,
    required this.simple,
    required this.legal,
    required this.tip,
  });

  final String term;
  final String category;
  final String simple;
  final String legal;
  final String tip;

  factory ContractTerm.fromMap(Map<String, String> map) {
    return ContractTerm(
      term: map['term']!,
      category: map['category']!,
      simple: map['simple']!,
      legal: map['legal']!,
      tip: map['tip']!,
    );
  }
}
