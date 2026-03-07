import 'package:flutter/material.dart';

class FakeEvent {
  final String title;
  final String subtitle;
  final String date;
  final String place;
  final String category;
  final bool isFree;

  const FakeEvent({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.place,
    required this.category,
    required this.isFree,
  });
}

class VisualizeScreen extends StatelessWidget {
  const VisualizeScreen({super.key});

  static const List<FakeEvent> _fakeEvents = [
    FakeEvent(
      title: 'Festival de Jazz',
      subtitle: 'Concert en viu amb artistes locals.',
      date: '14/03/2026 21:00',
      place: 'Girona',
      category: 'Musica',
      isFree: true,
    ),
    FakeEvent(
      title: 'Teatre Modern',
      subtitle: 'Comedia en catala per a tots els publics.',
      date: '19/03/2026 18:30',
      place: 'Barcelona',
      category: 'Teatre',
      isFree: false,
    ),
    FakeEvent(
      title: 'Mercat d\'Art',
      subtitle: 'Exposicio i venda d\'obra d\'art emergent.',
      date: '21/03/2026 11:00',
      place: 'Tarragona',
      category: 'Art',
      isFree: true,
    ),
    FakeEvent(
      title: 'Cinema a la Fresca',
      subtitle: 'Projeccio nocturna a l\'aire lliure.',
      date: '27/03/2026 22:00',
      place: 'Lleida',
      category: 'Cinema',
      isFree: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: Column(
        children: [
          searchBar(),
          filterButton(),
          const SizedBox(height: 12),
          Expanded(child: eventsList(_fakeEvents)),
        ],
      )
    );
  }

  Widget eventsList(List<FakeEvent> events) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => eventCard(events[index]),
    );
  }

  Widget eventCard(FakeEvent event) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color.fromARGB(255, 190, 0, 47),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: 
                eventTitle(event),
              ),
              const SizedBox(width: 10),
              eventCategory(event),
            ],
          ),
          const SizedBox(height: 4),
          eventSubtitle(event),
          const SizedBox(height: 10),
          Row(
            children: [
              eventDate(event),
              const Spacer(),
              eventPayment(event),
            ],
          ),
          const SizedBox(height: 4),
          eventPlace(event),
        ],
      ),
    );
  }

  Text eventPlace(FakeEvent event) {
    return Text(
          'Lloc: ${event.place}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        );
  }

  Text eventPayment(FakeEvent event) {
    return Text(
              event.isFree ? 'Gratuit' : 'De pagament',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            );
  }

  Text eventDate(FakeEvent event) {
    return Text(
              'Data: ${event.date}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            );
  }

  Text eventSubtitle(FakeEvent event) {
    return Text(
          event.subtitle,
          style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 109, 109, 109)),
        );
  }

  Container eventCategory(FakeEvent event) {
    return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 190, 0, 47),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                event.category,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
  }

  Text eventTitle(FakeEvent event) {
    return Text(
                event.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );
  }

  Align filterButton() {
    return Align(
          alignment: Alignment.centerLeft,
          child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 12),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 190, 0, 47),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // vale no se si obrir un desplegable o que
                  },
              child: const Text(
                'Filtres',
                style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
         );
  }

  Container searchBar() {
    return Container(
          margin: EdgeInsets.only(top: 40, left:20, right:20),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color(0xff1D1617).withOpacity(0.11),
                blurRadius: 40,
                spreadRadius: 0.0
              )
            ]
          ),
          child: TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.all(15),
              //afegir icono de cerca
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none
              )
            )
          ),
    );
  }

  AppBar appBar() { //text gran Agenda't
    return AppBar(
      title: const Text(
            "Agenda't",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
      backgroundColor: Colors.white,
      elevation: 0.0,
      centerTitle: false,
      //faltarà botó configuració
    );
  }
}