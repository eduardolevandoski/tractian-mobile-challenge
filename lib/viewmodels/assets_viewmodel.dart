import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tractian_mobile_challenge/models/asset.dart';
import 'package:tractian_mobile_challenge/models/location.dart';

class TreeNodeWithLevel {
  final TreeNode node;
  final int level;

  TreeNodeWithLevel(this.node, this.level);
}

class TreeNode {
  final String id;
  final String name;
  final bool isLocation;
  final bool isAsset;
  final bool isComponent;
  final bool isAlert;
  final String? sensorType;
  final bool isRoot;
  final List<TreeNode> children;

  TreeNode({
    required this.id,
    required this.name,
    this.isLocation = false,
    this.isAsset = false,
    this.isComponent = false,
    this.isAlert = false,
    this.sensorType,
    this.isRoot = false,
    this.children = const [],
  });
}


class AssetsViewmodel extends ChangeNotifier {
  List<Location> _locations = [];
  List<Asset> _assets = [];
  Map<String, List<Location>> locationMap = {};
  Map<String, List<Asset>> assetMap = {};
  Map<String, List<Asset>> componentMap = {};
  List<Asset> unlinkedComponents = [];

  Future<void> fetchAllData({required String companyId}) async {
    final http.Response locationResponse =
        await http.get(Uri.parse('https://fake-api.tractian.com/companies/$companyId/locations'));
    if (locationResponse.statusCode == 200) {
      _locations = (json.decode(locationResponse.body) as List).map((json) => Location.fromJson(json)).toList();
    }

    final http.Response assetsResponse =
        await http.get(Uri.parse('https://fake-api.tractian.com/companies/$companyId/assets'));
    if (assetsResponse.statusCode == 200) {
      _assets = (json.decode(assetsResponse.body) as List).map((json) => Asset.fromJson(json)).toList();
    }

    await _preprocessData();
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

  Stream<TreeNodeWithLevel> generateTreeNodesWithLevel() async* {
    if (locationMap.containsKey('root')) {
      for (Location location in locationMap['root']!) {
        TreeNode rootNode = TreeNode(
          id: location.id,
          name: location.name,
          isLocation: true,
          isRoot: true,
        );
        yield TreeNodeWithLevel(rootNode, 0);
        yield* _traverseNode(rootNode, 1, null, null);
      }
    }

    for (Asset component in unlinkedComponents) {
      TreeNode componentNode = TreeNode(
        id: component.id,
        name: component.name,
        isComponent: true,
        sensorType: component.sensorType,
        isAlert: component.status == "alert",
        isRoot: true,
      );
      yield TreeNodeWithLevel(componentNode, 0);
    }
  }

  Stream<TreeNodeWithLevel> _traverseNode(TreeNode node, int level, String? query, String? statusFilter) async* {
    List<TreeNode> children = await _buildSubTree(node, statusFilter);
    for (TreeNode child in children) {
      bool matchesQuery = query == null || child.name.toLowerCase().contains(query);
      if (matchesQuery) {
        yield TreeNodeWithLevel(child, level);
      }

      yield* _traverseNode(child, level + 1, query, statusFilter);
    }
  }

  Future<List<TreeNode>> _buildSubTree(TreeNode parentNode, String? filter) async {
    List<TreeNode> children = [];

    String parentId = parentNode.id;

    if (locationMap.containsKey(parentId)) {
      for (Location subLocation in locationMap[parentId]!) {
        children.add(TreeNode(
          id: subLocation.id,
          name: subLocation.name,
          isLocation: true,
        ));
      }
    }

    if (componentMap.containsKey(parentId)) {
      for (Asset component in componentMap[parentId]!) {
        if (filter == null || (filter == "energy" && component.sensorType == "energy") || (filter == "alert" && component.status == "alert")) {
          children.add(TreeNode(
            id: component.id,
            name: component.name,
            isComponent: true,
            sensorType: component.sensorType,
            isAlert: component.status == "alert",
          ));
        }
      }
    }

    if (assetMap.containsKey(parentId)) {
      for (Asset asset in assetMap[parentId]!) {
        children.add(TreeNode(
          id: asset.id,
          name: asset.name,
          isAsset: true,
        ));
      }
    }

    return children;
  }

  // ---------------------------- Tree with search filter -------------------------------

  Stream<TreeNodeWithLevel> generateSearchedTreeNodesWithLevel(String query, String? statusFilter) async* {
    if (locationMap.containsKey('root')) {
      for (Location location in locationMap['root']!) {
        TreeNode rootNode = TreeNode(
          id: location.id,
          name: location.name,
          isLocation: true,
          isRoot: true,
        );

        TreeNode? matchedTree = await _searchNode(rootNode, query, statusFilter);
        if (matchedTree != null) {
          yield* _hideTree(matchedTree, 0);
        }
      }
    }

    for (Asset component in unlinkedComponents) {
      if (component.name.toLowerCase().contains(query) && (statusFilter == null || component.status == statusFilter)) {
        TreeNode componentNode = TreeNode(
          id: component.id,
          name: component.name,
          isComponent: true,
          sensorType: component.sensorType,
          isAlert: component.status == "alert",
          isRoot: true,
        );
        yield TreeNodeWithLevel(componentNode, 0);
      }
    }
  }

  Stream<TreeNodeWithLevel> _hideTree(TreeNode node, int level) async* {
    yield TreeNodeWithLevel(node, level);
    for (TreeNode child in node.children) {
      yield* _hideTree(child, level + 1);
    }
  }

  Future<TreeNode?> _searchNode(
      TreeNode parentNode,
      String query,
      String? statusFilter) async {
    bool matchesQuery = parentNode.name.toLowerCase().contains(query);

    List<TreeNode> children = await _buildSubTree(parentNode, statusFilter);
    List<TreeNode> matchingChildren = [];

    for (TreeNode child in children) {
      TreeNode? matchedChild = await _searchNode(child, query, statusFilter);
      if (matchedChild != null) {
        matchingChildren.add(matchedChild);
      }
    }

    if (matchesQuery || matchingChildren.isNotEmpty) {
      return TreeNode(
        id: parentNode.id,
        name: parentNode.name,
        isLocation: parentNode.isLocation,
        isAsset: parentNode.isAsset,
        isComponent: parentNode.isComponent,
        isAlert: parentNode.isAlert,
        sensorType: parentNode.sensorType,
        isRoot: parentNode.isRoot,
        children: matchingChildren,
      );
    } else {
      return null;
    }
  }

  // ---------------------------- Tree with chip filters --------------------------------

  Stream<TreeNodeWithLevel> generateFilteredTreeNodesWithLevel(String filter) async* {
    if (locationMap.containsKey('root')) {
      for (Location location in locationMap['root']!) {
        Stream<TreeNodeWithLevel> childStream = _filterNode(location.id, 1, filter);

        bool hasMatchingChildren = false;
        await for (TreeNodeWithLevel childNode in childStream) {
          if (!hasMatchingChildren) {
            TreeNode rootNode = TreeNode(
              id: location.id,
              name: location.name,
              isLocation: true,
              isRoot: true,
            );
            yield TreeNodeWithLevel(rootNode, 0);
            hasMatchingChildren = true;
          }
          yield childNode;
        }
      }
    }

    for (Asset component in unlinkedComponents) {
      if (filter == "alert" && component.status == filter) {
        TreeNode componentNode = TreeNode(
          id: component.id,
          name: component.name,
          isComponent: true,
          sensorType: component.sensorType,
          isAlert: true,
          isRoot: true,
        );
        yield TreeNodeWithLevel(componentNode, 0);
      } else if (filter == "energy" && component.sensorType == "energy") {
        TreeNode componentNode = TreeNode(
          id: component.id,
          name: component.name,
          isComponent: true,
          sensorType: component.sensorType,
          isAlert: component.status == "alert",
          isRoot: true,
        );
        yield TreeNodeWithLevel(componentNode, 0);
      }
    }
  }

  Stream<TreeNodeWithLevel> _filterNode(String parentId, int level, String filter) async* {
    List<TreeNode> children = await _buildSubTree(TreeNode(id: parentId, name: ''), filter);

    for (TreeNode child in children) {
      if (child.isComponent) {
        if (filter == "energy" && child.sensorType == "energy") {
          yield TreeNodeWithLevel(child, level);
        }
        else if (filter == "alert" && child.isAlert) {
          yield TreeNodeWithLevel(child, level);
        }
      } else {
        Stream<TreeNodeWithLevel> childStream = _filterNode(child.id, level + 1, filter);

        bool hasMatchingChildren = false;
        await for (TreeNodeWithLevel childNode in childStream) {
          if (!hasMatchingChildren) {
            yield TreeNodeWithLevel(child, level);
            hasMatchingChildren = true;
          }
          yield childNode;
        }
      }
    }
  }
}
