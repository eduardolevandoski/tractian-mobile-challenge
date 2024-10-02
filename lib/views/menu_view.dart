import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tractian_mobile_challenge/viewmodels/menu_viewmodel.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  MenuViewmodel menuViewmodel = MenuViewmodel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/tractian.png', height: 17.0),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: FutureBuilder<void>(
          future: menuViewmodel.fetchCompanies(),
          builder: (context, snapshot) {
            return Skeletonizer(
              enabled: snapshot.connectionState == ConnectionState.waiting,
              child: ListView.separated(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: menuViewmodel.companies.length,
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(height: 5.0);
                },
                itemBuilder: (BuildContext context, int index) {
                  return Skeleton.leaf(
                    child: ListTile(
                      title: Material(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(5),
                        child: InkWell(
                          onTap: () {},
                          child: Container(
                            padding: EdgeInsets.all(20.0),
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(Icons.apartment, color: Colors.white),
                                const SizedBox(width: 12.5),
                                Text(
                                  "${menuViewmodel.companies[index].name} Unit",
                                  style: TextStyle(fontSize: 18.0, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
