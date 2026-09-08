import 'package:flutter/material.dart';
import 'mahasiswa.dart';
import 'Lyrik.dart';

void main() {
  runApp(const Hafiz());
}

class Hafiz extends StatelessWidget {
  const Hafiz({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final Mahasiswa mahasiswa = Mahasiswa(nama: 'Hafiz', umur: 20, kelas: 'TI-2A');
    final lyrik = lagu(
      judul: 'Heaven Can\'t Wait',
      penyanyi: 'Michael Jackson',
      lirik:  '''Tell the Angels no, I don't wanna leave my baby
      That's a chance I'll take, baby I'll stay, Heaven can wait
      No, if the angels took me from this Earth
      I would tell 'em "Bring me back to her"
      It's a chance I'll take, maybe I'll stay
      Heaven can wait
      ... ''',
    );
    final lyrik2 = lagu(
      lirik: '''(You're beautiful, you're wonderful, incredible, I love you so)
You're beautiful
Each moment spent with you is simply wonderful
This love I have for you, girl, it's incredible (Incredible)
And I don't know what I'd do if I can't be with you
The world could not go on, so every night I pray
If the Lord should come for me before I wake
I wouldn't wanna go if I can't see your face, can't hold you close
What good would Heaven be?
If the angels came for me, I'd tell them, "No"'''
    );
    final lyrik3 = lagu(
      lirik: '''No, I don't wanna leave my baby alone
I don't want nobody else to hold you
That's the chance I'll take
Baby, I'll stay, Heaven can wait
No (No), if the angels took me from this Earth
I would tell them, "Bring me back to her"
It's a chance I'll take, maybe I'll stay
Heaven can wait''',
    );

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('${lyrik.judul} - ${lyrik.penyanyi}'),
        ),
        body: Padding (
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${lyrik.lirik}', textAlign: TextAlign.left, style: TextStyle(color: Colors.black, fontSize: 14.0) ),
              SizedBox(height: 10),
              Text('${lyrik2.lirik}', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 14.0)),
              SizedBox(height: 10),
              Text('${lyrik3.lirik}', textAlign: TextAlign.left, style: TextStyle(color: Colors.black, fontSize: 14.0)),

            ],

          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Container(
            height: 25.0,
            color: Colors.blue,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(width: 5.0),
                  Icon(Icons.arrow_back, color: Colors.white,),
                  Icon(Icons.pause, color: Colors.white,),
                  Icon(Icons.arrow_forward, color: Colors.white,),
                  Icon(Icons.volume_up, color: Colors.white,),
                  Icon(Icons.volume_off, color: Colors.white,),
                  SizedBox(width: 5.0),
                  Text('Create by ${mahasiswa.nama}', style: TextStyle(color: Colors.white, fontSize: 12.0)),
                ],
              ),
            ),
          ),
      ),
      ),
    );
  }
}

