import 'package:flutter/material.dart';
import 'package:tractian_mobile_challenge/viewmodels/menu_viewmodel.dart';
import 'package:tractian_mobile_challenge/views/assets_view.dart';

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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else {
              return ListView.separated(
                padding: const EdgeInsets.only(top: 10.0),
                itemCount: menuViewmodel.companies.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Material(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(5.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssetsView(company: menuViewmodel.companies[index]),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20.0),
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
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(height: 5.0);
                },
              );
            }
          },
        ),
      ),
    );
  }
}
