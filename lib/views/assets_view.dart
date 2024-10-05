import 'package:flutter/material.dart';
import 'package:tractian_mobile_challenge/models/company.dart';
import 'package:tractian_mobile_challenge/viewmodels/assets_viewmodel.dart';

class AssetsView extends StatefulWidget {
  final Company company;

  AssetsView({super.key, required this.company});

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
  int selectedChipIndex = -1;
  bool isLoading = true;

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
  }

  @override
  void dispose() {
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
          Expanded(child: TreeWidget(assetsViewmodel.nodes)),
        ],
      ),
    );
  }

  Widget SearchTextFormField() {
    return TextFormField(
      controller: searchController,
      onChanged: (query) {
        setState(() {});
        if (selectedChipIndex == 0) {
          assetsViewmodel.filterTree(isOperating: true, query: query);
        } else if (selectedChipIndex == 1) {
          assetsViewmodel.filterTree(isOperating: false, query: query);
        } else {
          assetsViewmodel.searchTree(query);
        }
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
                String query = searchController.text;
                if (selectedChipIndex == index) {
                  selectedChipIndex = -1;
                  assetsViewmodel.clearFilter();
                  assetsViewmodel.searchTree(query);
                } else {
                  selectedChipIndex = index;
                  if (index == 0) {
                    assetsViewmodel.filterTree(isOperating: true, query: query, applyFilter: true);
                  } else if (index == 1) {
                    assetsViewmodel.filterTree(isOperating: false, query: query, applyFilter: true);
                  }
                }
              });
            });
      }),
    );
  }

  Widget TreeWidget(List<TreeNode> nodes) {
    return ListView.builder(
      itemCount: nodes.length,
      padding: EdgeInsets.only(bottom: 25.0),
      itemBuilder: (context, index) {
        return TreeNodes(nodes[index]);
      },
    );
  }

  Widget TreeNodes(TreeNode node) {
    if (node.isComponent) {
      return Padding(
        padding: EdgeInsets.only(left: node.isRoot ? 0 : 32.0),
        child: ListTile(
          minLeadingWidth: 0,
          title: Transform.translate(
            offset: Offset(node.isRoot ? 0 : -8, 0),
            child: Row(
              children: [
                Icon(Icons.layers_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 5.0),
                Text(node.name),
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
                )
              ],
            ),
          ),
          leading: node.isRoot ? null : const SizedBox(),
        ),
      );
    } else {
      return TreeExpansionTile(
        title: node.name,
        expanded: node.isExpanded,
        isRoot: node.isRoot,
        isLocation: node.isLocation,
        isAsset: node.isAsset,
        children: node.children.map((child) => TreeNodes(child)).toList(),
      );
    }
  }
}

class TreeExpansionTile extends StatefulWidget {
  final String title;
  final bool expanded;
  final bool isRoot;
  final bool isLocation;
  final bool isAsset;
  final List<Widget> children;

  TreeExpansionTile({
    required this.title,
    required this.expanded,
    required this.isRoot,
    required this.children,
    required this.isLocation,
    required this.isAsset,
  });

  @override
  _TreeExpansionTileState createState() => _TreeExpansionTileState();
}

class _TreeExpansionTileState extends State<TreeExpansionTile> {
  bool isExpanded = false;
  bool isRoot = false;
  bool hasChildren = false;
  bool isLocation = false;
  bool isAsset = false;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.expanded;
    isRoot = widget.isRoot;
    hasChildren = widget.children.length > 0;
    isLocation = widget.isLocation;
    isAsset = widget.isAsset;
  }

  @override
  Widget build(BuildContext context) {
    hasChildren = widget.children.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: isRoot ? 0 : 28.0),
      child: Column(
        children: [
          ListTile(
            minLeadingWidth: 0,
            title: Transform.translate(
              offset: Offset(-12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (hasChildren)
                    Row(
                      children: [
                        Icon(
                          isLocation ? Icons.location_on_outlined : Icons.layers,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 5.0),
                      ],
                    ),
                  Expanded(child: Text(widget.title)),
                ],
              ),
            ),
            leading: hasChildren
                ? Icon(
              isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
            )
                : Icon(
              isLocation ? Icons.location_on_outlined : Icons.layers,
              color: Theme.of(context).primaryColor,
            ),
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
          ),
          if (isExpanded)
            Column(
              children: widget.children,
            ),
        ],
      ),
    );
  }
}