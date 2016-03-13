_ = require("underscore")
Algebra = require("./algebra.coffee")
{ Abs, Sub, Add, Neg } = Algebra

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

PLANNER = new Algebra.TextPlanner()
planFirst = (tree) -> PLANNER.plan(tree)[0]

assert = require("assert")

describe "Expression Rendering (via planner)", ->
  describe "Planner Construction", ->
    it "should have strategies", ->
      assert PLANNER.strategies?
      assert _.isArray PLANNER.strategies

    it "should bind the planner to strategies", ->
      _.all PLANNER.strategies, (s) -> assert.equal s.planner, PLANNER

  describe "Leaf Rendering", ->
    it "should render literals correctly :  0", ->
      assert.equal "0", planFirst(ZERO)

    it "should render literals correctly :  1", ->
      assert.equal "1", planFirst(ONE)

    it "should render literals correctly : -1", ->
      assert.equal "-1", planFirst(N_ONE)


  describe "Unary Rendering", ->
    it "should render abs(0)", ->
      assert.equal "abs(0)", planFirst(new Algebra.Abs(ZERO))

    it "should render neg(0)", ->
      assert.equal "neg(0)", planFirst(new Algebra.Neg(ZERO))

    it "should render sqrt(0)", ->
      assert.equal "sqrt(0)", planFirst(new Algebra.Sqrt(ZERO))

    it "should render ceil(0)", ->
      assert.equal "ceil(0)", planFirst(new Algebra.Ceil(ZERO))

    it "should render floor(0)", ->
      assert.equal "floor(0)", planFirst(new Algebra.Floor(ZERO))

    it "should render ln(0)", ->
      assert.equal "ln(0)", planFirst(new Algebra.Ln(ZERO))

    it "should render exp(0)", ->
      assert.equal "exp(0)", planFirst(new Algebra.Exp(ZERO))

    it "should render log10(0)", ->
      assert.equal "log10(0)", planFirst(new Algebra.Log10(ZERO))

    it "should render round(0)", ->
      assert.equal "round(0)", planFirst(new Algebra.Round(ZERO))

    it "should render neg(neg(neg(1)))", ->
      assert.equal "neg(neg(neg(1)))", planFirst(new Neg(new Neg(new Neg(ONE))))

  describe "Binary Rendering", ->
    it "should render (2+1)", ->
      assert.equal "(2+1)", planFirst(new Algebra.Add(TWO,ONE))

    it "should render (2-1)", ->
      assert.equal "(2-1)", planFirst(new Algebra.Sub(TWO,ONE))

    it "should render (2*1)", ->
      assert.equal "(2*1)", planFirst(new Algebra.Mul(TWO,ONE))

    it "should render (2/1)", ->
      assert.equal "(2/1)", planFirst(new Algebra.Div(TWO,ONE))

    it "should render (2%1)", ->
      assert.equal "(2%1)", planFirst(new Algebra.Mod(TWO,ONE))

    it "should render pow(2,1)", ->
      assert.equal "pow(2,1)", planFirst(new Algebra.Pow(TWO,ONE))

    it "should render log(2,1)", ->
      assert.equal "log(2,1)", planFirst(new Algebra.LogB(TWO,ONE))

    it "should render round(2,1)", ->
      assert.equal "round(2,1)", planFirst(new Algebra.RoundB(TWO,ONE))

    it "should render ((2+1)-(1+1))", ->
      assert.equal "((2+1)-(1+1))", planFirst(new Sub(new Add(TWO,ONE),new Add(ONE,ONE)))

    describe "Mixed Rendering", ->
      it "should render neg((1+1))", ->
        assert.equal "neg((1+1))", planFirst(new Neg(new Add(ONE,ONE)))

      it "should render (neg(1)+abs(-1))", ->
        assert.equal "(neg(1)+abs(-1))", planFirst(new Add(new Neg(ONE),new Abs(N_ONE)))
