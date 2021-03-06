###
Copyright (c) 2016 Max Seiden <140dbs@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to
do so, subject to the following conditions.

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
###

do ->
  # for more details on where this "TreeNode" impl comes from, see:
  # - https://github.com/apache/spark/blob/master/sql/catalyst/src/main/scala/org/apache/spark/sql/catalyst/trees/TreeNode.scala

  # (from underscore.js) establish the "root" object (i.e. window, global, etc)
  root =  typeof self == 'object' && self.self == self && self ||
          typeof global == 'object' && global.global == global && global ||
          this

  # hold a local reference to underscore
  _ = root._ || require? and require("underscore")

  class Planner
    constructor: (@strategies) ->
      _.map @strategies, (s) => s.planner = @
      @planned = {} # track the trees we've planned

    plan: (tree) ->
      execute = (s) -> s.execute(tree)
      planned = _.map(@strategies,execute)
      _.filter _.flatten(planned), (n) -> n?

    planLater: (tree) ->
      plan = @planned[tree.nodeid]
      unless plan?
        if(plan = @plan(tree)[0])?
          @planned[tree.nodeid] = plan unless (tree.nondeterministic is true)
        else
          throw new Error("unable to plan tree: #{tree.print()}")
      return plan

  class PlannerStrategy
    constructor: ->
    execute: -> []

  class RuleExecutor
    constructor: (@batches = []) ->

    execute: (tree0) ->
      inner = (tree,batch) -> return batch.execute(tree)
      return _.foldl(@batches,inner,tree0,{})

  class RuleBatch
    constructor: (@rules,@iterations) ->

    execute: (tree0) ->
      prior = tree0
      result = null

      for i in [0...@iterations] by 1
        inner = (tree,rule) -> return rule.execute(tree)
        result = _.foldl(@rules,inner,prior,{})
        return prior if result.sameResult(prior)
        prior = result
      return result

  class Rule
    constructor: ->
    execute: (tree) -> return tree

  class TreeNode
    # [node ctor factory, node args, node children]
    constructor: (@ctor, @args = [], @children = []) ->
      @nodeid = TreeNode.nextNodeID()

    nodeName: ->
      @ctor.name

    toString: (withID = no) ->
      argString = _.map(@args,(a) -> a.toString()).join(",")
      idString = if withID then "##{@nodeid}" else ""
      "#{@nodeName()}[#{argString}]#{idString}"

    print: (withID = no, depth = 0) ->
      prefix = _.times(depth, -> " ").join("")
      children = _.map @children, (c) -> c.print(withID,1+depth)
      "\n#{prefix}#{@toString(withID)}#{children.join("")}"

    # rely on underscore's "deep equals" by default
    sameResult: (o) ->
      return no unless _.isEqual(@ctor,o.ctor)
      return no unless _.isEqual(@args,o.args)
      zipped = _.zip @children, o.children
      return _.all zipped, ([l,r]) -> l.sameResult(r)

    # creates a shallow copy of this node
    copy: (args = @args, children = @children) ->
      c = new @ctor()
      c.ctor = @ctor
      c.args = args
      c.children = children
      return c

    # walk up or down the tree (i.e. foreach)
    walkUp: (f) -> @walk(f,no)
    walkDown: (f) -> @walk(f,yes)
    walk: (f, down = yes) ->
      if down
        f(@)
        _.each @children, (c) -> c.walk(f,down)
      else
        _.each @children, (c) -> c.walk(f,down)
        f(@)
      return

    # find the first node that satisfies f (walk down)
    find: (f) ->
      return @ if f(@)
  
      if _.isEmpty(@children)
        return null
      else
        return _.find @children, (c) -> c.find(f)?

    # map over each node and return the resulting array
    map: (f) ->
      res = []
      @walk (node) -> res.push(f(node))
      return res

    # map over each node and return a flattened array
    flatMap: (f) ->
      _.flatten @map(f)

    # filter the nodes in the tree using predicate f
    filter: (f) ->
      @flatMap (node) -> if f(node) then [node] else []

    # transforms this node and its children using the given fn
    transformUp: (f) -> @transform(f,no)
    transformDown: (f) -> @transform(f,yes)
    transform: (f, down = yes) -> TreeNode.transform(@,f,down)

    # static helper to transform a single node
    @transform: (node,f,down) ->
      if down
        afterF = f(node)
        result = if afterF.sameResult(node) then node else afterF
        return TreeNode.transformChildren(result,f,down)
      else
        afterF = TreeNode.transformChildren(node,f,down)
        result = if afterF.sameResult(node) then node else afterF
        return f(result)

    # static helper to transform the children of a given node
    @transformChildren: (node,f,down) ->
      updated = []
      for c in node.children
        result = c.transform(f,down)
        updated.push(result)
      return node.copy(node.args,updated)

    @nextNodeID: do ->
      id = 0
      () -> ++id


  class LeafNode extends TreeNode
    constructor: (ctor,args) -> super(ctor,args,[])

  class UnaryNode extends TreeNode
    constructor: (ctor,args,child) -> super(ctor,args,[child])

  class BinaryNode extends TreeNode
    constructor: (ctor,args,l,r) -> super(ctor,args,[l,r])

  # export to the global / module space (partly taken from underscore)
  if module? and not module.nodeType
    exports = module.exports = {}
  else
    exports = root.astjs = {}

  # ast nodes
  exports.TreeNode        = TreeNode
  exports.LeafNode        = LeafNode
  exports.UnaryNode       = UnaryNode
  exports.BinaryNode      = BinaryNode

  # rewrite rule classes
  exports.Rule            = Rule
  exports.RuleBatch       = RuleBatch
  exports.RuleExecutor    = RuleExecutor

  # planner classes
  exports.Planner         = Planner
  exports.PlannerStrategy = PlannerStrategy
  return

