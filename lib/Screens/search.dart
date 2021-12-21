import 'package:flutter/material.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:neverlost_beta/Screens/userprofile.dart';

class Search extends StatefulWidget {
  final user;
  const Search({Key? key, required this.user}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final searchController = TextEditingController();
  List ispressed = [true, false];
  List<IconData> iconState = [Icons.person, Icons.email_rounded, Icons.phone];
  int currentIndex = 0;
  List<String> listState = ['name', 'email'];
  late Stream searchStream;
  bool isSearching = false;
  @override
  void initState() {
    super.initState();
  }

  void onpress(int index) {
    if (!ispressed[index]) {
      setState(() {
        ispressed[index] = true;
        ispressed[currentIndex] = false;
        currentIndex = index;
      });
    }
    onsearch();
  }

  void onsearch() async {
    isSearching = searchController.text != '' ? true : false;

    switch (listState[currentIndex]) {
      case 'name':
        searchStream =
            await DatabaseMethods().searchByName(searchController.text);
        break;
      case 'email':
        searchStream =
            await DatabaseMethods().searchByEmail(searchController.text);
        break;
    }

    setState(() {});
  }

  Widget searchList() {
    return StreamBuilder(
      stream: searchStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  var ds = snapshot.data.docs[index];
                  return ds['email'] != widget.user['email']
                      ? Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ListTile(
                            onTap: () {
                              FocusScopeNode currentFocus =
                                  FocusScope.of(context);
                              if (!currentFocus.hasPrimaryFocus) {
                                currentFocus.unfocus();
                              }
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => UserProfile(
                                            currentUser: widget.user,
                                            searchedUser: ds,
                                          )));
                            },
                            leading: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: Image.network(ds['photoURL'])),
                            title: Text(ds['name'],
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(ds['email'],
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Icon(Icons.chevron_right_rounded),
                          ),
                        )
                      : Text('');
                },
              )
            : Text('NO result found');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: backgroundColor2,
      body: SizedBox(
        width: width,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                decoration: BoxDecoration(
                    color: backgroundColor1.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(
                          iconState[currentIndex],
                          color: backgroundColor1,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                            controller: searchController,
                            cursorColor: backgroundColor1,
                            cursorHeight: 20,
                            onChanged: (value) async {
                              onsearch();
                            },
                            style: const TextStyle(
                                color: backgroundColor1, fontSize: 18),
                            decoration: InputDecoration(
                                hintText:
                                    'Search by ${listState[currentIndex]}',
                                hintStyle: const TextStyle(
                                    color: Colors.grey, fontSize: 16),
                                border: InputBorder.none,
                                helperStyle:
                                    const TextStyle(color: backgroundColor1))),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: InkWell(
                          onTap: () async {
                            searchController.clear();
                            setState(() {
                              isSearching = false;
                            });
                          },
                          child: Icon(
                            searchController.text != ''
                                ? Icons.close
                                : Icons.search,
                            color: iconColor1,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Container(
                decoration: BoxDecoration(
                    color: backgroundColor1,
                    borderRadius: BorderRadius.circular(8)),
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: ispressed[0]
                              ? backgroundColor2
                              : backgroundColor1,
                          borderRadius: BorderRadius.circular(6)),
                      height: 40,
                      width: 80,
                      child: TextButton(
                          onPressed: () {
                            onpress(0);
                          },
                          style: ButtonStyle(
                            overlayColor: MaterialStateColor.resolveWith(
                                (states) => backgroundColor2.withOpacity(0.2)),
                          ),
                          child: Text('name',
                              style: TextStyle(
                                  color: ispressed[0]
                                      ? backgroundColor1
                                      : backgroundColor2))),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          color: ispressed[1]
                              ? backgroundColor2
                              : backgroundColor1,
                          borderRadius: BorderRadius.circular(5)),
                      height: 40,
                      width: 80,
                      child: TextButton(
                          style: ButtonStyle(
                            overlayColor: MaterialStateColor.resolveWith(
                                (states) => backgroundColor2.withOpacity(0.2)),
                          ),
                          onPressed: () {
                            onpress(1);
                          },
                          child: Text(
                            'email',
                            style: TextStyle(
                                color: ispressed[1]
                                    ? backgroundColor1
                                    : backgroundColor2),
                          )),
                    ),
                  ],
                ),
              ),
            ),
            isSearching
                ? Expanded(child: searchList())
                : Expanded(child: Text('Search Your Friends here'))
          ],
        ),
      ),
    );
  }
}
