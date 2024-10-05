import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tractian_mobile_challenge/models/asset.dart';
import 'package:http/http.dart' as http;
import 'package:tractian_mobile_challenge/models/location.dart';

class TreeNode {
  final String name;
  final List<TreeNode> children;
  final bool isLocation;
  final bool isAsset;
  final bool isComponent;
  final bool isOperating;
  final String? sensorType;
  final bool isRoot;
  bool isExpanded;

  TreeNode({
    required this.name,
    this.children = const [],
    this.isLocation = false,
    this.isAsset = false,
    this.isComponent = false,
    this.isOperating = false,
    this.sensorType,
    this.isRoot = false,
    this.isExpanded = false,
  });
}

class AssetsViewmodel extends ChangeNotifier {
  List<Location> _locations = [];
  List<Asset> _assets = [];
  List<TreeNode> nodes = [];
  List<TreeNode> fullTree = [];

  Map<String, List<Location>> locationMap = {};
  Map<String, List<Asset>> assetMap = {};
  Map<String, List<Asset>> componentMap = {};
  List<Asset> unlinkedComponents = [];

  Future<void> fetchAllData({required String companyId}) async {
    final http.Response locationResponse = await http.get(Uri.parse('https://fake-api.tractian.com/companies/$companyId/locations'));
    if (locationResponse.statusCode == 200) {
      _locations = (json.decode(locationResponse.body) as List).map((json) => Location.fromJson(json)).toList();
    }

    final http.Response assetsResponse = await http.get(Uri.parse('https://fake-api.tractian.com/companies/$companyId/assets'));
    if (assetsResponse.statusCode == 200) {
      _assets = (json.decode(assetsResponse.body) as List).map((json) => Asset.fromJson(json)).toList();
    }

    await _preprocessData();
    nodes = await _buildTree();

    notifyListeners();
  }

  Future<void> _preprocessData() async {
    locationMap.clear();
    assetMap.clear();
    componentMap.clear();
    unlinkedComponents.clear();

    for (Location location in _locations) {
      if (!locationMap.containsKey(location.parentId ?? 'root')) {
        locationMap[location.parentId ?? 'root'] = [];
      }
      locationMap[location.parentId ?? 'root']!.add(location);
    }

    for (Asset asset in _assets) {
      if (asset.sensorType != null) {
        if (asset.parentId == null && asset.locationId == null) {
          unlinkedComponents.add(asset);
        } else if (asset.parentId != null) {
          if (!componentMap.containsKey(asset.parentId!)) {
            componentMap[asset.parentId!] = [];
          }
          componentMap[asset.parentId!]!.add(asset);
        } else if (asset.locationId != null) {
          if (!componentMap.containsKey(asset.locationId!)) {
            componentMap[asset.locationId!] = [];
          }
          componentMap[asset.locationId!]!.add(asset);
        }
      } else {
        if (asset.locationId != null) {
          if (!assetMap.containsKey(asset.locationId!)) {
            assetMap[asset.locationId!] = [];
          }
          assetMap[asset.locationId!]!.add(asset);
        } else if (asset.parentId != null) {
          if (!assetMap.containsKey(asset.parentId!)) {
            assetMap[asset.parentId!] = [];
          }
          assetMap[asset.parentId!]!.add(asset);
        }
      }
    }
  }

  // ---------------------------- Tree without filters ----------------------------------

  Future<List<TreeNode>> _buildTree() async {
    List<TreeNode> tree = [];

    if (locationMap.containsKey('root')) {
      for (Location location in locationMap['root']!) {
        tree.add(TreeNode(
          name: location.name,
          children: _buildSubTree(location.id),
          isLocation: true,
          isRoot: true,
          isExpanded: true,
        ));
      }
    }

    for (Asset component in unlinkedComponents) {
      tree.add(TreeNode(
        name: component.name,
        isComponent: true,
        sensorType: component.sensorType,
        isOperating: component.status == "operating",
        isRoot: true,
        isExpanded: true,
      ));
    }

    return tree;
  }

  List<TreeNode> _buildSubTree(String parentId) {
    List<TreeNode> children = [];

    if (locationMap.containsKey(parentId)) {
      for (Location subLocation in locationMap[parentId]!) {
        children.add(TreeNode(
          name: subLocation.name,
          children: _buildSubTree(subLocation.id),
          isLocation: true,
          isExpanded: true,
        ));
      }
    }

    if (componentMap.containsKey(parentId)) {
      for (Asset component in componentMap[parentId]!) {
        children.add(TreeNode(
          name: component.name,
          isComponent: true,
          isOperating: component.status == "operating",
          sensorType: component.sensorType,
          isExpanded: true,
        ));
      }
    }

    if (assetMap.containsKey(parentId)) {
      for (Asset asset in assetMap[parentId]!) {
        children.add(TreeNode(
          name: asset.name,
          children: _buildSubTree(asset.id),
          isAsset: true,
          isExpanded: true,
        ));
      }
    }

    return children;
  }

  // ---------------------------- Tree with search filter -------------------------------

  Future<void> searchTree(String query) async {
    if (query.isEmpty) {
      nodes = await _buildTree();
    } else {
      nodes = await _buildSearchedTree(query.toLowerCase());
    }
    notifyListeners();
  }

  Future<List<TreeNode>> _buildSearchedTree(String query) async {
    List<TreeNode> searchedTree = [];

    if (locationMap.containsKey('root')) {
      for (Location location in locationMap['root']!) {
        List<TreeNode> searchedChildren = _searchSubTree(location.id, query);
        if (searchedChildren.isNotEmpty || location.name.toLowerCase().contains(query)) {
          searchedTree.add(TreeNode(
            name: location.name,
            children: searchedChildren,
            isLocation: true,
            isRoot: true,
            isExpanded: true,
          ));
        }
      }
    }

    for (Asset component in unlinkedComponents.where((component) => component.name.toLowerCase().contains(query))) {
      searchedTree.add(TreeNode(
        name: component.name,
        isComponent: true,
        sensorType: component.sensorType,
        isOperating: component.status == "operating",
        isRoot: true,
        isExpanded: true,
      ));
    }

    return searchedTree;
  }

  List<TreeNode> _searchSubTree(String parentId, String query) {
    List<TreeNode> children = [];

    if (locationMap.containsKey(parentId)) {
      for (Location subLocation in locationMap[parentId]!) {
        List<TreeNode> searchedChildren = _searchSubTree(subLocation.id, query);
        if (searchedChildren.isNotEmpty || subLocation.name.toLowerCase().contains(query)) {
          children.add(TreeNode(
            name: subLocation.name,
            children: searchedChildren,
            isLocation: true,
            isExpanded: true,
          ));
        }
      }
    }

    if (componentMap.containsKey(parentId)) {
      for (Asset component in componentMap[parentId]!.where((component) => component.name.toLowerCase().contains(query))) {
        children.add(TreeNode(
          name: component.name,
          isComponent: true,
          isOperating: component.status == "operating",
          sensorType: component.sensorType,
          isExpanded: true,
        ));
      }
    }

    if (assetMap.containsKey(parentId)) {
      for (Asset asset in assetMap[parentId]!) {
        List<TreeNode> searchedChildren = _searchSubTree(asset.id, query);
        if (searchedChildren.isNotEmpty || asset.name.toLowerCase().contains(query)) {
          children.add(TreeNode(
            name: asset.name,
            children: searchedChildren,
            isAsset: true,
            isExpanded: true,
          ));
        }
      }
    }

    return children;
  }

  // ---------------------------- Tree with with chip filters ---------------------------

  Future<void> filterTree({required bool isOperating, required String query, bool applyFilter = true}) async {
    if (query.isEmpty) {
      if (applyFilter) {
        nodes = await _buildFilteredTree(isOperating);
      } else {
        nodes = await _buildTree();
      }
    } else {
      if (applyFilter) {
        nodes = await _buildFilteredAndSearchedTree(query.toLowerCase(), isOperating);
      } else {
        nodes = await _buildSearchedTree(query.toLowerCase());
      }
    }
    notifyListeners();
  }

  Future<void> clearFilter() async {
    nodes = await _buildTree();
    notifyListeners();
  }

  Future<List<TreeNode>> _buildFilteredTree(bool isOperating) async {
    List<TreeNode> filteredTree = [];

    if (locationMap.containsKey('root')) {
      for (Location location in locationMap['root']!) {
        List<TreeNode> filteredChildren = _filterSubTree(location.id, isOperating);
        if (filteredChildren.isNotEmpty) {
          filteredTree.add(TreeNode(
            name: location.name,
            children: filteredChildren,
            isLocation: true,
            isRoot: true,
            isExpanded: true,
          ));
        }
      }
    }

    for (Asset component in unlinkedComponents.where((component) => component.status == (isOperating ? "operating" : "not_operating"))) {
      filteredTree.add(TreeNode(
        name: component.name,
        isComponent: true,
        sensorType: component.sensorType,
        isOperating: component.status == "operating",
        isRoot: true,
        isExpanded: true,
      ));
    }

    return filteredTree;
  }

  List<TreeNode> _filterSubTree(String parentId, bool isOperating) {
    List<TreeNode> children = [];

    if (locationMap.containsKey(parentId)) {
      for (Location subLocation in locationMap[parentId]!) {
        List<TreeNode> filteredChildren = _filterSubTree(subLocation.id, isOperating);
        if (filteredChildren.isNotEmpty) {
          children.add(TreeNode(
            name: subLocation.name,
            children: filteredChildren,
            isLocation: true,
            isExpanded: true,
          ));
        }
      }
    }

    if (componentMap.containsKey(parentId)) {
      for (Asset component in componentMap[parentId]!.where((component) => component.status == (isOperating ? "operating" : "alert"))) {
        children.add(TreeNode(
          name: component.name,
          isComponent: true,
          isOperating: component.status == "operating",
          sensorType: component.sensorType,
          isExpanded: true,
        ));
      }
    }

    if (assetMap.containsKey(parentId)) {
      for (Asset asset in assetMap[parentId]!) {
        List<TreeNode> filteredChildren = _filterSubTree(asset.id, isOperating);
        if (filteredChildren.isNotEmpty) {
          children.add(TreeNode(
            name: asset.name,
            children: filteredChildren,
            isAsset: true,
            isExpanded: true,
          ));
        }
      }
    }

    return children;
  }

  Future<List<TreeNode>> _buildFilteredAndSearchedTree(String query, bool isOperating) async {
    List<TreeNode> filteredTree = [];

    if (locationMap.containsKey('root')) {
      for (Location location in locationMap['root']!) {
        List<TreeNode> filteredChildren = _filterAndSearchSubTree(location.id, query, isOperating);
        if (filteredChildren.isNotEmpty || location.name.toLowerCase().contains(query)) {
          filteredTree.add(TreeNode(
            name: location.name,
            children: filteredChildren,
            isLocation: true,
            isRoot: true,
            isExpanded: true,
          ));
        }
      }
    }

    for (Asset component in unlinkedComponents.where((component) =>
    component.name.toLowerCase().contains(query) &&
        component.status == (isOperating ? "operating" : "alert"))) {
      filteredTree.add(TreeNode(
        name: component.name,
        isComponent: true,
        sensorType: component.sensorType,
        isOperating: component.status == "operating",
        isRoot: true,
        isExpanded: true,
      ));
    }

    return filteredTree;
  }

  List<TreeNode> _filterAndSearchSubTree(String parentId, String query, bool isOperating) {
    List<TreeNode> children = [];

    if (locationMap.containsKey(parentId)) {
      for (Location subLocation in locationMap[parentId]!) {
        List<TreeNode> filteredChildren = _filterAndSearchSubTree(subLocation.id, query, isOperating);
        if (filteredChildren.isNotEmpty || subLocation.name.toLowerCase().contains(query)) {
          children.add(TreeNode(
            name: subLocation.name,
            children: filteredChildren,
            isLocation: true,
            isExpanded: true,
          ));
        }
      }
    }

    if (componentMap.containsKey(parentId)) {
      for (Asset component in componentMap[parentId]!.where((component) =>
      component.name.toLowerCase().contains(query) &&
          component.status == (isOperating ? "operating" : "alert"))) {
        children.add(TreeNode(
          name: component.name,
          isComponent: true,
          isOperating: component.status == "operating",
          sensorType: component.sensorType,
          isExpanded: true,
        ));
      }
    }

    if (assetMap.containsKey(parentId)) {
      for (Asset asset in assetMap[parentId]!) {
        List<TreeNode> filteredChildren = _filterAndSearchSubTree(asset.id, query, isOperating);
        if (filteredChildren.isNotEmpty || asset.name.toLowerCase().contains(query)) {
          children.add(TreeNode(
            name: asset.name,
            children: filteredChildren,
            isAsset: true,
            isExpanded: true,
          ));
        }
      }
    }

    return children;
  }
}