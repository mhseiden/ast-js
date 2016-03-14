
/*
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
 */

(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  (function() {
    var BinaryNode, LeafNode, Planner, PlannerStrategy, Rule, RuleBatch, RuleExecutor, TreeNode, UnaryNode, _, exports, root;
    root = typeof self === 'object' && self.self === self && self || typeof global === 'object' && global.global === global && global || this;
    _ = root._ || (typeof require !== "undefined" && require !== null) && require("underscore");
    Planner = (function() {
      function Planner(strategies) {
        this.strategies = strategies;
        _.map(this.strategies, (function(_this) {
          return function(s) {
            return s.planner = _this;
          };
        })(this));
      }

      Planner.prototype.plan = function(tree) {
        var execute, planned;
        execute = function(s) {
          return s.execute(tree);
        };
        planned = _.map(this.strategies, execute);
        return _.flatten(planned);
      };

      Planner.prototype.planLater = function(tree) {
        return this.plan(tree)[0];
      };

      return Planner;

    })();
    PlannerStrategy = (function() {
      function PlannerStrategy() {}

      PlannerStrategy.prototype.execute = function() {
        return [];
      };

      return PlannerStrategy;

    })();
    RuleExecutor = (function() {
      function RuleExecutor(batches) {
        this.batches = batches != null ? batches : [];
      }

      RuleExecutor.prototype.execute = function(tree0) {
        var inner;
        inner = function(tree, batch) {
          return batch.execute(tree);
        };
        return _.foldl(this.batches, inner, tree0, {});
      };

      return RuleExecutor;

    })();
    RuleBatch = (function() {
      function RuleBatch(rules, iterations) {
        this.rules = rules;
        this.iterations = iterations;
      }

      RuleBatch.prototype.execute = function(tree0) {
        var i, inner, j, prior, ref, result;
        prior = tree0;
        result = null;
        for (i = j = 0, ref = this.iterations; j < ref; i = j += 1) {
          inner = function(tree, rule) {
            return rule.execute(tree);
          };
          result = _.foldl(this.rules, inner, prior, {});
          if (result.sameResult(prior)) {
            return result;
          }
          prior = result;
        }
        return result;
      };

      return RuleBatch;

    })();
    Rule = (function() {
      function Rule() {}

      Rule.prototype.execute = function(tree) {
        return tree;
      };

      return Rule;

    })();
    TreeNode = (function() {
      function TreeNode(ctor1, args1, children1) {
        this.ctor = ctor1;
        this.args = args1 != null ? args1 : [];
        this.children = children1 != null ? children1 : [];
        this.nodeid = TreeNode.nextNodeID();
      }

      TreeNode.prototype.nodeName = function() {
        return this.ctor.name;
      };

      TreeNode.prototype.toString = function(withID) {
        var argString, idString;
        if (withID == null) {
          withID = false;
        }
        argString = _.map(this.args, function(a) {
          return a.toString();
        }).join(",");
        idString = withID ? "#" + this.nodeid : "";
        return (this.nodeName()) + "[" + argString + "]" + idString;
      };

      TreeNode.prototype.print = function(withID, depth) {
        var children, prefix;
        if (withID == null) {
          withID = false;
        }
        if (depth == null) {
          depth = 0;
        }
        prefix = _.times(depth, function() {
          return " ";
        }).join("");
        children = _.map(this.children, function(c) {
          return c.print(withID, 1 + depth);
        });
        return "\n" + prefix + (this.toString(withID)) + (children.join(""));
      };

      TreeNode.prototype.sameResult = function(o) {
        var zipped;
        if (!_.isEqual(this.ctor, o.ctor)) {
          return false;
        }
        if (!_.isEqual(this.args, o.args)) {
          return false;
        }
        zipped = _.zip(this.children, o.children);
        return _.all(zipped, function(arg) {
          var l, r;
          l = arg[0], r = arg[1];
          return l.sameResult(r);
        });
      };

      TreeNode.prototype.copy = function(args, children) {
        var c;
        if (args == null) {
          args = this.args;
        }
        if (children == null) {
          children = this.children;
        }
        c = new this.ctor();
        c.ctor = this.ctor;
        c.args = args;
        c.children = children;
        return c;
      };

      TreeNode.prototype.walkUp = function(f) {
        return this.walk(f, false);
      };

      TreeNode.prototype.walkDown = function(f) {
        return this.walk(f, true);
      };

      TreeNode.prototype.walk = function(f, down) {
        if (down == null) {
          down = true;
        }
        if (down) {
          f(this);
          _.each(this.children, function(c) {
            return c.walk(f, down);
          });
        } else {
          _.each(this.children, function(c) {
            return c.walk(f, down);
          });
          f(this);
        }
      };

      TreeNode.prototype.find = function(f) {
        if (f(this)) {
          return this;
        }
        if (_.isEmpty(this.children)) {
          return null;
        } else {
          return _.find(this.children, function(c) {
            return c.find(f) != null;
          });
        }
      };

      TreeNode.prototype.map = function(f) {
        var res;
        res = [];
        this.walk(function(node) {
          return res.push(f(node));
        });
        return res;
      };

      TreeNode.prototype.flatMap = function(f) {
        return _.flatten(this.map(f));
      };

      TreeNode.prototype.filter = function(f) {
        return this.flatMap(function(node) {
          if (f(node)) {
            return [node];
          } else {
            return [];
          }
        });
      };

      TreeNode.prototype.transformUp = function(f) {
        return this.transform(f, false);
      };

      TreeNode.prototype.transformDown = function(f) {
        return this.transform(f, true);
      };

      TreeNode.prototype.transform = function(f, down) {
        if (down == null) {
          down = true;
        }
        return TreeNode.transform(this, f, down);
      };

      TreeNode.transform = function(node, f, down) {
        var afterF, result;
        if (down) {
          afterF = f(node);
          result = afterF.sameResult(node) ? node : afterF;
          return TreeNode.transformChildren(result, f, down);
        } else {
          afterF = TreeNode.transformChildren(node, f, down);
          result = afterF.sameResult(node) ? node : afterF;
          return f(result);
        }
      };

      TreeNode.transformChildren = function(node, f, down) {
        var c, j, len, ref, result, updated;
        updated = [];
        ref = node.children;
        for (j = 0, len = ref.length; j < len; j++) {
          c = ref[j];
          result = c.transform(f, down);
          updated.push(result);
        }
        return node.copy(node.args, updated);
      };

      TreeNode.nextNodeID = (function() {
        var id;
        id = 0;
        return function() {
          return ++id;
        };
      })();

      return TreeNode;

    })();
    LeafNode = (function(superClass) {
      extend(LeafNode, superClass);

      function LeafNode(ctor, args) {
        LeafNode.__super__.constructor.call(this, ctor, args, []);
      }

      return LeafNode;

    })(TreeNode);
    UnaryNode = (function(superClass) {
      extend(UnaryNode, superClass);

      function UnaryNode(ctor, args, child) {
        UnaryNode.__super__.constructor.call(this, ctor, args, [child]);
      }

      return UnaryNode;

    })(TreeNode);
    BinaryNode = (function(superClass) {
      extend(BinaryNode, superClass);

      function BinaryNode(ctor, args, l, r) {
        BinaryNode.__super__.constructor.call(this, ctor, args, [l, r]);
      }

      return BinaryNode;

    })(TreeNode);
    if ((typeof module !== "undefined" && module !== null) && !module.nodeType) {
      exports = module.exports = {};
    } else {
      exports = root.astjs = {};
    }
    exports.TreeNode = TreeNode;
    exports.LeafNode = LeafNode;
    exports.UnaryNode = UnaryNode;
    exports.BinaryNode = BinaryNode;
    exports.Rule = Rule;
    exports.RuleBatch = RuleBatch;
    exports.RuleExecutor = RuleExecutor;
    exports.Planner = Planner;
    exports.PlannerStrategy = PlannerStrategy;
  })();

}).call(this);
