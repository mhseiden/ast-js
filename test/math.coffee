{ TreeNode, UnaryNode, LeafNode, BinaryNode, Rule, RuleExecutor, RuleBatch } = require("../treenode.coffee")

_ = require("underscore")

class Literal extends LeafNode
  constructor: (v) -> super(Literal,[v])

class Abs extends UnaryNode
  constructor: (c) -> super(Abs,[],c)

class Neg extends UnaryNode
  constructor: (c) -> super(Neg,[],c)

class Sqrt extends UnaryNode
  constructor: (c) -> super(Sqrt,[],c)

class Ceil extends UnaryNode
  constructor: (c) -> super(Ceil,[],c)

class Floor extends UnaryNode
  constructor: (c) -> super(Floor,[],c)

class Ln extends UnaryNode
  constructor: (c) -> super(Ln,[],c)

class Exp extends UnaryNode
  constructor: (c) -> super(Exp,[],c)

class Log10 extends UnaryNode
  constructor: (c) -> super(Log10,[],c)

class Round extends UnaryNode
  constructor: (c) -> super(Round,[],c)

class Add extends BinaryNode
  constructor: (l,r) -> super(Add,[],l,r)

class Sub extends BinaryNode
  constructor: (l,r) -> super(Sub,[],l,r)

class Mul extends BinaryNode
  constructor: (l,r) -> super(Mul,[],l,r)

class Div extends BinaryNode
  constructor: (l,r) -> super(Div,[],l,r)

class Mod extends BinaryNode
  constructor: (l,r) -> super(Mod,[],l,r)

class Pow extends BinaryNode
  constructor: (l,r) -> super(Pow,[],l,r)

class LogB extends BinaryNode
  constructor: (l,r) -> super(LogB,[],l,r)

class RoundB extends BinaryNode
  constructor: (l,r) -> super(RoundB,[],l,r)

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

class EvaluationBatch extends RuleBatch
  constructor: (iterations) ->
    super([
      new EvalUnaryNodes(),
      new EvalBinaryNodes(),
      new RewriteUnaryToBinaryNode()
    ], iterations)

class MathExecutor extends RuleExecutor
  constructor: (iterations) -> super([new EvaluationBatch(iterations)])

EVAL_1    = new MathExecutor(1)
EVAL_10   = new MathExecutor(10)
EVAL_100  = new MathExecutor(100)
EVAL_1000 = new MathExecutor(1000)

N_FIVE  = new Literal(-5)
N_FOUR  = new Literal(-4)
N_THREE = new Literal(-3)
N_TWO   = new Literal(-2)
N_ONE   = new Literal(-1)
ZERO    = new Literal(0)
ONE     = new Literal(1)
TWO     = new Literal(2)
THREE   = new Literal(3)
FOUR    = new Literal(4)
FIVE    = new Literal(5)

assert = require("assert")

SAME = yes
DIFF = no
check = (lhs,rhs,expected = SAME) ->
  if not expected is lhs.sameResult(rhs)
    assert.equal(lhs.toString(),rhs.toString())

describe "Arithmetic Evaluation", ->
  describe "Leaf Operators", ->
    it "should have equality for leaf operators (via direct)", ->
      check ZERO, ZERO, SAME

    it "should have inequality for leaf operators (via direct)", ->
      check ZERO, ONE, DIFF

    it "should have equality for leaf operators (via eval)", ->
      check ZERO, EVAL_1.execute(ZERO), SAME

    it "should have inequality for leaf operators (via eval)", ->
      check ZERO, EVAL_1.execute(ONE), DIFF

  describe "Unary Operators", ->
    it "should be correct for abs (1)", ->
      expr = new Abs(N_TWO)
      check TWO, EVAL_1.execute(expr), SAME

    it "should be correct for abs (2)", ->
      expr = new Abs(TWO)
      check TWO, EVAL_1.execute(expr), SAME

    it "should be correct for neg (1)", ->
      expr = new Neg(N_TWO)
      check TWO, EVAL_1.execute(expr), SAME

    it "should be correct for neg (2)", ->
      expr = new Neg(TWO)
      check N_TWO, EVAL_1.execute(expr), SAME

    it "should be correct for sqrt", ->
      expr = new Sqrt(FOUR)
      check TWO, EVAL_1.execute(expr), SAME

    it "should be correct for ceil", ->
      expr = new Ceil(new Literal(1.5))
      check TWO, EVAL_1.execute(expr), SAME

    it "should be correct for floor", ->
      expr = new Floor(new Literal(1.5))
      check ONE, EVAL_1.execute(expr), SAME

    it "should be correct for ln", ->
      expr = new Ceil(new Ln(new Literal(10)))
      check THREE, EVAL_1.execute(expr), SAME

    it "should be correct for log10 (eval[1])", ->
      expr = new Log10(new Literal(10))
      check ONE, EVAL_1.execute(expr), DIFF

    it "should be correct for log10 (eval[10])", ->
      expr = new Log10(new Literal(10))
      check ONE, EVAL_10.execute(expr), SAME

    it "should be correct for round (eval[1])", ->
      expr = new Round(new Literal(1.1))
      check ONE, EVAL_1.execute(expr), DIFF

    it "should be correct for round (eval[10])", ->
      expr = new Round(new Literal(1.1))
      check ONE, EVAL_10.execute(expr), SAME

    it "should be correct for exp (eval[1])", ->
      expr = new Exp(ONE)
      check new Literal(Math.E), EVAL_1.execute(expr), DIFF

    it "should be correct for exp (eval[10])", ->
      expr = new Exp(ONE)
      check new Literal(Math.E), EVAL_10.execute(expr), SAME

  describe "Binary Operators", ->
    it "should be correct for add", ->
      expr = new Add(ONE,TWO)
      check THREE, EVAL_1.execute(expr), SAME

    it "should be correct for sub", ->
      expr = new Sub(FIVE,ONE)
      check FOUR, EVAL_1.execute(expr), SAME

    it "should be correct for mul", ->
      expr = new Mul(THREE,TWO)
      check new Literal(6), EVAL_1.execute(expr), SAME

    it "should be correct for div", ->
      expr = new Div(new Literal(6),TWO)
      check THREE, EVAL_1.execute(expr), SAME

    it "should be correct for mod", ->
      expr = new Mod(THREE,TWO)
      check ONE, EVAL_1.execute(expr), SAME

    it "should be correct for pow", ->
      expr = new Pow(THREE,TWO)
      check new Literal(9), EVAL_1.execute(expr), SAME

    it "should be correct for logb", ->
      expr = new LogB(new Literal(100),new Literal(10))
      check TWO, EVAL_1.execute(expr), SAME

    it "should be correct for roundb", ->
      expr = new RoundB(new Literal(1.6), ZERO)
      check TWO, EVAL_1.execute(expr), SAME
