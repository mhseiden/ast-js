_ = require("underscore")

{ TreeNode, UnaryNode, LeafNode, BinaryNode, Rule, RuleExecutor, RuleBatch } = require("./treenode")

class Literal extends LeafNode
  constructor: (v) -> super(Literal,[v])

class Abs extends UnaryNode
  constructor: (c) -> super(Abs,[],c)

class Neg extends UnaryNode
  constructor: (c) -> super(Neg,[],c)

class Add extends BinaryNode
  constructor: (l,r) -> super(Add,[],l,r)

class Sub extends BinaryNode
  constructor: (l,r) -> super(Sub,[],l,r)

class Mul extends BinaryNode
  constructor: (l,r) -> super(Mul,[],l,r)

class Div extends BinaryNode
  constructor: (l,r) -> super(Div,[],l,r)


class FoldConstants extends Rule
  execute: (tree) ->
    tree.transformUp (node) ->
      children = node.children
      if(_.isEmpty(children) or not _.all children, ((c) -> c instanceof Literal))
        return node

      if node instanceof UnaryNode
        value = children[0].args[0]
        if node instanceof Abs
          return new Literal(Math.abs(value))
        if node instanceof Neg
          return new Literal(-1 * value)
    
      if node instanceof BinaryNode
        l = children[0].args[0]
        r = children[1].args[0]

        if node instanceof Add
          return new Literal(l+r)
        if node instanceof Sub
          return new Literal(l-r)
        if node instanceof Mul
          return new Literal(l*r)
        if node instanceof Div
          return new Literal(l/r)

      return node

TWO = new Literal(2)
ONE = new Literal(1)
add = new Add(ONE,TWO)          # 3
sub = new Sub(TWO,add)          # -1
mul = new Mul(new Neg(sub),add) # 3
div = new Div(mul,TWO)          # 1.5

input = div
console.log(input.print())
res = (new FoldConstants).execute(input)
console.log(res.print())
