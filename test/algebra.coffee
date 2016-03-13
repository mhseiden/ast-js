_ = require("underscore")
exports = module.exports = {}

{
  TreeNode
  UnaryNode
  LeafNode
  BinaryNode
  Rule
  RuleExecutor
  RuleBatch
  Planner
  PlannerStrategy
} = require("../treenode.coffee")

exports.Literal =
class Literal extends LeafNode
  constructor: (v) -> super(Literal,[v])

exports.Abs =
class Abs extends UnaryNode
  constructor: (c) -> super(Abs,[],c)

exports.Neg =
class Neg extends UnaryNode
  constructor: (c) -> super(Neg,[],c)

exports.Sqrt =
class Sqrt extends UnaryNode
  constructor: (c) -> super(Sqrt,[],c)

exports.Ceil =
class Ceil extends UnaryNode
  constructor: (c) -> super(Ceil,[],c)

exports.Floor =
class Floor extends UnaryNode
  constructor: (c) -> super(Floor,[],c)

exports.Ln =
class Ln extends UnaryNode
  constructor: (c) -> super(Ln,[],c)

exports.Exp =
class Exp extends UnaryNode
  constructor: (c) -> super(Exp,[],c)

exports.Log10 =
class Log10 extends UnaryNode
  constructor: (c) -> super(Log10,[],c)

exports.Round =
class Round extends UnaryNode
  constructor: (c) -> super(Round,[],c)

exports.Add =
class Add extends BinaryNode
  constructor: (l,r) -> super(Add,[],l,r)

exports.Sub =
class Sub extends BinaryNode
  constructor: (l,r) -> super(Sub,[],l,r)

exports.Mul =
class Mul extends BinaryNode
  constructor: (l,r) -> super(Mul,[],l,r)

exports.Div =
class Div extends BinaryNode
  constructor: (l,r) -> super(Div,[],l,r)

exports.Mod =
class Mod extends BinaryNode
  constructor: (l,r) -> super(Mod,[],l,r)

exports.Pow =
class Pow extends BinaryNode
  constructor: (l,r) -> super(Pow,[],l,r)

exports.LogB =
class LogB extends BinaryNode
  constructor: (l,r) -> super(LogB,[],l,r)

exports.RoundB =
class RoundB extends BinaryNode
  constructor: (l,r) -> super(RoundB,[],l,r)

exports.RewriteUnaryToBinaryNode =
class RewriteUnaryToBinaryNode extends Rule
  execute: (tree) ->
    tree.transform (node) ->
      return node unless node instanceof UnaryNode
      child = node.children[0]

      if node instanceof Round
        return new RoundB(child,new Literal(0))
      if node instanceof Log10
        return new LogB(child,new Literal(10))
      if node instanceof Exp
        return new Pow(new Literal(Math.E),child)

      return node

exports.EvalUnaryNodes =
class EvalUnaryNodes extends Rule
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
        if node instanceof Sqrt
          return new Literal(Math.sqrt(value))
        if node instanceof Ceil
          return new Literal(Math.ceil(value))
        if node instanceof Floor
          return new Literal(Math.floor(value))
        if node instanceof Ln
          return new Literal(Math.log(value))

      return node

exports.EvalBinaryNodes =
class EvalBinaryNodes extends Rule
  execute: (tree) ->
    tree.transformUp (node) ->
      children = node.children
      if(_.isEmpty(children) or not _.all children, ((c) -> c instanceof Literal))
        return node

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
        if node instanceof LogB
          return new Literal(Math.log10(l) / Math.log10(r))
        if node instanceof RoundB
          return new Literal(Math.round(l,r))
        if node instanceof Mod
          return new Literal(l % r)
        if node instanceof Pow
          return new Literal(Math.pow(l,r))

      return node

exports.EvaluationBatch =
class EvaluationBatch extends RuleBatch
  constructor: (iterations) ->
    super([
      new EvalUnaryNodes(),
      new EvalBinaryNodes(),
      new RewriteUnaryToBinaryNode()
    ], iterations)

exports.MathExecutor =
class MathExecutor extends RuleExecutor
  constructor: (iterations) -> super([new EvaluationBatch(iterations)])

exports.TextPlanner =
class TextPlanner extends Planner
  constructor: ->
    super([
      new LeafAsText(),
      new UnaryAsText(),
      new BinaryAsText()
    ])

exports.BinaryAsText =
class BinaryAsText extends PlannerStrategy
  constructor: -> super()

  execute: (tree) ->
    unless tree instanceof BinaryNode
      return []

    lInner  = @planner.planLater(tree.children[0])
    rInner  = @planner.planLater(tree.children[1])
    buildOp = (op) -> ["(#{lInner}#{op}#{rInner})"]
    buildFn = (fn) -> ["#{fn}(#{lInner},#{rInner})"]

    if tree instanceof Add
      return buildOp("+")
    if tree instanceof Sub
      return buildOp("-")
    if tree instanceof Mul
      return buildOp("*")
    if tree instanceof Div
      return buildOp("/")
    if tree instanceof Mod
      return buildOp("%")
    if tree instanceof Pow
      return buildFn("pow")
    if tree instanceof LogB
      return buildFn("log")
    if tree instanceof RoundB
      return buildFn("round")

exports.UnaryAsText =
class UnaryAsText extends PlannerStrategy
  constructor: -> super()

  execute: (tree) ->
    unless tree instanceof UnaryNode
      return []

    inner = @planner.planLater(tree.children[0])
    build = (name) -> ["#{name}(#{inner})"]

    if tree instanceof Abs
      return build("abs")
    if tree instanceof Neg
      return build("neg")
    if tree instanceof Sqrt
      return build("sqrt")
    if tree instanceof Ceil
      return build("ceil")
    if tree instanceof Floor
      return build("floor")
    if tree instanceof Ln
      return build("ln")
    if tree instanceof Exp
      return build("exp")
    if tree instanceof Log10
      return build("log10")
    if tree instanceof Round
      return build("round")

exports.LeafAsText =
class LeafAsText extends PlannerStrategy
  constructor: -> super()

  execute: (tree) ->
    unless tree instanceof LeafNode
      return []

    if tree instanceof Literal
      return ["#{tree.args[0]}"]
