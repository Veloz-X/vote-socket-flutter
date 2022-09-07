class Candidate {
  String id;
  String name;
  int votes;
  
  Candidate({
    required this.id,
    required this.name,
    required this.votes,
  });

  factory Candidate.fromMap(Map<String, dynamic> obj) => Candidate(
    id: obj.containsKey('id')?obj["id"]:'no-id',
    name: obj.containsKey('name')?obj["name"]:'no-name',
    votes: obj.containsKey('votes')?obj["votes"]: 'no-votes',
  );
}