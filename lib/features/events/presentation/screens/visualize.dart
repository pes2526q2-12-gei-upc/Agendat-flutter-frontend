import 'package:flutter/material.dart';

class VisualizeScreen extends StatelessWidget {
  const VisualizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: Column(
        children: [
          searchBar(),
          filterButton(),
        ],
      )
    );
  }

  Align filterButton() {
    return Align(
          alignment: Alignment.centerLeft,
          child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 12),
              child: ElevatedButton(
                  onPressed: () {
                    // vale no se si obrir un desplegablke o que
                  },
              child: const Text('Filtres'),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            "Agenda't",
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Cultura a un clic',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0.0,
      centerTitle: false,
      //faltarà botó configuració
    );
  }
}