import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tractian_mobile_challenge/models/company.dart';
import 'package:tractian_mobile_challenge/viewmodels/assets_viewmodel.dart';

class AssetsView extends StatefulWidget {
  final Company company;

  AssetsView({Key? key, required this.company}) : super(key: key);

  @override
  State<AssetsView> createState() => _AssetsViewState();
}

class ChipData {
  final String label;
  final IconData icon;

  ChipData(this.label, this.icon);
}

class _AssetsViewState extends State<AssetsView> {
  AssetsViewmodel assetsViewmodel = AssetsViewmodel();
  TextEditingController searchController = TextEditingController();
  ScrollController scrollController = ScrollController();
  int selectedChipIndex = -1;
  bool isLoading = true;

  Stream<TreeNodeWithLevel>? nodeStream;
  StreamSubscription<TreeNodeWithLevel>? subscription;
  List<TreeNodeWithLevel> nodes = [];

  final List<ChipData> chipDataList = [
    ChipData("Sensor de Energia", Icons.bolt_outlined),
    ChipData("Crítico", Icons.error_outline),
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await assetsViewmodel.fetchAllData(companyId: widget.company.id);
    setState(() {
      isLoading = false;
    });

    _nodeStream();
  }

  void _nodeStream() {
    subscription?.cancel();

    if (searchController.text.isNotEmpty) {
      nodeStream = assetsViewmodel.generateSearchedTreeNodesWithLevel(
          searchController.text.toLowerCase(),
          selectedChipIndex == 0
              ? "operating"
              : selectedChipIndex == 1
                  ? "alert"
                  : null);
    } else if (selectedChipIndex != -1) {
      nodeStream = assetsViewmodel.generateFilteredTreeNodesWithLevel(selectedChipIndex == 0 ? "operating" : "alert");
    } else {
      nodeStream = assetsViewmodel.generateTreeNodesWithLevel();
    }

    nodes.clear();
    subscription = nodeStream!.listen((nodeWithLevel) {
      setState(() {
        nodes.add(nodeWithLevel);
      });
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.company.name} Assets"),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SearchTextFormField(),
                      const SizedBox(height: 5.0),
                      FilterChips(),
                    ],
                  ),
                ),
                Divider(),
                Expanded(child: TreeWidget()),
              ],
            ),
    );
  }

  Widget SearchTextFormField() {
    return TextFormField(
      controller: searchController,
      onChanged: (query) {
        _nodeStream();
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5.0),
          borderSide: BorderSide.none,
        ),
        fillColor: Colors.blueGrey.withOpacity(0.15),
        filled: true,
        isDense: true,
        hintText: "Buscar Ativo ou Local",
        hintStyle: TextStyle(color: Colors.black38),
        prefixIcon: Icon(Icons.search, color: Colors.black38),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget FilterChips() {
    return Wrap(
      spacing: 8.0,
      children: List<Widget>.generate(chipDataList.length, (index) {
        return ChoiceChip(
          selected: selectedChipIndex == index,
          backgroundColor: Colors.transparent,
          selectedColor: Colors.blue,
          labelPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
            side: BorderSide(
              color: selectedChipIndex == index ? Colors.transparent : Colors.black12,
            ),
          ),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                chipDataList[index].icon,
                color: selectedChipIndex == index ? Colors.white : Colors.black38,
                size: 20.0,
              ),
              const SizedBox(width: 5.0),
              Text(
                chipDataList[index].label,
                style: TextStyle(
                  fontSize: 15.0,
                  color: selectedChipIndex == index ? Colors.white : Colors.black38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          onSelected: (selected) {
            setState(() {
              if (selectedChipIndex == index) {
                selectedChipIndex = -1;
              } else {
                selectedChipIndex = index;
              }
              _nodeStream();
            });
          },
        );
      }),
    );
  }

  Widget TreeWidget() {
    return Scrollbar(
      child: ListView.builder(
        itemCount: nodes.length,
        controller: scrollController,
        itemBuilder: (context, index) {
          TreeNodeWithLevel nodeWithLevel = nodes[index];
          return TreeNodes(nodeWithLevel, index);
        },
      ),
    );
  }

  Widget TreeNodes(TreeNodeWithLevel nodeWithLevel, int index) {
    TreeNode node = nodeWithLevel.node;
    int level = nodeWithLevel.level;

    bool hasChildren = false;
    if (index + 1 < nodes.length) {
      if (nodes[index + 1].level > level) {
        hasChildren = true;
      }
    }

    EdgeInsets padding = EdgeInsets.only(
      left: node.isRoot ? 0 : level * 28.0,
    );

    if (node.isComponent) {
      return Padding(
        padding: padding,
        child: ListTile(
          minLeadingWidth: 0,
          title: Transform.translate(
            offset: Offset(0, 0),
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: Row(
                children: [
                  Image.asset("assets/images/icons/component.png", width: 24.0),
                  const SizedBox(width: 5.0),
                  Flexible(flex: 1, child: Text(node.name)),
                  node.isOperating
                      ? Icon(Icons.bolt, color: Colors.green)
                      : Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Container(
                            width: 7.5,
                            height: 7.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
          leading: node.isRoot ? null : const SizedBox(),
        ),
      );
    } else {
      return Padding(
        padding: padding,
        child: ListTile(
          minLeadingWidth: 0,
          title: Transform.translate(
            offset: hasChildren ? Offset(node.isLocation ? -10.0 : -12, 0) : Offset(-15, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(node.isLocation ? "assets/images/icons/location.png" : "assets/images/icons/asset.png", width: 24.0),
                const SizedBox(width: 5.0),
                Expanded(child: Text(node.name)),
              ],
            ),
          ),
          leading: hasChildren ? Icon(Icons.arrow_drop_down) : SizedBox(),
        ),
      );
    }
  }
}
