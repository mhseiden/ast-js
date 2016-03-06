do ->

  # for more details on where this "TreeNode" impl comes from, see:
  # - https://github.com/apache/spark/blob/master/sql/catalyst/src/main/scala/org/apache/spark/sql/catalyst/trees/TreeNode.scala

  # (from underscore.js) establish the "root" object (i.e. window, global, etc)
  root =  typeof self == 'object' && self.self == self && self ||
          typeof global == 'object' && global.global == global && global ||
          this

  # hold a local reference to underscore
  _ = root._ || require? and require("underscore")


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
        return result if result.sameResult(prior)
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

    # rely on underscore's "deep equals" by default (but remove nodeid)
    sameResult: (o) ->
      nodeid_1 = @nodeid
      nodeid_2 = o.nodeid
      @nodeid = o.nodeid = 0
      try
        _.isEqual(@,o)
      finally
        @nodeid   = nodeid_1
        o.nodeid  = nodeid_2

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
    exports = root

  exports.Rule          = Rule
  exports.TreeNode      = TreeNode
  exports.LeafNode      = LeafNode
  exports.BinaryNode    = BinaryNode
  exports.UnaryNode     = UnaryNode
  exports.RuleBatch     = RuleBatch
  exports.RuleExecutor  = RuleExecutor
