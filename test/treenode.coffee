Algebra = require("./algebra.coffee")

_ = require("underscore")
assert = require("assert")

N_THREE = new Algebra.Literal(-3)
N_TWO   = new Algebra.Literal(-2)
N_ONE   = new Algebra.Literal(-1)
ZERO    = new Algebra.Literal(0)
ONE     = new Algebra.Literal(1)
TWO     = new Algebra.Literal(2)
THREE   = new Algebra.Literal(3)

SAME = yes
DIFF = no
check = (lhs,rhs,expected = SAME) ->
  if not expected is lhs.sameResult(rhs)
    assert.equal(lhs.toString(),rhs.toString())

Neg = Algebra.Neg
Add = Algebra.Add
Sub = Algebra.Sub

[NEG_TREE, NEG_TREE_NODES] = do ->
  depth = 5
  expr = ONE
  expr = new Neg(expr) for i in [0...depth]
  return [expr,1+depth]

[ADD_TREE, ADD_TREE_NODES, ADD_TREE_LEAVES] = do ->
  depth = 2
  nodes = 0
  leaves = 0
  mkChild = (depth) ->
    ++nodes
    if 0 == depth
      ++leaves
      return ONE
    else
      return new Add(mkChild(depth - 1),mkChild(depth - 1))
  [mkChild(depth),nodes,leaves]

describe "Tree Node Operations", ->
  describe "TreeNode#transform", ->
    it "should swap out leaf nodes (down)", ->
      transform = (n) -> if n == ONE then TWO else n
      xform = ADD_TREE.transform(transform,yes)
      twos = xform.filter (n) -> n.sameResult(TWO)
      assert.equal(ADD_TREE_LEAVES,twos.length)

    it "should swap out leaf nodes (up)", ->
      transform = (n) -> if n == ONE then TWO else n
      xform = ADD_TREE.transform(transform,no)
      twos = xform.filter (n) -> n.sameResult(TWO)
      assert.equal(ADD_TREE_LEAVES,twos.length)

    it "should swap out add nodes (down)", ->
      transform = (n) ->
        return n unless n instanceof Add
        [l,r] = n.children
        new Sub(l,r)

      xform = ADD_TREE.transform(transform,yes)
      subs = xform.filter (n) -> n instanceof Sub
      assert.equal(ADD_TREE_NODES - ADD_TREE_LEAVES,subs.length)

    it "should swap out add nodes (up)", ->
      transform = (n) ->
        return n unless n instanceof Add
        [l,r] = n.children
        new Sub(l,r)

      xform = ADD_TREE.transform(transform,no)
      subs = xform.filter (n) -> n instanceof Sub
      assert.equal(ADD_TREE_NODES - ADD_TREE_LEAVES,subs.length)

  describe "TreeNode#map", ->
    it "should stringify the whole tree", ->
      str = ZERO.map (n) -> n.toString()
      assert.deepEqual(str,[ZERO.toString()])

    it "should be deterministic (1)", ->
      str1 = NEG_TREE.map (n) -> n.toString()
      str2 = NEG_TREE.map (n) -> n.toString()
      assert.deepEqual(str1,str2)

    it "should be deterministic (2)", ->
      str1 = ADD_TREE.map (n) -> n.toString()
      str2 = ADD_TREE.map (n) -> n.toString()
      assert.deepEqual(str1,str2)

  describe "TreeNode#flatMap", ->
    it "should flatten out intermediate arrays", ->
      str1 = ADD_TREE.map (n) -> n.toString()
      str2 = ADD_TREE.flatMap (n) -> [n.toString()]
      assert.deepEqual(str1,str2)

    it "should filter out empty intermediate arrays", ->
      ones = ADD_TREE.flatMap (n) -> if n == ONE then [n] else []
      assert.equal(ADD_TREE_LEAVES, ones.length)

  describe "TreeNode#filter", ->
    it "should be empty when predicate is always false", ->
      nodes = ADD_TREE.filter -> false
      assert.equal(0, nodes.length)

    it "should be full when predicate is always true", ->
      nodes = ADD_TREE.filter -> true
      assert.equal(ADD_TREE_NODES, nodes.length)

    it "should be correct when predicate is given", ->
      nodes = ADD_TREE.filter (n) -> n == ONE
      assert.equal(ADD_TREE_LEAVES, nodes.length)

  describe "TreeNode#sameResult", ->
    it "should be equal to itself", ->
      assert.equal(yes, ZERO.sameResult(ZERO))

    it "should be equal to another instance", ->
      assert.equal(yes, new Algebra.Literal(0).sameResult(ZERO))

    it "should not be equal to a different node", ->
      assert.equal(no, ZERO.sameResult(ONE))

    it "should be equal to the same tree (1)", ->
      assert.equal(yes, NEG_TREE.sameResult(NEG_TREE))

    it "should be equal to the same tree (2)", ->
      assert.equal(yes, ADD_TREE.sameResult(ADD_TREE))

    it "should not be equal to another tree", ->
      assert.equal(no, ADD_TREE.sameResult(NEG_TREE))

  describe "TreeNode#walk", ->
    it "should walk down a unary tree", ->
      path = []
      walkFn = (n) -> path.push(n)
      NEG_TREE.walk(walkFn, yes)
      assert.equal(NEG_TREE_NODES, path.length)
      check(path[0],NEG_TREE,SAME)

    it "should walk up a unary tree", ->
      path = []
      walkFn = (n) -> path.push(n)
      NEG_TREE.walk(walkFn, no)
      assert.equal(NEG_TREE_NODES, path.length)
      check(path[0],ONE,SAME)

    it "should walk down a binary tree", ->
      path = []
      walkFn = (n) -> path.push(n)
      ADD_TREE.walk(walkFn, yes)
      assert.equal(ADD_TREE_NODES,path.length)
      check(path[0],ADD_TREE,SAME)

    it "should walk up a binary tree", ->
      path = []
      walkFn = (n) -> path.push(n)
      ADD_TREE.walk(walkFn, no)
      assert.equal(ADD_TREE_NODES,path.length)
      check(path[0],ONE,SAME)

  describe "TreeNode#find", ->
    it "should find a literal node", ->
      expr = ZERO
      found = expr.find (n) -> n.args[0] == 0
      check(ZERO,found,SAME)

    it "should not find a literal that doesn't exist", ->
      expr = ZERO
      found = expr.find (n) -> n.args[0] == 1
      assert(not found?)

    it "should find a node within the tree", ->
      expr = new Algebra.Neg(ONE)
      found = expr.find (n) -> n.args[0] == 1
      check(ONE,found,SAME)

    it "should not find a node that isn't in the tree", ->
      expr = new Algebra.Neg(ONE)
      found = expr.find (n) -> n.args[0] == 5
      assert(not found?)
