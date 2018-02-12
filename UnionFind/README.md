UnionFind for Objective-C
=========================

This is a tiny library implementing a union find / disjoint set data structure, featuring:

- **Nodes**: The only type is `UFDisjointSetNode`. A `UFDisjointSetNode` is a member of some implicit set of nodes. At any given time, the set is represented by some single specific node among its members. Sets never partially overlap; they are either the same set or have no nodes in common.
- **Union-ing**: Use `unionWith:` to merge the sets two `UFDisjointSetNode`s are members of into a single set.
- **Find-ing**: Use `isInSameSetAs:` to determine if two `UFDisjointSetNode`s are in the same set. Use `currentRepresentative` to get the current node representing the set the receiving node is in. Nodes are in the same set when they have the same representative.

Installation
============

**Method #1: [CocoaPods](http://cocoapods.org/)**

1. In your [Podfile](http://docs.cocoapods.org/podfile.html), add `pod 'UnionFind'`
2. Consider [versioning](http://docs.cocoapods.org/guides/dependency_versioning.html), like: `pod 'UnionFind', '~> 1.0'`
3. Run `pod install` from a terminal in your project directory
4. `#import "UnionFind.h"` wherever you want to access the library's types or methods

**Method #2: Manual**

1. Download one of the [releases](https://github.com/Strilanc/UnionFind-ObjC/releases), or clone the repo
2. Copy the source files from the src/ folder into your project
3. Have ARC enabled
4. `#import "UnionFind.h"` wherever you want to access the library's types or methods


Algorithm
=========

The algorithm is sourced from [wikipedia's disjoint set data structure article](http://en.wikipedia.org/wiki/Union_find). Operations take amortized nearly constant time.

Usage
=====

In the class that you want to union together, add a field of type `UFDisjointSetNode`. Initialize the node, either eagerly when the class is constructed or lazily just before it is needed, then perform operations on it.

For example, suppose we have a `FancyGraphNode` to which edges can be added but not removed. We want to track if nodes are in the same connected component. We can:

1. Add the field `@private UFDisjointSetNode* _ccNode` to `FancyGraphNode`
2. Initialize the field in the `init` function: `_ccNode = [UFDisjointSetNode new]`.
3. When adding an edge, call `[edge.Node1._ccNode unionWith:edge.Node2._ccNode]`.
4. To determine if two nodes are in the same component, evaluate `[node1._ccNode isInSameSetAs:node2._ccNode]`.

An example application is discussed in [this blog post about incremental cycle detection](http://twistedoakstudios.com/blog/Post8766_detecting-simple-cycles-forming-faster).
