Algebra = require("./algebra.coffee")

EVAL_1    = new Algebra.MathExecutor(1)
EVAL_10   = new Algebra.MathExecutor(10)
EVAL_100  = new Algebra.MathExecutor(100)
EVAL_1000 = new Algebra.MathExecutor(1000)

N_FIVE  = new Algebra.Literal(-5)
N_FOUR  = new Algebra.Literal(-4)
N_THREE = new Algebra.Literal(-3)
N_TWO   = new Algebra.Literal(-2)
N_ONE   = new Algebra.Literal(-1)
ZERO    = new Algebra.Literal(0)
ONE     = new Algebra.Literal(1)
TWO     = new Algebra.Literal(2)
THREE   = new Algebra.Literal(3)
FOUR    = new Algebra.Literal(4)
FIVE    = new Algebra.Literal(5)

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
      expr = new Algebra.Abs(N_TWO)
      check TWO, EVAL_1.execute(expr), SAME

    it "should be correct for abs (2)", ->
      expr = new Algebra.Abs(TWO)
      check TWO, EVAL_1.execute(expr), SAME

    it "should be correct for neg (1)", ->
      expr = new Algebra.Neg(N_TWO)
      check TWO, EVAL_1.execute(expr), SAME

    it "should be correct for neg (2)", ->
      expr = new Algebra.Neg(TWO)
      check N_TWO, EVAL_1.execute(expr), SAME

    it "should be correct for sqrt", ->
      expr = new Algebra.Sqrt(FOUR)
      check TWO, EVAL_1.execute(expr), SAME

    it "should be correct for ceil", ->
      expr = new Algebra.Ceil(new Algebra.Literal(1.5))
      check TWO, EVAL_1.execute(expr), SAME

    it "should be correct for floor", ->
      expr = new Algebra.Floor(new Algebra.Literal(1.5))
      check ONE, EVAL_1.execute(expr), SAME

    it "should be correct for ln", ->
      expr = new Algebra.Ceil(new Algebra.Ln(new Algebra.Literal(10)))
      check THREE, EVAL_1.execute(expr), SAME

    it "should be correct for log10 (eval[1])", ->
      expr = new Algebra.Log10(new Algebra.Literal(10))
      check ONE, EVAL_1.execute(expr), DIFF

    it "should be correct for log10 (eval[10])", ->
      expr = new Algebra.Log10(new Algebra.Literal(10))
      check ONE, EVAL_10.execute(expr), SAME

    it "should be correct for round (eval[1])", ->
      expr = new Algebra.Round(new Algebra.Literal(1.1))
      check ONE, EVAL_1.execute(expr), DIFF

    it "should be correct for round (eval[10])", ->
      expr = new Algebra.Round(new Algebra.Literal(1.1))
      check ONE, EVAL_10.execute(expr), SAME

    it "should be correct for exp (eval[1])", ->
      expr = new Algebra.Exp(ONE)
      check new Algebra.Literal(Math.E), EVAL_1.execute(expr), DIFF

    it "should be correct for exp (eval[10])", ->
      expr = new Algebra.Exp(ONE)
      check new Algebra.Literal(Math.E), EVAL_10.execute(expr), SAME

  describe "Binary Operators", ->
    it "should be correct for add", ->
      expr = new Algebra.Add(ONE,TWO)
      check THREE, EVAL_1.execute(expr), SAME

    it "should be correct for sub", ->
      expr = new Algebra.Sub(FIVE,ONE)
      check FOUR, EVAL_1.execute(expr), SAME

    it "should be correct for mul", ->
      expr = new Algebra.Mul(THREE,TWO)
      check new Algebra.Literal(6), EVAL_1.execute(expr), SAME

    it "should be correct for div", ->
      expr = new Algebra.Div(new Algebra.Literal(6),TWO)
      check THREE, EVAL_1.execute(expr), SAME

    it "should be correct for mod", ->
      expr = new Algebra.Mod(THREE,TWO)
      check ONE, EVAL_1.execute(expr), SAME

    it "should be correct for pow", ->
      expr = new Algebra.Pow(THREE,TWO)
      check new Algebra.Literal(9), EVAL_1.execute(expr), SAME

    it "should be correct for logb", ->
      expr = new Algebra.LogB(new Algebra.Literal(100),new Algebra.Literal(10))
      check TWO, EVAL_1.execute(expr), SAME

    it "should be correct for roundb", ->
      expr = new Algebra.RoundB(new Algebra.Literal(1.6), ZERO)
      check TWO, EVAL_1.execute(expr), SAME
