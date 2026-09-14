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
    final Mahasiswa mahasiswa = Mahasiswa(nama: 'Hafiz', umur: 20, kelas: 'TI-3C');
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
    final lyrik4 = lagu(
      lirik: '''Unthinkable
Me sittin' up in the clouds and you are all alone
The time might come around when you'd be movin' on (Movin' on)
I'd turn it all around and try to get back down to my baby girl
Can't stand to see nobody kissin', touchin' her
Couldn't take nobody lovin' you the way we were
What good would Heaven be?
If the angels come for me, I'd tell them, "No"''',
    );
    final lyrik5 = lagu(
      lirik: '''No (Yeah), I don't wanna leave my baby alone (My baby)
I don't want nobody else to hold you (Don't you do this to me)
That's a chance I'll take (If the angels come around, just tell 'em to bring me down to my baby)
Baby, I'll stay, Heaven can wait
No, if the angels took me from this Earth (Don't you do this to me)
I would tell 'em, "Bring me back to her" (Heaven can wait)
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
          centerTitle: true,
          backgroundColor: Colors.orange,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24.0)),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                onTap: () {
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: 'Flutter Demo',
                    applicationVersion: '1.0.0',
                    applicationIcon: Icon(Icons.flutter_dash),
                    children: [
                      Text('This is a demo application for Flutter.'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        body: Padding (
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
          child: ClipRRect(
            child: Image.asset(
              'assets/images/heaven.png',
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),
          ),
        ),

      SizedBox(height: 15),
              Text('${lyrik.lirik}', textAlign: TextAlign.left, style: TextStyle(color: Colors.black, fontSize: 14.0, backgroundColor: Colors.greenAccent)),
              SizedBox(height: 10),
              Text('${lyrik2.lirik}', textAlign: TextAlign.left, style: TextStyle(color: Colors.black, fontSize: 14.0, backgroundColor: Colors.yellowAccent)),
              SizedBox(height: 10),
              Text('${lyrik3.lirik}', textAlign: TextAlign.left, style: TextStyle(color: Colors.black, fontSize: 14.0, backgroundColor: Colors.blueAccent)),
              SizedBox(height: 10),
              Text('${lyrik4.lirik}', textAlign: TextAlign.left, style: TextStyle(color: Colors.black, fontSize: 14.0, backgroundColor: Colors.purpleAccent)),
              SizedBox(height: 10),
              Text('${lyrik5.lirik}', textAlign: TextAlign.left, style: TextStyle(color: Colors.black, fontSize: 14.0, backgroundColor: Colors.redAccent)),
            ],

          ),
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
                  Icon(Icons.skip_previous, color: Colors.black,),
                  Icon(Icons.pause, color: Colors.black,),
                  Icon(Icons.skip_next, color: Colors.black,),
                  Icon(Icons.volume_up, color: Colors.black,),
                  Icon(Icons.volume_off, color: Colors.black,),
                  SizedBox(width: 5.0),
                  Text('Create by ${mahasiswa.nama}', style: TextStyle(color: Colors.black, fontSize: 12.0)),
                ],
              ),
            ),
          ),
      ),
      ),
    );
  }
}

