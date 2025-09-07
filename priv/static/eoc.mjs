var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// node_modules/@dagrejs/graphlib/lib/graph.js
var require_graph = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/graph.js"(exports, module) {
    "use strict";
    var DEFAULT_EDGE_NAME = "\0";
    var GRAPH_NODE = "\0";
    var EDGE_KEY_DELIM = "";
    var Graph4 = class {
      _isDirected = true;
      _isMultigraph = false;
      _isCompound = false;
      // Label for the graph itself
      _label;
      // Defaults to be set when creating a new node
      _defaultNodeLabelFn = () => void 0;
      // Defaults to be set when creating a new edge
      _defaultEdgeLabelFn = () => void 0;
      // v -> label
      _nodes = {};
      // v -> edgeObj
      _in = {};
      // u -> v -> Number
      _preds = {};
      // v -> edgeObj
      _out = {};
      // v -> w -> Number
      _sucs = {};
      // e -> edgeObj
      _edgeObjs = {};
      // e -> label
      _edgeLabels = {};
      /* Number of nodes in the graph. Should only be changed by the implementation. */
      _nodeCount = 0;
      /* Number of edges in the graph. Should only be changed by the implementation. */
      _edgeCount = 0;
      _parent;
      _children;
      constructor(opts) {
        if (opts) {
          this._isDirected = Object.hasOwn(opts, "directed") ? opts.directed : true;
          this._isMultigraph = Object.hasOwn(opts, "multigraph") ? opts.multigraph : false;
          this._isCompound = Object.hasOwn(opts, "compound") ? opts.compound : false;
        }
        if (this._isCompound) {
          this._parent = {};
          this._children = {};
          this._children[GRAPH_NODE] = {};
        }
      }
      /* === Graph functions ========= */
      /**
       * Whether graph was created with 'directed' flag set to true or not.
       */
      isDirected() {
        return this._isDirected;
      }
      /**
       * Whether graph was created with 'multigraph' flag set to true or not.
       */
      isMultigraph() {
        return this._isMultigraph;
      }
      /**
       * Whether graph was created with 'compound' flag set to true or not.
       */
      isCompound() {
        return this._isCompound;
      }
      /**
       * Sets the label of the graph.
       */
      setGraph(label) {
        this._label = label;
        return this;
      }
      /**
       * Gets the graph label.
       */
      graph() {
        return this._label;
      }
      /* === Node functions ========== */
      /**
       * Sets the default node label. If newDefault is a function, it will be
       * invoked ach time when setting a label for a node. Otherwise, this label
       * will be assigned as default label in case if no label was specified while
       * setting a node.
       * Complexity: O(1).
       */
      setDefaultNodeLabel(newDefault) {
        this._defaultNodeLabelFn = newDefault;
        if (typeof newDefault !== "function") {
          this._defaultNodeLabelFn = () => newDefault;
        }
        return this;
      }
      /**
       * Gets the number of nodes in the graph.
       * Complexity: O(1).
       */
      nodeCount() {
        return this._nodeCount;
      }
      /**
       * Gets all nodes of the graph. Note, the in case of compound graph subnodes are
       * not included in list.
       * Complexity: O(1).
       */
      nodes() {
        return Object.keys(this._nodes);
      }
      /**
       * Gets list of nodes without in-edges.
       * Complexity: O(|V|).
       */
      sources() {
        var self = this;
        return this.nodes().filter((v) => Object.keys(self._in[v]).length === 0);
      }
      /**
       * Gets list of nodes without out-edges.
       * Complexity: O(|V|).
       */
      sinks() {
        var self = this;
        return this.nodes().filter((v) => Object.keys(self._out[v]).length === 0);
      }
      /**
       * Invokes setNode method for each node in names list.
       * Complexity: O(|names|).
       */
      setNodes(vs, value) {
        var args = arguments;
        var self = this;
        vs.forEach(function(v) {
          if (args.length > 1) {
            self.setNode(v, value);
          } else {
            self.setNode(v);
          }
        });
        return this;
      }
      /**
       * Creates or updates the value for the node v in the graph. If label is supplied
       * it is set as the value for the node. If label is not supplied and the node was
       * created by this call then the default node label will be assigned.
       * Complexity: O(1).
       */
      setNode(v, value) {
        if (Object.hasOwn(this._nodes, v)) {
          if (arguments.length > 1) {
            this._nodes[v] = value;
          }
          return this;
        }
        this._nodes[v] = arguments.length > 1 ? value : this._defaultNodeLabelFn(v);
        if (this._isCompound) {
          this._parent[v] = GRAPH_NODE;
          this._children[v] = {};
          this._children[GRAPH_NODE][v] = true;
        }
        this._in[v] = {};
        this._preds[v] = {};
        this._out[v] = {};
        this._sucs[v] = {};
        ++this._nodeCount;
        return this;
      }
      /**
       * Gets the label of node with specified name.
       * Complexity: O(|V|).
       */
      node(v) {
        return this._nodes[v];
      }
      /**
       * Detects whether graph has a node with specified name or not.
       */
      hasNode(v) {
        return Object.hasOwn(this._nodes, v);
      }
      /**
       * Remove the node with the name from the graph or do nothing if the node is not in
       * the graph. If the node was removed this function also removes any incident
       * edges.
       * Complexity: O(1).
       */
      removeNode(v) {
        var self = this;
        if (Object.hasOwn(this._nodes, v)) {
          var removeEdge = (e) => self.removeEdge(self._edgeObjs[e]);
          delete this._nodes[v];
          if (this._isCompound) {
            this._removeFromParentsChildList(v);
            delete this._parent[v];
            this.children(v).forEach(function(child) {
              self.setParent(child);
            });
            delete this._children[v];
          }
          Object.keys(this._in[v]).forEach(removeEdge);
          delete this._in[v];
          delete this._preds[v];
          Object.keys(this._out[v]).forEach(removeEdge);
          delete this._out[v];
          delete this._sucs[v];
          --this._nodeCount;
        }
        return this;
      }
      /**
       * Sets node p as a parent for node v if it is defined, or removes the
       * parent for v if p is undefined. Method throws an exception in case of
       * invoking it in context of noncompound graph.
       * Average-case complexity: O(1).
       */
      setParent(v, parent) {
        if (!this._isCompound) {
          throw new Error("Cannot set parent in a non-compound graph");
        }
        if (parent === void 0) {
          parent = GRAPH_NODE;
        } else {
          parent += "";
          for (var ancestor = parent; ancestor !== void 0; ancestor = this.parent(ancestor)) {
            if (ancestor === v) {
              throw new Error("Setting " + parent + " as parent of " + v + " would create a cycle");
            }
          }
          this.setNode(parent);
        }
        this.setNode(v);
        this._removeFromParentsChildList(v);
        this._parent[v] = parent;
        this._children[parent][v] = true;
        return this;
      }
      _removeFromParentsChildList(v) {
        delete this._children[this._parent[v]][v];
      }
      /**
       * Gets parent node for node v.
       * Complexity: O(1).
       */
      parent(v) {
        if (this._isCompound) {
          var parent = this._parent[v];
          if (parent !== GRAPH_NODE) {
            return parent;
          }
        }
      }
      /**
       * Gets list of direct children of node v.
       * Complexity: O(1).
       */
      children(v = GRAPH_NODE) {
        if (this._isCompound) {
          var children = this._children[v];
          if (children) {
            return Object.keys(children);
          }
        } else if (v === GRAPH_NODE) {
          return this.nodes();
        } else if (this.hasNode(v)) {
          return [];
        }
      }
      /**
       * Return all nodes that are predecessors of the specified node or undefined if node v is not in
       * the graph. Behavior is undefined for undirected graphs - use neighbors instead.
       * Complexity: O(|V|).
       */
      predecessors(v) {
        var predsV = this._preds[v];
        if (predsV) {
          return Object.keys(predsV);
        }
      }
      /**
       * Return all nodes that are successors of the specified node or undefined if node v is not in
       * the graph. Behavior is undefined for undirected graphs - use neighbors instead.
       * Complexity: O(|V|).
       */
      successors(v) {
        var sucsV = this._sucs[v];
        if (sucsV) {
          return Object.keys(sucsV);
        }
      }
      /**
       * Return all nodes that are predecessors or successors of the specified node or undefined if
       * node v is not in the graph.
       * Complexity: O(|V|).
       */
      neighbors(v) {
        var preds = this.predecessors(v);
        if (preds) {
          const union2 = new Set(preds);
          for (var succ of this.successors(v)) {
            union2.add(succ);
          }
          return Array.from(union2.values());
        }
      }
      isLeaf(v) {
        var neighbors;
        if (this.isDirected()) {
          neighbors = this.successors(v);
        } else {
          neighbors = this.neighbors(v);
        }
        return neighbors.length === 0;
      }
      /**
       * Creates new graph with nodes filtered via filter. Edges incident to rejected node
       * are also removed. In case of compound graph, if parent is rejected by filter,
       * than all its children are rejected too.
       * Average-case complexity: O(|E|+|V|).
       */
      filterNodes(filter2) {
        var copy = new this.constructor({
          directed: this._isDirected,
          multigraph: this._isMultigraph,
          compound: this._isCompound
        });
        copy.setGraph(this.graph());
        var self = this;
        Object.entries(this._nodes).forEach(function([v, value]) {
          if (filter2(v)) {
            copy.setNode(v, value);
          }
        });
        Object.values(this._edgeObjs).forEach(function(e) {
          if (copy.hasNode(e.v) && copy.hasNode(e.w)) {
            copy.setEdge(e, self.edge(e));
          }
        });
        var parents = {};
        function findParent(v) {
          var parent = self.parent(v);
          if (parent === void 0 || copy.hasNode(parent)) {
            parents[v] = parent;
            return parent;
          } else if (parent in parents) {
            return parents[parent];
          } else {
            return findParent(parent);
          }
        }
        if (this._isCompound) {
          copy.nodes().forEach((v) => copy.setParent(v, findParent(v)));
        }
        return copy;
      }
      /* === Edge functions ========== */
      /**
       * Sets the default edge label or factory function. This label will be
       * assigned as default label in case if no label was specified while setting
       * an edge or this function will be invoked each time when setting an edge
       * with no label specified and returned value * will be used as a label for edge.
       * Complexity: O(1).
       */
      setDefaultEdgeLabel(newDefault) {
        this._defaultEdgeLabelFn = newDefault;
        if (typeof newDefault !== "function") {
          this._defaultEdgeLabelFn = () => newDefault;
        }
        return this;
      }
      /**
       * Gets the number of edges in the graph.
       * Complexity: O(1).
       */
      edgeCount() {
        return this._edgeCount;
      }
      /**
       * Gets edges of the graph. In case of compound graph subgraphs are not considered.
       * Complexity: O(|E|).
       */
      edges() {
        return Object.values(this._edgeObjs);
      }
      /**
       * Establish an edges path over the nodes in nodes list. If some edge is already
       * exists, it will update its label, otherwise it will create an edge between pair
       * of nodes with label provided or default label if no label provided.
       * Complexity: O(|nodes|).
       */
      setPath(vs, value) {
        var self = this;
        var args = arguments;
        vs.reduce(function(v, w) {
          if (args.length > 1) {
            self.setEdge(v, w, value);
          } else {
            self.setEdge(v, w);
          }
          return w;
        });
        return this;
      }
      /**
       * Creates or updates the label for the edge (v, w) with the optionally supplied
       * name. If label is supplied it is set as the value for the edge. If label is not
       * supplied and the edge was created by this call then the default edge label will
       * be assigned. The name parameter is only useful with multigraphs.
       */
      setEdge() {
        var v, w, name, value;
        var valueSpecified = false;
        var arg0 = arguments[0];
        if (typeof arg0 === "object" && arg0 !== null && "v" in arg0) {
          v = arg0.v;
          w = arg0.w;
          name = arg0.name;
          if (arguments.length === 2) {
            value = arguments[1];
            valueSpecified = true;
          }
        } else {
          v = arg0;
          w = arguments[1];
          name = arguments[3];
          if (arguments.length > 2) {
            value = arguments[2];
            valueSpecified = true;
          }
        }
        v = "" + v;
        w = "" + w;
        if (name !== void 0) {
          name = "" + name;
        }
        var e = edgeArgsToId(this._isDirected, v, w, name);
        if (Object.hasOwn(this._edgeLabels, e)) {
          if (valueSpecified) {
            this._edgeLabels[e] = value;
          }
          return this;
        }
        if (name !== void 0 && !this._isMultigraph) {
          throw new Error("Cannot set a named edge when isMultigraph = false");
        }
        this.setNode(v);
        this.setNode(w);
        this._edgeLabels[e] = valueSpecified ? value : this._defaultEdgeLabelFn(v, w, name);
        var edgeObj = edgeArgsToObj(this._isDirected, v, w, name);
        v = edgeObj.v;
        w = edgeObj.w;
        Object.freeze(edgeObj);
        this._edgeObjs[e] = edgeObj;
        incrementOrInitEntry(this._preds[w], v);
        incrementOrInitEntry(this._sucs[v], w);
        this._in[w][e] = edgeObj;
        this._out[v][e] = edgeObj;
        this._edgeCount++;
        return this;
      }
      /**
       * Gets the label for the specified edge.
       * Complexity: O(1).
       */
      edge(v, w, name) {
        var e = arguments.length === 1 ? edgeObjToId(this._isDirected, arguments[0]) : edgeArgsToId(this._isDirected, v, w, name);
        return this._edgeLabels[e];
      }
      /**
       * Gets the label for the specified edge and converts it to an object.
       * Complexity: O(1)
       */
      edgeAsObj() {
        const edge = this.edge(...arguments);
        if (typeof edge !== "object") {
          return { label: edge };
        }
        return edge;
      }
      /**
       * Detects whether the graph contains specified edge or not. No subgraphs are considered.
       * Complexity: O(1).
       */
      hasEdge(v, w, name) {
        var e = arguments.length === 1 ? edgeObjToId(this._isDirected, arguments[0]) : edgeArgsToId(this._isDirected, v, w, name);
        return Object.hasOwn(this._edgeLabels, e);
      }
      /**
       * Removes the specified edge from the graph. No subgraphs are considered.
       * Complexity: O(1).
       */
      removeEdge(v, w, name) {
        var e = arguments.length === 1 ? edgeObjToId(this._isDirected, arguments[0]) : edgeArgsToId(this._isDirected, v, w, name);
        var edge = this._edgeObjs[e];
        if (edge) {
          v = edge.v;
          w = edge.w;
          delete this._edgeLabels[e];
          delete this._edgeObjs[e];
          decrementOrRemoveEntry(this._preds[w], v);
          decrementOrRemoveEntry(this._sucs[v], w);
          delete this._in[w][e];
          delete this._out[v][e];
          this._edgeCount--;
        }
        return this;
      }
      /**
       * Return all edges that point to the node v. Optionally filters those edges down to just those
       * coming from node u. Behavior is undefined for undirected graphs - use nodeEdges instead.
       * Complexity: O(|E|).
       */
      inEdges(v, u) {
        var inV = this._in[v];
        if (inV) {
          var edges = Object.values(inV);
          if (!u) {
            return edges;
          }
          return edges.filter((edge) => edge.v === u);
        }
      }
      /**
       * Return all edges that are pointed at by node v. Optionally filters those edges down to just
       * those point to w. Behavior is undefined for undirected graphs - use nodeEdges instead.
       * Complexity: O(|E|).
       */
      outEdges(v, w) {
        var outV = this._out[v];
        if (outV) {
          var edges = Object.values(outV);
          if (!w) {
            return edges;
          }
          return edges.filter((edge) => edge.w === w);
        }
      }
      /**
       * Returns all edges to or from node v regardless of direction. Optionally filters those edges
       * down to just those between nodes v and w regardless of direction.
       * Complexity: O(|E|).
       */
      nodeEdges(v, w) {
        var inEdges = this.inEdges(v, w);
        if (inEdges) {
          return inEdges.concat(this.outEdges(v, w));
        }
      }
    };
    function incrementOrInitEntry(map7, k) {
      if (map7[k]) {
        map7[k]++;
      } else {
        map7[k] = 1;
      }
    }
    function decrementOrRemoveEntry(map7, k) {
      if (!--map7[k]) {
        delete map7[k];
      }
    }
    function edgeArgsToId(isDirected, v_, w_, name) {
      var v = "" + v_;
      var w = "" + w_;
      if (!isDirected && v > w) {
        var tmp = v;
        v = w;
        w = tmp;
      }
      return v + EDGE_KEY_DELIM + w + EDGE_KEY_DELIM + (name === void 0 ? DEFAULT_EDGE_NAME : name);
    }
    function edgeArgsToObj(isDirected, v_, w_, name) {
      var v = "" + v_;
      var w = "" + w_;
      if (!isDirected && v > w) {
        var tmp = v;
        v = w;
        w = tmp;
      }
      var edgeObj = { v, w };
      if (name) {
        edgeObj.name = name;
      }
      return edgeObj;
    }
    function edgeObjToId(isDirected, edgeObj) {
      return edgeArgsToId(isDirected, edgeObj.v, edgeObj.w, edgeObj.name);
    }
    module.exports = Graph4;
  }
});

// node_modules/@dagrejs/graphlib/lib/version.js
var require_version = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/version.js"(exports, module) {
    module.exports = "2.2.4";
  }
});

// node_modules/@dagrejs/graphlib/lib/index.js
var require_lib = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/index.js"(exports, module) {
    module.exports = {
      Graph: require_graph(),
      version: require_version()
    };
  }
});

// node_modules/@dagrejs/graphlib/lib/json.js
var require_json = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/json.js"(exports, module) {
    var Graph4 = require_graph();
    module.exports = {
      write,
      read
    };
    function write(g) {
      var json2 = {
        options: {
          directed: g.isDirected(),
          multigraph: g.isMultigraph(),
          compound: g.isCompound()
        },
        nodes: writeNodes(g),
        edges: writeEdges(g)
      };
      if (g.graph() !== void 0) {
        json2.value = structuredClone(g.graph());
      }
      return json2;
    }
    function writeNodes(g) {
      return g.nodes().map(function(v) {
        var nodeValue = g.node(v);
        var parent = g.parent(v);
        var node = { v };
        if (nodeValue !== void 0) {
          node.value = nodeValue;
        }
        if (parent !== void 0) {
          node.parent = parent;
        }
        return node;
      });
    }
    function writeEdges(g) {
      return g.edges().map(function(e) {
        var edgeValue = g.edge(e);
        var edge = { v: e.v, w: e.w };
        if (e.name !== void 0) {
          edge.name = e.name;
        }
        if (edgeValue !== void 0) {
          edge.value = edgeValue;
        }
        return edge;
      });
    }
    function read(json2) {
      var g = new Graph4(json2.options).setGraph(json2.value);
      json2.nodes.forEach(function(entry) {
        g.setNode(entry.v, entry.value);
        if (entry.parent) {
          g.setParent(entry.v, entry.parent);
        }
      });
      json2.edges.forEach(function(entry) {
        g.setEdge({ v: entry.v, w: entry.w, name: entry.name }, entry.value);
      });
      return g;
    }
  }
});

// node_modules/@dagrejs/graphlib/lib/alg/components.js
var require_components = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/alg/components.js"(exports, module) {
    module.exports = components;
    function components(g) {
      var visited = {};
      var cmpts = [];
      var cmpt;
      function dfs(v) {
        if (Object.hasOwn(visited, v)) return;
        visited[v] = true;
        cmpt.push(v);
        g.successors(v).forEach(dfs);
        g.predecessors(v).forEach(dfs);
      }
      g.nodes().forEach(function(v) {
        cmpt = [];
        dfs(v);
        if (cmpt.length) {
          cmpts.push(cmpt);
        }
      });
      return cmpts;
    }
  }
});

// node_modules/@dagrejs/graphlib/lib/data/priority-queue.js
var require_priority_queue = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/data/priority-queue.js"(exports, module) {
    var PriorityQueue = class {
      _arr = [];
      _keyIndices = {};
      /**
       * Returns the number of elements in the queue. Takes `O(1)` time.
       */
      size() {
        return this._arr.length;
      }
      /**
       * Returns the keys that are in the queue. Takes `O(n)` time.
       */
      keys() {
        return this._arr.map(function(x) {
          return x.key;
        });
      }
      /**
       * Returns `true` if **key** is in the queue and `false` if not.
       */
      has(key) {
        return Object.hasOwn(this._keyIndices, key);
      }
      /**
       * Returns the priority for **key**. If **key** is not present in the queue
       * then this function returns `undefined`. Takes `O(1)` time.
       *
       * @param {Object} key
       */
      priority(key) {
        var index4 = this._keyIndices[key];
        if (index4 !== void 0) {
          return this._arr[index4].priority;
        }
      }
      /**
       * Returns the key for the minimum element in this queue. If the queue is
       * empty this function throws an Error. Takes `O(1)` time.
       */
      min() {
        if (this.size() === 0) {
          throw new Error("Queue underflow");
        }
        return this._arr[0].key;
      }
      /**
       * Inserts a new key into the priority queue. If the key already exists in
       * the queue this function returns `false`; otherwise it will return `true`.
       * Takes `O(n)` time.
       *
       * @param {Object} key the key to add
       * @param {Number} priority the initial priority for the key
       */
      add(key, priority) {
        var keyIndices = this._keyIndices;
        key = String(key);
        if (!Object.hasOwn(keyIndices, key)) {
          var arr = this._arr;
          var index4 = arr.length;
          keyIndices[key] = index4;
          arr.push({ key, priority });
          this._decrease(index4);
          return true;
        }
        return false;
      }
      /**
       * Removes and returns the smallest key in the queue. Takes `O(log n)` time.
       */
      removeMin() {
        this._swap(0, this._arr.length - 1);
        var min3 = this._arr.pop();
        delete this._keyIndices[min3.key];
        this._heapify(0);
        return min3.key;
      }
      /**
       * Decreases the priority for **key** to **priority**. If the new priority is
       * greater than the previous priority, this function will throw an Error.
       *
       * @param {Object} key the key for which to raise priority
       * @param {Number} priority the new priority for the key
       */
      decrease(key, priority) {
        var index4 = this._keyIndices[key];
        if (priority > this._arr[index4].priority) {
          throw new Error("New priority is greater than current priority. Key: " + key + " Old: " + this._arr[index4].priority + " New: " + priority);
        }
        this._arr[index4].priority = priority;
        this._decrease(index4);
      }
      _heapify(i) {
        var arr = this._arr;
        var l = 2 * i;
        var r = l + 1;
        var largest = i;
        if (l < arr.length) {
          largest = arr[l].priority < arr[largest].priority ? l : largest;
          if (r < arr.length) {
            largest = arr[r].priority < arr[largest].priority ? r : largest;
          }
          if (largest !== i) {
            this._swap(i, largest);
            this._heapify(largest);
          }
        }
      }
      _decrease(index4) {
        var arr = this._arr;
        var priority = arr[index4].priority;
        var parent;
        while (index4 !== 0) {
          parent = index4 >> 1;
          if (arr[parent].priority < priority) {
            break;
          }
          this._swap(index4, parent);
          index4 = parent;
        }
      }
      _swap(i, j) {
        var arr = this._arr;
        var keyIndices = this._keyIndices;
        var origArrI = arr[i];
        var origArrJ = arr[j];
        arr[i] = origArrJ;
        arr[j] = origArrI;
        keyIndices[origArrJ.key] = i;
        keyIndices[origArrI.key] = j;
      }
    };
    module.exports = PriorityQueue;
  }
});

// node_modules/@dagrejs/graphlib/lib/alg/dijkstra.js
var require_dijkstra = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/alg/dijkstra.js"(exports, module) {
    var PriorityQueue = require_priority_queue();
    module.exports = dijkstra;
    var DEFAULT_WEIGHT_FUNC = () => 1;
    function dijkstra(g, source, weightFn, edgeFn) {
      return runDijkstra(
        g,
        String(source),
        weightFn || DEFAULT_WEIGHT_FUNC,
        edgeFn || function(v) {
          return g.outEdges(v);
        }
      );
    }
    function runDijkstra(g, source, weightFn, edgeFn) {
      var results = {};
      var pq = new PriorityQueue();
      var v, vEntry;
      var updateNeighbors = function(edge) {
        var w = edge.v !== v ? edge.v : edge.w;
        var wEntry = results[w];
        var weight = weightFn(edge);
        var distance = vEntry.distance + weight;
        if (weight < 0) {
          throw new Error("dijkstra does not allow negative edge weights. Bad edge: " + edge + " Weight: " + weight);
        }
        if (distance < wEntry.distance) {
          wEntry.distance = distance;
          wEntry.predecessor = v;
          pq.decrease(w, distance);
        }
      };
      g.nodes().forEach(function(v2) {
        var distance = v2 === source ? 0 : Number.POSITIVE_INFINITY;
        results[v2] = { distance };
        pq.add(v2, distance);
      });
      while (pq.size() > 0) {
        v = pq.removeMin();
        vEntry = results[v];
        if (vEntry.distance === Number.POSITIVE_INFINITY) {
          break;
        }
        edgeFn(v).forEach(updateNeighbors);
      }
      return results;
    }
  }
});

// node_modules/@dagrejs/graphlib/lib/alg/dijkstra-all.js
var require_dijkstra_all = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/alg/dijkstra-all.js"(exports, module) {
    var dijkstra = require_dijkstra();
    module.exports = dijkstraAll;
    function dijkstraAll(g, weightFunc, edgeFunc) {
      return g.nodes().reduce(function(acc, v) {
        acc[v] = dijkstra(g, v, weightFunc, edgeFunc);
        return acc;
      }, {});
    }
  }
});

// node_modules/@dagrejs/graphlib/lib/alg/tarjan.js
var require_tarjan = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/alg/tarjan.js"(exports, module) {
    module.exports = tarjan;
    function tarjan(g) {
      var index4 = 0;
      var stack = [];
      var visited = {};
      var results = [];
      function dfs(v) {
        var entry = visited[v] = {
          onStack: true,
          lowlink: index4,
          index: index4++
        };
        stack.push(v);
        g.successors(v).forEach(function(w2) {
          if (!Object.hasOwn(visited, w2)) {
            dfs(w2);
            entry.lowlink = Math.min(entry.lowlink, visited[w2].lowlink);
          } else if (visited[w2].onStack) {
            entry.lowlink = Math.min(entry.lowlink, visited[w2].index);
          }
        });
        if (entry.lowlink === entry.index) {
          var cmpt = [];
          var w;
          do {
            w = stack.pop();
            visited[w].onStack = false;
            cmpt.push(w);
          } while (v !== w);
          results.push(cmpt);
        }
      }
      g.nodes().forEach(function(v) {
        if (!Object.hasOwn(visited, v)) {
          dfs(v);
        }
      });
      return results;
    }
  }
});

// node_modules/@dagrejs/graphlib/lib/alg/find-cycles.js
var require_find_cycles = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/alg/find-cycles.js"(exports, module) {
    var tarjan = require_tarjan();
    module.exports = findCycles;
    function findCycles(g) {
      return tarjan(g).filter(function(cmpt) {
        return cmpt.length > 1 || cmpt.length === 1 && g.hasEdge(cmpt[0], cmpt[0]);
      });
    }
  }
});

// node_modules/@dagrejs/graphlib/lib/alg/floyd-warshall.js
var require_floyd_warshall = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/alg/floyd-warshall.js"(exports, module) {
    module.exports = floydWarshall;
    var DEFAULT_WEIGHT_FUNC = () => 1;
    function floydWarshall(g, weightFn, edgeFn) {
      return runFloydWarshall(
        g,
        weightFn || DEFAULT_WEIGHT_FUNC,
        edgeFn || function(v) {
          return g.outEdges(v);
        }
      );
    }
    function runFloydWarshall(g, weightFn, edgeFn) {
      var results = {};
      var nodes2 = g.nodes();
      nodes2.forEach(function(v) {
        results[v] = {};
        results[v][v] = { distance: 0 };
        nodes2.forEach(function(w) {
          if (v !== w) {
            results[v][w] = { distance: Number.POSITIVE_INFINITY };
          }
        });
        edgeFn(v).forEach(function(edge) {
          var w = edge.v === v ? edge.w : edge.v;
          var d = weightFn(edge);
          results[v][w] = { distance: d, predecessor: v };
        });
      });
      nodes2.forEach(function(k) {
        var rowK = results[k];
        nodes2.forEach(function(i) {
          var rowI = results[i];
          nodes2.forEach(function(j) {
            var ik = rowI[k];
            var kj = rowK[j];
            var ij = rowI[j];
            var altDistance = ik.distance + kj.distance;
            if (altDistance < ij.distance) {
              ij.distance = altDistance;
              ij.predecessor = kj.predecessor;
            }
          });
        });
      });
      return results;
    }
  }
});

// node_modules/@dagrejs/graphlib/lib/alg/topsort.js
var require_topsort = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/alg/topsort.js"(exports, module) {
    function topsort(g) {
      var visited = {};
      var stack = {};
      var results = [];
      function visit(node) {
        if (Object.hasOwn(stack, node)) {
          throw new CycleException();
        }
        if (!Object.hasOwn(visited, node)) {
          stack[node] = true;
          visited[node] = true;
          g.predecessors(node).forEach(visit);
          delete stack[node];
          results.push(node);
        }
      }
      g.sinks().forEach(visit);
      if (Object.keys(visited).length !== g.nodeCount()) {
        throw new CycleException();
      }
      return results;
    }
    var CycleException = class extends Error {
      constructor() {
        super(...arguments);
      }
    };
    module.exports = topsort;
    topsort.CycleException = CycleException;
  }
});

// node_modules/@dagrejs/graphlib/lib/alg/is-acyclic.js
var require_is_acyclic = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/alg/is-acyclic.js"(exports, module) {
    var topsort = require_topsort();
    module.exports = isAcyclic;
    function isAcyclic(g) {
      try {
        topsort(g);
      } catch (e) {
        if (e instanceof topsort.CycleException) {
          return false;
        }
        throw e;
      }
      return true;
    }
  }
});

// node_modules/@dagrejs/graphlib/lib/alg/dfs.js
var require_dfs = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/alg/dfs.js"(exports, module) {
    module.exports = dfs;
    function dfs(g, vs, order2) {
      if (!Array.isArray(vs)) {
        vs = [vs];
      }
      var navigation = g.isDirected() ? (v) => g.successors(v) : (v) => g.neighbors(v);
      var orderFunc = order2 === "post" ? postOrderDfs : preOrderDfs;
      var acc = [];
      var visited = {};
      vs.forEach((v) => {
        if (!g.hasNode(v)) {
          throw new Error("Graph does not have node: " + v);
        }
        orderFunc(v, navigation, visited, acc);
      });
      return acc;
    }
    function postOrderDfs(v, navigation, visited, acc) {
      var stack = [[v, false]];
      while (stack.length > 0) {
        var curr = stack.pop();
        if (curr[1]) {
          acc.push(curr[0]);
        } else {
          if (!Object.hasOwn(visited, curr[0])) {
            visited[curr[0]] = true;
            stack.push([curr[0], true]);
            forEachRight(navigation(curr[0]), (w) => stack.push([w, false]));
          }
        }
      }
    }
    function preOrderDfs(v, navigation, visited, acc) {
      var stack = [v];
      while (stack.length > 0) {
        var curr = stack.pop();
        if (!Object.hasOwn(visited, curr)) {
          visited[curr] = true;
          acc.push(curr);
          forEachRight(navigation(curr), (w) => stack.push(w));
        }
      }
    }
    function forEachRight(array4, iteratee) {
      var length3 = array4.length;
      while (length3--) {
        iteratee(array4[length3], length3, array4);
      }
      return array4;
    }
  }
});

// node_modules/@dagrejs/graphlib/lib/alg/postorder.js
var require_postorder = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/alg/postorder.js"(exports, module) {
    var dfs = require_dfs();
    module.exports = postorder;
    function postorder(g, vs) {
      return dfs(g, vs, "post");
    }
  }
});

// node_modules/@dagrejs/graphlib/lib/alg/preorder.js
var require_preorder = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/alg/preorder.js"(exports, module) {
    var dfs = require_dfs();
    module.exports = preorder;
    function preorder(g, vs) {
      return dfs(g, vs, "pre");
    }
  }
});

// node_modules/@dagrejs/graphlib/lib/alg/prim.js
var require_prim = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/alg/prim.js"(exports, module) {
    var Graph4 = require_graph();
    var PriorityQueue = require_priority_queue();
    module.exports = prim;
    function prim(g, weightFunc) {
      var result = new Graph4();
      var parents = {};
      var pq = new PriorityQueue();
      var v;
      function updateNeighbors(edge) {
        var w = edge.v === v ? edge.w : edge.v;
        var pri = pq.priority(w);
        if (pri !== void 0) {
          var edgeWeight = weightFunc(edge);
          if (edgeWeight < pri) {
            parents[w] = v;
            pq.decrease(w, edgeWeight);
          }
        }
      }
      if (g.nodeCount() === 0) {
        return result;
      }
      g.nodes().forEach(function(v2) {
        pq.add(v2, Number.POSITIVE_INFINITY);
        result.setNode(v2);
      });
      pq.decrease(g.nodes()[0], 0);
      var init2 = false;
      while (pq.size() > 0) {
        v = pq.removeMin();
        if (Object.hasOwn(parents, v)) {
          result.setEdge(v, parents[v]);
        } else if (init2) {
          throw new Error("Input graph is not connected: " + g);
        } else {
          init2 = true;
        }
        g.nodeEdges(v).forEach(updateNeighbors);
      }
      return result;
    }
  }
});

// node_modules/@dagrejs/graphlib/lib/alg/index.js
var require_alg = __commonJS({
  "node_modules/@dagrejs/graphlib/lib/alg/index.js"(exports, module) {
    module.exports = {
      components: require_components(),
      dijkstra: require_dijkstra(),
      dijkstraAll: require_dijkstra_all(),
      findCycles: require_find_cycles(),
      floydWarshall: require_floyd_warshall(),
      isAcyclic: require_is_acyclic(),
      postorder: require_postorder(),
      preorder: require_preorder(),
      prim: require_prim(),
      tarjan: require_tarjan(),
      topsort: require_topsort()
    };
  }
});

// node_modules/@dagrejs/graphlib/index.js
var require_graphlib = __commonJS({
  "node_modules/@dagrejs/graphlib/index.js"(exports, module) {
    var lib = require_lib();
    module.exports = {
      Graph: lib.Graph,
      json: require_json(),
      alg: require_alg(),
      version: lib.version
    };
  }
});

// build/dev/javascript/prelude.mjs
var CustomType = class {
  withFields(fields) {
    let properties = Object.keys(this).map(
      (label) => label in fields ? fields[label] : this[label]
    );
    return new this.constructor(...properties);
  }
};
var List = class {
  static fromArray(array4, tail) {
    let t = tail || new Empty();
    for (let i = array4.length - 1; i >= 0; --i) {
      t = new NonEmpty(array4[i], t);
    }
    return t;
  }
  [Symbol.iterator]() {
    return new ListIterator(this);
  }
  toArray() {
    return [...this];
  }
  // @internal
  atLeastLength(desired) {
    let current = this;
    while (desired-- > 0 && current) current = current.tail;
    return current !== void 0;
  }
  // @internal
  hasLength(desired) {
    let current = this;
    while (desired-- > 0 && current) current = current.tail;
    return desired === -1 && current instanceof Empty;
  }
  // @internal
  countLength() {
    let current = this;
    let length3 = 0;
    while (current) {
      current = current.tail;
      length3++;
    }
    return length3 - 1;
  }
};
function prepend(element4, tail) {
  return new NonEmpty(element4, tail);
}
function toList(elements, tail) {
  return List.fromArray(elements, tail);
}
var ListIterator = class {
  #current;
  constructor(current) {
    this.#current = current;
  }
  next() {
    if (this.#current instanceof Empty) {
      return { done: true };
    } else {
      let { head, tail } = this.#current;
      this.#current = tail;
      return { value: head, done: false };
    }
  }
};
var Empty = class extends List {
};
var NonEmpty = class extends List {
  constructor(head, tail) {
    super();
    this.head = head;
    this.tail = tail;
  }
};
var BitArray = class {
  /**
   * The size in bits of this bit array's data.
   *
   * @type {number}
   */
  bitSize;
  /**
   * The size in bytes of this bit array's data. If this bit array doesn't store
   * a whole number of bytes then this value is rounded up.
   *
   * @type {number}
   */
  byteSize;
  /**
   * The number of unused high bits in the first byte of this bit array's
   * buffer prior to the start of its data. The value of any unused high bits is
   * undefined.
   *
   * The bit offset will be in the range 0-7.
   *
   * @type {number}
   */
  bitOffset;
  /**
   * The raw bytes that hold this bit array's data.
   *
   * If `bitOffset` is not zero then there are unused high bits in the first
   * byte of this buffer.
   *
   * If `bitOffset + bitSize` is not a multiple of 8 then there are unused low
   * bits in the last byte of this buffer.
   *
   * @type {Uint8Array}
   */
  rawBuffer;
  /**
   * Constructs a new bit array from a `Uint8Array`, an optional size in
   * bits, and an optional bit offset.
   *
   * If no bit size is specified it is taken as `buffer.length * 8`, i.e. all
   * bytes in the buffer make up the new bit array's data.
   *
   * If no bit offset is specified it defaults to zero, i.e. there are no unused
   * high bits in the first byte of the buffer.
   *
   * @param {Uint8Array} buffer
   * @param {number} [bitSize]
   * @param {number} [bitOffset]
   */
  constructor(buffer, bitSize, bitOffset) {
    if (!(buffer instanceof Uint8Array)) {
      throw globalThis.Error(
        "BitArray can only be constructed from a Uint8Array"
      );
    }
    this.bitSize = bitSize ?? buffer.length * 8;
    this.byteSize = Math.trunc((this.bitSize + 7) / 8);
    this.bitOffset = bitOffset ?? 0;
    if (this.bitSize < 0) {
      throw globalThis.Error(`BitArray bit size is invalid: ${this.bitSize}`);
    }
    if (this.bitOffset < 0 || this.bitOffset > 7) {
      throw globalThis.Error(
        `BitArray bit offset is invalid: ${this.bitOffset}`
      );
    }
    if (buffer.length !== Math.trunc((this.bitOffset + this.bitSize + 7) / 8)) {
      throw globalThis.Error("BitArray buffer length is invalid");
    }
    this.rawBuffer = buffer;
  }
  /**
   * Returns a specific byte in this bit array. If the byte index is out of
   * range then `undefined` is returned.
   *
   * When returning the final byte of a bit array with a bit size that's not a
   * multiple of 8, the content of the unused low bits are undefined.
   *
   * @param {number} index
   * @returns {number | undefined}
   */
  byteAt(index4) {
    if (index4 < 0 || index4 >= this.byteSize) {
      return void 0;
    }
    return bitArrayByteAt(this.rawBuffer, this.bitOffset, index4);
  }
  /** @internal */
  equals(other) {
    if (this.bitSize !== other.bitSize) {
      return false;
    }
    const wholeByteCount = Math.trunc(this.bitSize / 8);
    if (this.bitOffset === 0 && other.bitOffset === 0) {
      for (let i = 0; i < wholeByteCount; i++) {
        if (this.rawBuffer[i] !== other.rawBuffer[i]) {
          return false;
        }
      }
      const trailingBitsCount = this.bitSize % 8;
      if (trailingBitsCount) {
        const unusedLowBitCount = 8 - trailingBitsCount;
        if (this.rawBuffer[wholeByteCount] >> unusedLowBitCount !== other.rawBuffer[wholeByteCount] >> unusedLowBitCount) {
          return false;
        }
      }
    } else {
      for (let i = 0; i < wholeByteCount; i++) {
        const a2 = bitArrayByteAt(this.rawBuffer, this.bitOffset, i);
        const b = bitArrayByteAt(other.rawBuffer, other.bitOffset, i);
        if (a2 !== b) {
          return false;
        }
      }
      const trailingBitsCount = this.bitSize % 8;
      if (trailingBitsCount) {
        const a2 = bitArrayByteAt(
          this.rawBuffer,
          this.bitOffset,
          wholeByteCount
        );
        const b = bitArrayByteAt(
          other.rawBuffer,
          other.bitOffset,
          wholeByteCount
        );
        const unusedLowBitCount = 8 - trailingBitsCount;
        if (a2 >> unusedLowBitCount !== b >> unusedLowBitCount) {
          return false;
        }
      }
    }
    return true;
  }
  /**
   * Returns this bit array's internal buffer.
   *
   * @deprecated Use `BitArray.byteAt()` or `BitArray.rawBuffer` instead.
   *
   * @returns {Uint8Array}
   */
  get buffer() {
    bitArrayPrintDeprecationWarning(
      "buffer",
      "Use BitArray.byteAt() or BitArray.rawBuffer instead"
    );
    if (this.bitOffset !== 0 || this.bitSize % 8 !== 0) {
      throw new globalThis.Error(
        "BitArray.buffer does not support unaligned bit arrays"
      );
    }
    return this.rawBuffer;
  }
  /**
   * Returns the length in bytes of this bit array's internal buffer.
   *
   * @deprecated Use `BitArray.bitSize` or `BitArray.byteSize` instead.
   *
   * @returns {number}
   */
  get length() {
    bitArrayPrintDeprecationWarning(
      "length",
      "Use BitArray.bitSize or BitArray.byteSize instead"
    );
    if (this.bitOffset !== 0 || this.bitSize % 8 !== 0) {
      throw new globalThis.Error(
        "BitArray.length does not support unaligned bit arrays"
      );
    }
    return this.rawBuffer.length;
  }
};
function bitArrayByteAt(buffer, bitOffset, index4) {
  if (bitOffset === 0) {
    return buffer[index4] ?? 0;
  } else {
    const a2 = buffer[index4] << bitOffset & 255;
    const b = buffer[index4 + 1] >> 8 - bitOffset;
    return a2 | b;
  }
}
var UtfCodepoint = class {
  constructor(value) {
    this.value = value;
  }
};
var isBitArrayDeprecationMessagePrinted = {};
function bitArrayPrintDeprecationWarning(name, message) {
  if (isBitArrayDeprecationMessagePrinted[name]) {
    return;
  }
  console.warn(
    `Deprecated BitArray.${name} property used in JavaScript FFI code. ${message}.`
  );
  isBitArrayDeprecationMessagePrinted[name] = true;
}
var Result = class _Result extends CustomType {
  // @internal
  static isResult(data) {
    return data instanceof _Result;
  }
};
var Ok = class extends Result {
  constructor(value) {
    super();
    this[0] = value;
  }
  // @internal
  isOk() {
    return true;
  }
};
var Error2 = class extends Result {
  constructor(detail) {
    super();
    this[0] = detail;
  }
  // @internal
  isOk() {
    return false;
  }
};
function isEqual(x, y) {
  let values3 = [x, y];
  while (values3.length) {
    let a2 = values3.pop();
    let b = values3.pop();
    if (a2 === b) continue;
    if (!isObject(a2) || !isObject(b)) return false;
    let unequal = !structurallyCompatibleObjects(a2, b) || unequalDates(a2, b) || unequalBuffers(a2, b) || unequalArrays(a2, b) || unequalMaps(a2, b) || unequalSets(a2, b) || unequalRegExps(a2, b);
    if (unequal) return false;
    const proto = Object.getPrototypeOf(a2);
    if (proto !== null && typeof proto.equals === "function") {
      try {
        if (a2.equals(b)) continue;
        else return false;
      } catch {
      }
    }
    let [keys2, get4] = getters(a2);
    const ka = keys2(a2);
    const kb = keys2(b);
    if (ka.length !== kb.length) return false;
    for (let k of ka) {
      values3.push(get4(a2, k), get4(b, k));
    }
  }
  return true;
}
function getters(object4) {
  if (object4 instanceof Map) {
    return [(x) => x.keys(), (x, y) => x.get(y)];
  } else {
    let extra = object4 instanceof globalThis.Error ? ["message"] : [];
    return [(x) => [...extra, ...Object.keys(x)], (x, y) => x[y]];
  }
}
function unequalDates(a2, b) {
  return a2 instanceof Date && (a2 > b || a2 < b);
}
function unequalBuffers(a2, b) {
  return !(a2 instanceof BitArray) && a2.buffer instanceof ArrayBuffer && a2.BYTES_PER_ELEMENT && !(a2.byteLength === b.byteLength && a2.every((n, i) => n === b[i]));
}
function unequalArrays(a2, b) {
  return Array.isArray(a2) && a2.length !== b.length;
}
function unequalMaps(a2, b) {
  return a2 instanceof Map && a2.size !== b.size;
}
function unequalSets(a2, b) {
  return a2 instanceof Set && (a2.size != b.size || [...a2].some((e) => !b.has(e)));
}
function unequalRegExps(a2, b) {
  return a2 instanceof RegExp && (a2.source !== b.source || a2.flags !== b.flags);
}
function isObject(a2) {
  return typeof a2 === "object" && a2 !== null;
}
function structurallyCompatibleObjects(a2, b) {
  if (typeof a2 !== "object" && typeof b !== "object" && (!a2 || !b))
    return false;
  let nonstructural = [Promise, WeakSet, WeakMap, Function];
  if (nonstructural.some((c) => a2 instanceof c)) return false;
  return a2.constructor === b.constructor;
}
function divideFloat(a2, b) {
  if (b === 0) {
    return 0;
  } else {
    return a2 / b;
  }
}
function makeError(variant, file, module, line, fn, message, extra) {
  let error = new globalThis.Error(message);
  error.gleam_error = variant;
  error.file = file;
  error.module = module;
  error.line = line;
  error.function = fn;
  error.fn = fn;
  for (let k in extra) error[k] = extra[k];
  return error;
}

// build/dev/javascript/gleam_stdlib/gleam/option.mjs
var Some = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var None = class extends CustomType {
};
function then$(option, fun) {
  if (option instanceof Some) {
    let x = option[0];
    return fun(x);
  } else {
    return option;
  }
}

// build/dev/javascript/gleam_stdlib/dict.mjs
var referenceMap = /* @__PURE__ */ new WeakMap();
var tempDataView = /* @__PURE__ */ new DataView(
  /* @__PURE__ */ new ArrayBuffer(8)
);
var referenceUID = 0;
function hashByReference(o) {
  const known = referenceMap.get(o);
  if (known !== void 0) {
    return known;
  }
  const hash = referenceUID++;
  if (referenceUID === 2147483647) {
    referenceUID = 0;
  }
  referenceMap.set(o, hash);
  return hash;
}
function hashMerge(a2, b) {
  return a2 ^ b + 2654435769 + (a2 << 6) + (a2 >> 2) | 0;
}
function hashString(s) {
  let hash = 0;
  const len = s.length;
  for (let i = 0; i < len; i++) {
    hash = Math.imul(31, hash) + s.charCodeAt(i) | 0;
  }
  return hash;
}
function hashNumber(n) {
  tempDataView.setFloat64(0, n);
  const i = tempDataView.getInt32(0);
  const j = tempDataView.getInt32(4);
  return Math.imul(73244475, i >> 16 ^ i) ^ j;
}
function hashBigInt(n) {
  return hashString(n.toString());
}
function hashObject(o) {
  const proto = Object.getPrototypeOf(o);
  if (proto !== null && typeof proto.hashCode === "function") {
    try {
      const code2 = o.hashCode(o);
      if (typeof code2 === "number") {
        return code2;
      }
    } catch {
    }
  }
  if (o instanceof Promise || o instanceof WeakSet || o instanceof WeakMap) {
    return hashByReference(o);
  }
  if (o instanceof Date) {
    return hashNumber(o.getTime());
  }
  let h = 0;
  if (o instanceof ArrayBuffer) {
    o = new Uint8Array(o);
  }
  if (Array.isArray(o) || o instanceof Uint8Array) {
    for (let i = 0; i < o.length; i++) {
      h = Math.imul(31, h) + getHash(o[i]) | 0;
    }
  } else if (o instanceof Set) {
    o.forEach((v) => {
      h = h + getHash(v) | 0;
    });
  } else if (o instanceof Map) {
    o.forEach((v, k) => {
      h = h + hashMerge(getHash(v), getHash(k)) | 0;
    });
  } else {
    const keys2 = Object.keys(o);
    for (let i = 0; i < keys2.length; i++) {
      const k = keys2[i];
      const v = o[k];
      h = h + hashMerge(getHash(v), hashString(k)) | 0;
    }
  }
  return h;
}
function getHash(u) {
  if (u === null) return 1108378658;
  if (u === void 0) return 1108378659;
  if (u === true) return 1108378657;
  if (u === false) return 1108378656;
  switch (typeof u) {
    case "number":
      return hashNumber(u);
    case "string":
      return hashString(u);
    case "bigint":
      return hashBigInt(u);
    case "object":
      return hashObject(u);
    case "symbol":
      return hashByReference(u);
    case "function":
      return hashByReference(u);
    default:
      return 0;
  }
}
var SHIFT = 5;
var BUCKET_SIZE = Math.pow(2, SHIFT);
var MASK = BUCKET_SIZE - 1;
var MAX_INDEX_NODE = BUCKET_SIZE / 2;
var MIN_ARRAY_NODE = BUCKET_SIZE / 4;
var ENTRY = 0;
var ARRAY_NODE = 1;
var INDEX_NODE = 2;
var COLLISION_NODE = 3;
var EMPTY = {
  type: INDEX_NODE,
  bitmap: 0,
  array: []
};
function mask(hash, shift) {
  return hash >>> shift & MASK;
}
function bitpos(hash, shift) {
  return 1 << mask(hash, shift);
}
function bitcount(x) {
  x -= x >> 1 & 1431655765;
  x = (x & 858993459) + (x >> 2 & 858993459);
  x = x + (x >> 4) & 252645135;
  x += x >> 8;
  x += x >> 16;
  return x & 127;
}
function index(bitmap, bit) {
  return bitcount(bitmap & bit - 1);
}
function cloneAndSet(arr, at, val) {
  const len = arr.length;
  const out = new Array(len);
  for (let i = 0; i < len; ++i) {
    out[i] = arr[i];
  }
  out[at] = val;
  return out;
}
function spliceIn(arr, at, val) {
  const len = arr.length;
  const out = new Array(len + 1);
  let i = 0;
  let g = 0;
  while (i < at) {
    out[g++] = arr[i++];
  }
  out[g++] = val;
  while (i < len) {
    out[g++] = arr[i++];
  }
  return out;
}
function spliceOut(arr, at) {
  const len = arr.length;
  const out = new Array(len - 1);
  let i = 0;
  let g = 0;
  while (i < at) {
    out[g++] = arr[i++];
  }
  ++i;
  while (i < len) {
    out[g++] = arr[i++];
  }
  return out;
}
function createNode(shift, key1, val1, key2hash, key2, val2) {
  const key1hash = getHash(key1);
  if (key1hash === key2hash) {
    return {
      type: COLLISION_NODE,
      hash: key1hash,
      array: [
        { type: ENTRY, k: key1, v: val1 },
        { type: ENTRY, k: key2, v: val2 }
      ]
    };
  }
  const addedLeaf = { val: false };
  return assoc(
    assocIndex(EMPTY, shift, key1hash, key1, val1, addedLeaf),
    shift,
    key2hash,
    key2,
    val2,
    addedLeaf
  );
}
function assoc(root3, shift, hash, key, val, addedLeaf) {
  switch (root3.type) {
    case ARRAY_NODE:
      return assocArray(root3, shift, hash, key, val, addedLeaf);
    case INDEX_NODE:
      return assocIndex(root3, shift, hash, key, val, addedLeaf);
    case COLLISION_NODE:
      return assocCollision(root3, shift, hash, key, val, addedLeaf);
  }
}
function assocArray(root3, shift, hash, key, val, addedLeaf) {
  const idx = mask(hash, shift);
  const node = root3.array[idx];
  if (node === void 0) {
    addedLeaf.val = true;
    return {
      type: ARRAY_NODE,
      size: root3.size + 1,
      array: cloneAndSet(root3.array, idx, { type: ENTRY, k: key, v: val })
    };
  }
  if (node.type === ENTRY) {
    if (isEqual(key, node.k)) {
      if (val === node.v) {
        return root3;
      }
      return {
        type: ARRAY_NODE,
        size: root3.size,
        array: cloneAndSet(root3.array, idx, {
          type: ENTRY,
          k: key,
          v: val
        })
      };
    }
    addedLeaf.val = true;
    return {
      type: ARRAY_NODE,
      size: root3.size,
      array: cloneAndSet(
        root3.array,
        idx,
        createNode(shift + SHIFT, node.k, node.v, hash, key, val)
      )
    };
  }
  const n = assoc(node, shift + SHIFT, hash, key, val, addedLeaf);
  if (n === node) {
    return root3;
  }
  return {
    type: ARRAY_NODE,
    size: root3.size,
    array: cloneAndSet(root3.array, idx, n)
  };
}
function assocIndex(root3, shift, hash, key, val, addedLeaf) {
  const bit = bitpos(hash, shift);
  const idx = index(root3.bitmap, bit);
  if ((root3.bitmap & bit) !== 0) {
    const node = root3.array[idx];
    if (node.type !== ENTRY) {
      const n = assoc(node, shift + SHIFT, hash, key, val, addedLeaf);
      if (n === node) {
        return root3;
      }
      return {
        type: INDEX_NODE,
        bitmap: root3.bitmap,
        array: cloneAndSet(root3.array, idx, n)
      };
    }
    const nodeKey = node.k;
    if (isEqual(key, nodeKey)) {
      if (val === node.v) {
        return root3;
      }
      return {
        type: INDEX_NODE,
        bitmap: root3.bitmap,
        array: cloneAndSet(root3.array, idx, {
          type: ENTRY,
          k: key,
          v: val
        })
      };
    }
    addedLeaf.val = true;
    return {
      type: INDEX_NODE,
      bitmap: root3.bitmap,
      array: cloneAndSet(
        root3.array,
        idx,
        createNode(shift + SHIFT, nodeKey, node.v, hash, key, val)
      )
    };
  } else {
    const n = root3.array.length;
    if (n >= MAX_INDEX_NODE) {
      const nodes2 = new Array(32);
      const jdx = mask(hash, shift);
      nodes2[jdx] = assocIndex(EMPTY, shift + SHIFT, hash, key, val, addedLeaf);
      let j = 0;
      let bitmap = root3.bitmap;
      for (let i = 0; i < 32; i++) {
        if ((bitmap & 1) !== 0) {
          const node = root3.array[j++];
          nodes2[i] = node;
        }
        bitmap = bitmap >>> 1;
      }
      return {
        type: ARRAY_NODE,
        size: n + 1,
        array: nodes2
      };
    } else {
      const newArray = spliceIn(root3.array, idx, {
        type: ENTRY,
        k: key,
        v: val
      });
      addedLeaf.val = true;
      return {
        type: INDEX_NODE,
        bitmap: root3.bitmap | bit,
        array: newArray
      };
    }
  }
}
function assocCollision(root3, shift, hash, key, val, addedLeaf) {
  if (hash === root3.hash) {
    const idx = collisionIndexOf(root3, key);
    if (idx !== -1) {
      const entry = root3.array[idx];
      if (entry.v === val) {
        return root3;
      }
      return {
        type: COLLISION_NODE,
        hash,
        array: cloneAndSet(root3.array, idx, { type: ENTRY, k: key, v: val })
      };
    }
    const size4 = root3.array.length;
    addedLeaf.val = true;
    return {
      type: COLLISION_NODE,
      hash,
      array: cloneAndSet(root3.array, size4, { type: ENTRY, k: key, v: val })
    };
  }
  return assoc(
    {
      type: INDEX_NODE,
      bitmap: bitpos(root3.hash, shift),
      array: [root3]
    },
    shift,
    hash,
    key,
    val,
    addedLeaf
  );
}
function collisionIndexOf(root3, key) {
  const size4 = root3.array.length;
  for (let i = 0; i < size4; i++) {
    if (isEqual(key, root3.array[i].k)) {
      return i;
    }
  }
  return -1;
}
function find(root3, shift, hash, key) {
  switch (root3.type) {
    case ARRAY_NODE:
      return findArray(root3, shift, hash, key);
    case INDEX_NODE:
      return findIndex(root3, shift, hash, key);
    case COLLISION_NODE:
      return findCollision(root3, key);
  }
}
function findArray(root3, shift, hash, key) {
  const idx = mask(hash, shift);
  const node = root3.array[idx];
  if (node === void 0) {
    return void 0;
  }
  if (node.type !== ENTRY) {
    return find(node, shift + SHIFT, hash, key);
  }
  if (isEqual(key, node.k)) {
    return node;
  }
  return void 0;
}
function findIndex(root3, shift, hash, key) {
  const bit = bitpos(hash, shift);
  if ((root3.bitmap & bit) === 0) {
    return void 0;
  }
  const idx = index(root3.bitmap, bit);
  const node = root3.array[idx];
  if (node.type !== ENTRY) {
    return find(node, shift + SHIFT, hash, key);
  }
  if (isEqual(key, node.k)) {
    return node;
  }
  return void 0;
}
function findCollision(root3, key) {
  const idx = collisionIndexOf(root3, key);
  if (idx < 0) {
    return void 0;
  }
  return root3.array[idx];
}
function without(root3, shift, hash, key) {
  switch (root3.type) {
    case ARRAY_NODE:
      return withoutArray(root3, shift, hash, key);
    case INDEX_NODE:
      return withoutIndex(root3, shift, hash, key);
    case COLLISION_NODE:
      return withoutCollision(root3, key);
  }
}
function withoutArray(root3, shift, hash, key) {
  const idx = mask(hash, shift);
  const node = root3.array[idx];
  if (node === void 0) {
    return root3;
  }
  let n = void 0;
  if (node.type === ENTRY) {
    if (!isEqual(node.k, key)) {
      return root3;
    }
  } else {
    n = without(node, shift + SHIFT, hash, key);
    if (n === node) {
      return root3;
    }
  }
  if (n === void 0) {
    if (root3.size <= MIN_ARRAY_NODE) {
      const arr = root3.array;
      const out = new Array(root3.size - 1);
      let i = 0;
      let j = 0;
      let bitmap = 0;
      while (i < idx) {
        const nv = arr[i];
        if (nv !== void 0) {
          out[j] = nv;
          bitmap |= 1 << i;
          ++j;
        }
        ++i;
      }
      ++i;
      while (i < arr.length) {
        const nv = arr[i];
        if (nv !== void 0) {
          out[j] = nv;
          bitmap |= 1 << i;
          ++j;
        }
        ++i;
      }
      return {
        type: INDEX_NODE,
        bitmap,
        array: out
      };
    }
    return {
      type: ARRAY_NODE,
      size: root3.size - 1,
      array: cloneAndSet(root3.array, idx, n)
    };
  }
  return {
    type: ARRAY_NODE,
    size: root3.size,
    array: cloneAndSet(root3.array, idx, n)
  };
}
function withoutIndex(root3, shift, hash, key) {
  const bit = bitpos(hash, shift);
  if ((root3.bitmap & bit) === 0) {
    return root3;
  }
  const idx = index(root3.bitmap, bit);
  const node = root3.array[idx];
  if (node.type !== ENTRY) {
    const n = without(node, shift + SHIFT, hash, key);
    if (n === node) {
      return root3;
    }
    if (n !== void 0) {
      return {
        type: INDEX_NODE,
        bitmap: root3.bitmap,
        array: cloneAndSet(root3.array, idx, n)
      };
    }
    if (root3.bitmap === bit) {
      return void 0;
    }
    return {
      type: INDEX_NODE,
      bitmap: root3.bitmap ^ bit,
      array: spliceOut(root3.array, idx)
    };
  }
  if (isEqual(key, node.k)) {
    if (root3.bitmap === bit) {
      return void 0;
    }
    return {
      type: INDEX_NODE,
      bitmap: root3.bitmap ^ bit,
      array: spliceOut(root3.array, idx)
    };
  }
  return root3;
}
function withoutCollision(root3, key) {
  const idx = collisionIndexOf(root3, key);
  if (idx < 0) {
    return root3;
  }
  if (root3.array.length === 1) {
    return void 0;
  }
  return {
    type: COLLISION_NODE,
    hash: root3.hash,
    array: spliceOut(root3.array, idx)
  };
}
function forEach(root3, fn) {
  if (root3 === void 0) {
    return;
  }
  const items = root3.array;
  const size4 = items.length;
  for (let i = 0; i < size4; i++) {
    const item = items[i];
    if (item === void 0) {
      continue;
    }
    if (item.type === ENTRY) {
      fn(item.v, item.k);
      continue;
    }
    forEach(item, fn);
  }
}
var Dict = class _Dict {
  /**
   * @template V
   * @param {Record<string,V>} o
   * @returns {Dict<string,V>}
   */
  static fromObject(o) {
    const keys2 = Object.keys(o);
    let m = _Dict.new();
    for (let i = 0; i < keys2.length; i++) {
      const k = keys2[i];
      m = m.set(k, o[k]);
    }
    return m;
  }
  /**
   * @template K,V
   * @param {Map<K,V>} o
   * @returns {Dict<K,V>}
   */
  static fromMap(o) {
    let m = _Dict.new();
    o.forEach((v, k) => {
      m = m.set(k, v);
    });
    return m;
  }
  static new() {
    return new _Dict(void 0, 0);
  }
  /**
   * @param {undefined | Node<K,V>} root
   * @param {number} size
   */
  constructor(root3, size4) {
    this.root = root3;
    this.size = size4;
  }
  /**
   * @template NotFound
   * @param {K} key
   * @param {NotFound} notFound
   * @returns {NotFound | V}
   */
  get(key, notFound) {
    if (this.root === void 0) {
      return notFound;
    }
    const found = find(this.root, 0, getHash(key), key);
    if (found === void 0) {
      return notFound;
    }
    return found.v;
  }
  /**
   * @param {K} key
   * @param {V} val
   * @returns {Dict<K,V>}
   */
  set(key, val) {
    const addedLeaf = { val: false };
    const root3 = this.root === void 0 ? EMPTY : this.root;
    const newRoot = assoc(root3, 0, getHash(key), key, val, addedLeaf);
    if (newRoot === this.root) {
      return this;
    }
    return new _Dict(newRoot, addedLeaf.val ? this.size + 1 : this.size);
  }
  /**
   * @param {K} key
   * @returns {Dict<K,V>}
   */
  delete(key) {
    if (this.root === void 0) {
      return this;
    }
    const newRoot = without(this.root, 0, getHash(key), key);
    if (newRoot === this.root) {
      return this;
    }
    if (newRoot === void 0) {
      return _Dict.new();
    }
    return new _Dict(newRoot, this.size - 1);
  }
  /**
   * @param {K} key
   * @returns {boolean}
   */
  has(key) {
    if (this.root === void 0) {
      return false;
    }
    return find(this.root, 0, getHash(key), key) !== void 0;
  }
  /**
   * @returns {[K,V][]}
   */
  entries() {
    if (this.root === void 0) {
      return [];
    }
    const result = [];
    this.forEach((v, k) => result.push([k, v]));
    return result;
  }
  /**
   *
   * @param {(val:V,key:K)=>void} fn
   */
  forEach(fn) {
    forEach(this.root, fn);
  }
  hashCode() {
    let h = 0;
    this.forEach((v, k) => {
      h = h + hashMerge(getHash(v), getHash(k)) | 0;
    });
    return h;
  }
  /**
   * @param {unknown} o
   * @returns {boolean}
   */
  equals(o) {
    if (!(o instanceof _Dict) || this.size !== o.size) {
      return false;
    }
    try {
      this.forEach((v, k) => {
        if (!isEqual(o.get(k, !v), v)) {
          throw unequalDictSymbol;
        }
      });
      return true;
    } catch (e) {
      if (e === unequalDictSymbol) {
        return false;
      }
      throw e;
    }
  }
};
var unequalDictSymbol = /* @__PURE__ */ Symbol();

// build/dev/javascript/gleam_stdlib/gleam/order.mjs
var Lt = class extends CustomType {
};
var Eq = class extends CustomType {
};
var Gt = class extends CustomType {
};

// build/dev/javascript/gleam_stdlib/gleam/float.mjs
function negate(x) {
  return -1 * x;
}
function round2(x) {
  let $ = x >= 0;
  if ($) {
    return round(x);
  } else {
    return 0 - round(negate(x));
  }
}
function divide(a2, b) {
  if (b === 0) {
    return new Error2(void 0);
  } else {
    let b$1 = b;
    return new Ok(divideFloat(a2, b$1));
  }
}

// build/dev/javascript/gleam_stdlib/gleam/int.mjs
function compare(a2, b) {
  let $ = a2 === b;
  if ($) {
    return new Eq();
  } else {
    let $1 = a2 < b;
    if ($1) {
      return new Lt();
    } else {
      return new Gt();
    }
  }
}
function min(a2, b) {
  let $ = a2 < b;
  if ($) {
    return a2;
  } else {
    return b;
  }
}
function max(a2, b) {
  let $ = a2 > b;
  if ($) {
    return a2;
  } else {
    return b;
  }
}

// build/dev/javascript/gleam_stdlib/gleam/string_tree.mjs
function append(tree, second2) {
  return add(tree, identity(second2));
}
function join(trees, sep) {
  let _pipe = trees;
  let _pipe$1 = intersperse(_pipe, identity(sep));
  return concat(_pipe$1);
}

// build/dev/javascript/gleam_stdlib/gleam/string.mjs
function replace(string5, pattern, substitute) {
  let _pipe = string5;
  let _pipe$1 = identity(_pipe);
  let _pipe$2 = string_replace(_pipe$1, pattern, substitute);
  return identity(_pipe$2);
}
function compare2(a2, b) {
  let $ = a2 === b;
  if ($) {
    return new Eq();
  } else {
    let $1 = less_than(a2, b);
    if ($1) {
      return new Lt();
    } else {
      return new Gt();
    }
  }
}
function concat_loop(loop$strings, loop$accumulator) {
  while (true) {
    let strings = loop$strings;
    let accumulator = loop$accumulator;
    if (strings instanceof Empty) {
      return accumulator;
    } else {
      let string5 = strings.head;
      let strings$1 = strings.tail;
      loop$strings = strings$1;
      loop$accumulator = accumulator + string5;
    }
  }
}
function concat2(strings) {
  return concat_loop(strings, "");
}
function inspect2(term) {
  let _pipe = inspect(term);
  return identity(_pipe);
}

// build/dev/javascript/gleam_stdlib/gleam/dynamic/decode.mjs
var DecodeError = class extends CustomType {
  constructor(expected, found, path) {
    super();
    this.expected = expected;
    this.found = found;
    this.path = path;
  }
};
var Decoder = class extends CustomType {
  constructor(function$) {
    super();
    this.function = function$;
  }
};
function run(data, decoder2) {
  let $ = decoder2.function(data);
  let maybe_invalid_data;
  let errors;
  maybe_invalid_data = $[0];
  errors = $[1];
  if (errors instanceof Empty) {
    return new Ok(maybe_invalid_data);
  } else {
    return new Error2(errors);
  }
}
function success(data) {
  return new Decoder((_) => {
    return [data, toList([])];
  });
}
function map2(decoder2, transformer) {
  return new Decoder(
    (d) => {
      let $ = decoder2.function(d);
      let data;
      let errors;
      data = $[0];
      errors = $[1];
      return [transformer(data), errors];
    }
  );
}
function run_decoders(loop$data, loop$failure, loop$decoders) {
  while (true) {
    let data = loop$data;
    let failure2 = loop$failure;
    let decoders = loop$decoders;
    if (decoders instanceof Empty) {
      return failure2;
    } else {
      let decoder2 = decoders.head;
      let decoders$1 = decoders.tail;
      let $ = decoder2.function(data);
      let layer;
      let errors;
      layer = $;
      errors = $[1];
      if (errors instanceof Empty) {
        return layer;
      } else {
        loop$data = data;
        loop$failure = failure2;
        loop$decoders = decoders$1;
      }
    }
  }
}
function one_of(first3, alternatives) {
  return new Decoder(
    (dynamic_data) => {
      let $ = first3.function(dynamic_data);
      let layer;
      let errors;
      layer = $;
      errors = $[1];
      if (errors instanceof Empty) {
        return layer;
      } else {
        return run_decoders(dynamic_data, layer, alternatives);
      }
    }
  );
}
function run_dynamic_function(data, name, f) {
  let $ = f(data);
  if ($ instanceof Ok) {
    let data$1 = $[0];
    return [data$1, toList([])];
  } else {
    let zero = $[0];
    return [
      zero,
      toList([new DecodeError(name, classify_dynamic(data), toList([]))])
    ];
  }
}
function decode_int(data) {
  return run_dynamic_function(data, "Int", int);
}
var int2 = /* @__PURE__ */ new Decoder(decode_int);
function decode_string(data) {
  return run_dynamic_function(data, "String", string);
}
var string2 = /* @__PURE__ */ new Decoder(decode_string);
function push_path(layer, path) {
  let decoder2 = one_of(
    string2,
    toList([
      (() => {
        let _pipe = int2;
        return map2(_pipe, to_string);
      })()
    ])
  );
  let path$1 = map(
    path,
    (key) => {
      let key$1 = identity(key);
      let $ = run(key$1, decoder2);
      if ($ instanceof Ok) {
        let key$2 = $[0];
        return key$2;
      } else {
        return "<" + classify_dynamic(key$1) + ">";
      }
    }
  );
  let errors = map(
    layer[1],
    (error) => {
      return new DecodeError(
        error.expected,
        error.found,
        append3(path$1, error.path)
      );
    }
  );
  return [layer[0], errors];
}
function index3(loop$path, loop$position, loop$inner, loop$data, loop$handle_miss) {
  while (true) {
    let path = loop$path;
    let position = loop$position;
    let inner = loop$inner;
    let data = loop$data;
    let handle_miss = loop$handle_miss;
    if (path instanceof Empty) {
      let _pipe = inner(data);
      return push_path(_pipe, reverse(position));
    } else {
      let key = path.head;
      let path$1 = path.tail;
      let $ = index2(data, key);
      if ($ instanceof Ok) {
        let $1 = $[0];
        if ($1 instanceof Some) {
          let data$1 = $1[0];
          loop$path = path$1;
          loop$position = prepend(key, position);
          loop$inner = inner;
          loop$data = data$1;
          loop$handle_miss = handle_miss;
        } else {
          return handle_miss(data, prepend(key, position));
        }
      } else {
        let kind = $[0];
        let $1 = inner(data);
        let default$2;
        default$2 = $1[0];
        let _pipe = [
          default$2,
          toList([new DecodeError(kind, classify_dynamic(data), toList([]))])
        ];
        return push_path(_pipe, reverse(position));
      }
    }
  }
}
function subfield(field_path, field_decoder, next2) {
  return new Decoder(
    (data) => {
      let $ = index3(
        field_path,
        toList([]),
        field_decoder.function,
        data,
        (data2, position) => {
          let $12 = field_decoder.function(data2);
          let default$2;
          default$2 = $12[0];
          let _pipe = [
            default$2,
            toList([new DecodeError("Field", "Nothing", toList([]))])
          ];
          return push_path(_pipe, reverse(position));
        }
      );
      let out;
      let errors1;
      out = $[0];
      errors1 = $[1];
      let $1 = next2(out).function(data);
      let out$1;
      let errors2;
      out$1 = $1[0];
      errors2 = $1[1];
      return [out$1, append3(errors1, errors2)];
    }
  );
}

// build/dev/javascript/gleam_stdlib/gleam_stdlib.mjs
var Nil = void 0;
var NOT_FOUND = {};
function identity(x) {
  return x;
}
function parse_int(value) {
  if (/^[-+]?(\d+)$/.test(value)) {
    return new Ok(parseInt(value));
  } else {
    return new Error2(Nil);
  }
}
function to_string(term) {
  return term.toString();
}
function string_replace(string5, target, substitute) {
  return string5.replaceAll(target, substitute);
}
function graphemes(string5) {
  const iterator = graphemes_iterator(string5);
  if (iterator) {
    return List.fromArray(Array.from(iterator).map((item) => item.segment));
  } else {
    return List.fromArray(string5.match(/./gsu));
  }
}
var segmenter = void 0;
function graphemes_iterator(string5) {
  if (globalThis.Intl && Intl.Segmenter) {
    segmenter ||= new Intl.Segmenter();
    return segmenter.segment(string5)[Symbol.iterator]();
  }
}
function less_than(a2, b) {
  return a2 < b;
}
function add(a2, b) {
  return a2 + b;
}
function concat(xs) {
  let result = "";
  for (const x of xs) {
    result = result + x;
  }
  return result;
}
function starts_with(haystack, needle) {
  return haystack.startsWith(needle);
}
var unicode_whitespaces = [
  " ",
  // Space
  "	",
  // Horizontal tab
  "\n",
  // Line feed
  "\v",
  // Vertical tab
  "\f",
  // Form feed
  "\r",
  // Carriage return
  "\x85",
  // Next line
  "\u2028",
  // Line separator
  "\u2029"
  // Paragraph separator
].join("");
var trim_start_regex = /* @__PURE__ */ new RegExp(
  `^[${unicode_whitespaces}]*`
);
var trim_end_regex = /* @__PURE__ */ new RegExp(`[${unicode_whitespaces}]*$`);
function round(float4) {
  return Math.round(float4);
}
function new_map() {
  return Dict.new();
}
function map_size(map7) {
  return map7.size;
}
function map_to_list(map7) {
  return List.fromArray(map7.entries());
}
function map_remove(key, map7) {
  return map7.delete(key);
}
function map_get(map7, key) {
  const value = map7.get(key, NOT_FOUND);
  if (value === NOT_FOUND) {
    return new Error2(Nil);
  }
  return new Ok(value);
}
function map_insert(key, value, map7) {
  return map7.set(key, value);
}
function classify_dynamic(data) {
  if (typeof data === "string") {
    return "String";
  } else if (typeof data === "boolean") {
    return "Bool";
  } else if (data instanceof Result) {
    return "Result";
  } else if (data instanceof List) {
    return "List";
  } else if (data instanceof BitArray) {
    return "BitArray";
  } else if (data instanceof Dict) {
    return "Dict";
  } else if (Number.isInteger(data)) {
    return "Int";
  } else if (Array.isArray(data)) {
    return `Array`;
  } else if (typeof data === "number") {
    return "Float";
  } else if (data === null) {
    return "Nil";
  } else if (data === void 0) {
    return "Nil";
  } else {
    const type = typeof data;
    return type.charAt(0).toUpperCase() + type.slice(1);
  }
}
function inspect(v) {
  return new Inspector().inspect(v);
}
function float_to_string(float4) {
  const string5 = float4.toString().replace("+", "");
  if (string5.indexOf(".") >= 0) {
    return string5;
  } else {
    const index4 = string5.indexOf("e");
    if (index4 >= 0) {
      return string5.slice(0, index4) + ".0" + string5.slice(index4);
    } else {
      return string5 + ".0";
    }
  }
}
var Inspector = class {
  #references = /* @__PURE__ */ new Set();
  inspect(v) {
    const t = typeof v;
    if (v === true) return "True";
    if (v === false) return "False";
    if (v === null) return "//js(null)";
    if (v === void 0) return "Nil";
    if (t === "string") return this.#string(v);
    if (t === "bigint" || Number.isInteger(v)) return v.toString();
    if (t === "number") return float_to_string(v);
    if (v instanceof UtfCodepoint) return this.#utfCodepoint(v);
    if (v instanceof BitArray) return this.#bit_array(v);
    if (v instanceof RegExp) return `//js(${v})`;
    if (v instanceof Date) return `//js(Date("${v.toISOString()}"))`;
    if (v instanceof globalThis.Error) return `//js(${v.toString()})`;
    if (v instanceof Function) {
      const args = [];
      for (const i of Array(v.length).keys())
        args.push(String.fromCharCode(i + 97));
      return `//fn(${args.join(", ")}) { ... }`;
    }
    if (this.#references.size === this.#references.add(v).size) {
      return "//js(circular reference)";
    }
    let printed;
    if (Array.isArray(v)) {
      printed = `#(${v.map((v2) => this.inspect(v2)).join(", ")})`;
    } else if (v instanceof List) {
      printed = this.#list(v);
    } else if (v instanceof CustomType) {
      printed = this.#customType(v);
    } else if (v instanceof Dict) {
      printed = this.#dict(v);
    } else if (v instanceof Set) {
      return `//js(Set(${[...v].map((v2) => this.inspect(v2)).join(", ")}))`;
    } else {
      printed = this.#object(v);
    }
    this.#references.delete(v);
    return printed;
  }
  #object(v) {
    const name = Object.getPrototypeOf(v)?.constructor?.name || "Object";
    const props = [];
    for (const k of Object.keys(v)) {
      props.push(`${this.inspect(k)}: ${this.inspect(v[k])}`);
    }
    const body = props.length ? " " + props.join(", ") + " " : "";
    const head = name === "Object" ? "" : name + " ";
    return `//js(${head}{${body}})`;
  }
  #dict(map7) {
    let body = "dict.from_list([";
    let first3 = true;
    map7.forEach((value, key) => {
      if (!first3) body = body + ", ";
      body = body + "#(" + this.inspect(key) + ", " + this.inspect(value) + ")";
      first3 = false;
    });
    return body + "])";
  }
  #customType(record) {
    const props = Object.keys(record).map((label) => {
      const value = this.inspect(record[label]);
      return isNaN(parseInt(label)) ? `${label}: ${value}` : value;
    }).join(", ");
    return props ? `${record.constructor.name}(${props})` : record.constructor.name;
  }
  #list(list4) {
    if (list4 instanceof Empty) {
      return "[]";
    }
    let char_out = 'charlist.from_string("';
    let list_out = "[";
    let current = list4;
    while (current instanceof NonEmpty) {
      let element4 = current.head;
      current = current.tail;
      if (list_out !== "[") {
        list_out += ", ";
      }
      list_out += this.inspect(element4);
      if (char_out) {
        if (Number.isInteger(element4) && element4 >= 32 && element4 <= 126) {
          char_out += String.fromCharCode(element4);
        } else {
          char_out = null;
        }
      }
    }
    if (char_out) {
      return char_out + '")';
    } else {
      return list_out + "]";
    }
  }
  #string(str) {
    let new_str = '"';
    for (let i = 0; i < str.length; i++) {
      const char = str[i];
      switch (char) {
        case "\n":
          new_str += "\\n";
          break;
        case "\r":
          new_str += "\\r";
          break;
        case "	":
          new_str += "\\t";
          break;
        case "\f":
          new_str += "\\f";
          break;
        case "\\":
          new_str += "\\\\";
          break;
        case '"':
          new_str += '\\"';
          break;
        default:
          if (char < " " || char > "~" && char < "\xA0") {
            new_str += "\\u{" + char.charCodeAt(0).toString(16).toUpperCase().padStart(4, "0") + "}";
          } else {
            new_str += char;
          }
      }
    }
    new_str += '"';
    return new_str;
  }
  #utfCodepoint(codepoint2) {
    return `//utfcodepoint(${String.fromCodePoint(codepoint2.value)})`;
  }
  #bit_array(bits) {
    if (bits.bitSize === 0) {
      return "<<>>";
    }
    let acc = "<<";
    for (let i = 0; i < bits.byteSize - 1; i++) {
      acc += bits.byteAt(i).toString();
      acc += ", ";
    }
    if (bits.byteSize * 8 === bits.bitSize) {
      acc += bits.byteAt(bits.byteSize - 1).toString();
    } else {
      const trailingBitsCount = bits.bitSize % 8;
      acc += bits.byteAt(bits.byteSize - 1) >> 8 - trailingBitsCount;
      acc += `:size(${trailingBitsCount})`;
    }
    acc += ">>";
    return acc;
  }
};
function index2(data, key) {
  if (data instanceof Dict || data instanceof WeakMap || data instanceof Map) {
    const token4 = {};
    const entry = data.get(key, token4);
    if (entry === token4) return new Ok(new None());
    return new Ok(new Some(entry));
  }
  const key_is_int = Number.isInteger(key);
  if (key_is_int && key >= 0 && key < 8 && data instanceof List) {
    let i = 0;
    for (const value of data) {
      if (i === key) return new Ok(new Some(value));
      i++;
    }
    return new Error2("Indexable");
  }
  if (key_is_int && Array.isArray(data) || data && typeof data === "object" || data && Object.getPrototypeOf(data) === Object.prototype) {
    if (key in data) return new Ok(new Some(data[key]));
    return new Ok(new None());
  }
  return new Error2(key_is_int ? "Indexable" : "Dict");
}
function int(data) {
  if (Number.isInteger(data)) return new Ok(data);
  return new Error2(0);
}
function string(data) {
  if (typeof data === "string") return new Ok(data);
  return new Error2("");
}

// build/dev/javascript/gleam_stdlib/gleam/dict.mjs
function do_has_key(key, dict3) {
  return !isEqual(map_get(dict3, key), new Error2(void 0));
}
function has_key(dict3, key) {
  return do_has_key(key, dict3);
}
function insert(dict3, key, value) {
  return map_insert(key, value, dict3);
}
function from_list_loop(loop$list, loop$initial) {
  while (true) {
    let list4 = loop$list;
    let initial = loop$initial;
    if (list4 instanceof Empty) {
      return initial;
    } else {
      let rest = list4.tail;
      let key = list4.head[0];
      let value = list4.head[1];
      loop$list = rest;
      loop$initial = insert(initial, key, value);
    }
  }
}
function from_list(list4) {
  return from_list_loop(list4, new_map());
}
function reverse_and_concat(loop$remaining, loop$accumulator) {
  while (true) {
    let remaining = loop$remaining;
    let accumulator = loop$accumulator;
    if (remaining instanceof Empty) {
      return accumulator;
    } else {
      let first3 = remaining.head;
      let rest = remaining.tail;
      loop$remaining = rest;
      loop$accumulator = prepend(first3, accumulator);
    }
  }
}
function do_keys_loop(loop$list, loop$acc) {
  while (true) {
    let list4 = loop$list;
    let acc = loop$acc;
    if (list4 instanceof Empty) {
      return reverse_and_concat(acc, toList([]));
    } else {
      let rest = list4.tail;
      let key = list4.head[0];
      loop$list = rest;
      loop$acc = prepend(key, acc);
    }
  }
}
function keys(dict3) {
  return do_keys_loop(map_to_list(dict3), toList([]));
}
function do_values_loop(loop$list, loop$acc) {
  while (true) {
    let list4 = loop$list;
    let acc = loop$acc;
    if (list4 instanceof Empty) {
      return reverse_and_concat(acc, toList([]));
    } else {
      let rest = list4.tail;
      let value = list4.head[1];
      loop$list = rest;
      loop$acc = prepend(value, acc);
    }
  }
}
function values(dict3) {
  let list_of_pairs = map_to_list(dict3);
  return do_values_loop(list_of_pairs, toList([]));
}
function delete$(dict3, key) {
  return map_remove(key, dict3);
}
function fold_loop(loop$list, loop$initial, loop$fun) {
  while (true) {
    let list4 = loop$list;
    let initial = loop$initial;
    let fun = loop$fun;
    if (list4 instanceof Empty) {
      return initial;
    } else {
      let rest = list4.tail;
      let k = list4.head[0];
      let v = list4.head[1];
      loop$list = rest;
      loop$initial = fun(initial, k, v);
      loop$fun = fun;
    }
  }
}
function fold(dict3, initial, fun) {
  return fold_loop(map_to_list(dict3), initial, fun);
}
function do_map_values(f, dict3) {
  let f$1 = (dict4, k, v) => {
    return insert(dict4, k, f(k, v));
  };
  return fold(dict3, new_map(), f$1);
}
function map_values(dict3, fun) {
  return do_map_values(fun, dict3);
}

// build/dev/javascript/gleam_stdlib/gleam/list.mjs
var Continue = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var Stop = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var Ascending = class extends CustomType {
};
var Descending = class extends CustomType {
};
function reverse_and_prepend(loop$prefix, loop$suffix) {
  while (true) {
    let prefix = loop$prefix;
    let suffix = loop$suffix;
    if (prefix instanceof Empty) {
      return suffix;
    } else {
      let first$1 = prefix.head;
      let rest$1 = prefix.tail;
      loop$prefix = rest$1;
      loop$suffix = prepend(first$1, suffix);
    }
  }
}
function reverse(list4) {
  return reverse_and_prepend(list4, toList([]));
}
function first(list4) {
  if (list4 instanceof Empty) {
    return new Error2(void 0);
  } else {
    let first$1 = list4.head;
    return new Ok(first$1);
  }
}
function filter_map_loop(loop$list, loop$fun, loop$acc) {
  while (true) {
    let list4 = loop$list;
    let fun = loop$fun;
    let acc = loop$acc;
    if (list4 instanceof Empty) {
      return reverse(acc);
    } else {
      let first$1 = list4.head;
      let rest$1 = list4.tail;
      let _block;
      let $ = fun(first$1);
      if ($ instanceof Ok) {
        let first$2 = $[0];
        _block = prepend(first$2, acc);
      } else {
        _block = acc;
      }
      let new_acc = _block;
      loop$list = rest$1;
      loop$fun = fun;
      loop$acc = new_acc;
    }
  }
}
function filter_map(list4, fun) {
  return filter_map_loop(list4, fun, toList([]));
}
function map_loop(loop$list, loop$fun, loop$acc) {
  while (true) {
    let list4 = loop$list;
    let fun = loop$fun;
    let acc = loop$acc;
    if (list4 instanceof Empty) {
      return reverse(acc);
    } else {
      let first$1 = list4.head;
      let rest$1 = list4.tail;
      loop$list = rest$1;
      loop$fun = fun;
      loop$acc = prepend(fun(first$1), acc);
    }
  }
}
function map(list4, fun) {
  return map_loop(list4, fun, toList([]));
}
function map_fold_loop(loop$list, loop$fun, loop$acc, loop$list_acc) {
  while (true) {
    let list4 = loop$list;
    let fun = loop$fun;
    let acc = loop$acc;
    let list_acc = loop$list_acc;
    if (list4 instanceof Empty) {
      return [acc, reverse(list_acc)];
    } else {
      let first$1 = list4.head;
      let rest$1 = list4.tail;
      let $ = fun(acc, first$1);
      let acc$1;
      let first$2;
      acc$1 = $[0];
      first$2 = $[1];
      loop$list = rest$1;
      loop$fun = fun;
      loop$acc = acc$1;
      loop$list_acc = prepend(first$2, list_acc);
    }
  }
}
function map_fold(list4, initial, fun) {
  return map_fold_loop(list4, fun, initial, toList([]));
}
function take_loop(loop$list, loop$n, loop$acc) {
  while (true) {
    let list4 = loop$list;
    let n = loop$n;
    let acc = loop$acc;
    let $ = n <= 0;
    if ($) {
      return reverse(acc);
    } else {
      if (list4 instanceof Empty) {
        return reverse(acc);
      } else {
        let first$1 = list4.head;
        let rest$1 = list4.tail;
        loop$list = rest$1;
        loop$n = n - 1;
        loop$acc = prepend(first$1, acc);
      }
    }
  }
}
function take(list4, n) {
  return take_loop(list4, n, toList([]));
}
function append_loop(loop$first, loop$second) {
  while (true) {
    let first3 = loop$first;
    let second2 = loop$second;
    if (first3 instanceof Empty) {
      return second2;
    } else {
      let first$1 = first3.head;
      let rest$1 = first3.tail;
      loop$first = rest$1;
      loop$second = prepend(first$1, second2);
    }
  }
}
function append3(first3, second2) {
  return append_loop(reverse(first3), second2);
}
function flatten_loop(loop$lists, loop$acc) {
  while (true) {
    let lists = loop$lists;
    let acc = loop$acc;
    if (lists instanceof Empty) {
      return reverse(acc);
    } else {
      let list4 = lists.head;
      let further_lists = lists.tail;
      loop$lists = further_lists;
      loop$acc = reverse_and_prepend(list4, acc);
    }
  }
}
function flatten(lists) {
  return flatten_loop(lists, toList([]));
}
function flat_map(list4, fun) {
  return flatten(map(list4, fun));
}
function fold2(loop$list, loop$initial, loop$fun) {
  while (true) {
    let list4 = loop$list;
    let initial = loop$initial;
    let fun = loop$fun;
    if (list4 instanceof Empty) {
      return initial;
    } else {
      let first$1 = list4.head;
      let rest$1 = list4.tail;
      loop$list = rest$1;
      loop$initial = fun(initial, first$1);
      loop$fun = fun;
    }
  }
}
function fold_right(list4, initial, fun) {
  if (list4 instanceof Empty) {
    return initial;
  } else {
    let first$1 = list4.head;
    let rest$1 = list4.tail;
    return fun(fold_right(rest$1, initial, fun), first$1);
  }
}
function fold_until(loop$list, loop$initial, loop$fun) {
  while (true) {
    let list4 = loop$list;
    let initial = loop$initial;
    let fun = loop$fun;
    if (list4 instanceof Empty) {
      return initial;
    } else {
      let first$1 = list4.head;
      let rest$1 = list4.tail;
      let $ = fun(initial, first$1);
      if ($ instanceof Continue) {
        let next_accumulator = $[0];
        loop$list = rest$1;
        loop$initial = next_accumulator;
        loop$fun = fun;
      } else {
        let b = $[0];
        return b;
      }
    }
  }
}
function zip_loop(loop$one, loop$other, loop$acc) {
  while (true) {
    let one = loop$one;
    let other = loop$other;
    let acc = loop$acc;
    if (other instanceof Empty) {
      return reverse(acc);
    } else if (one instanceof Empty) {
      return reverse(acc);
    } else {
      let first_other = other.head;
      let rest_other = other.tail;
      let first_one = one.head;
      let rest_one = one.tail;
      loop$one = rest_one;
      loop$other = rest_other;
      loop$acc = prepend([first_one, first_other], acc);
    }
  }
}
function zip(list4, other) {
  return zip_loop(list4, other, toList([]));
}
function intersperse_loop(loop$list, loop$separator, loop$acc) {
  while (true) {
    let list4 = loop$list;
    let separator = loop$separator;
    let acc = loop$acc;
    if (list4 instanceof Empty) {
      return reverse(acc);
    } else {
      let first$1 = list4.head;
      let rest$1 = list4.tail;
      loop$list = rest$1;
      loop$separator = separator;
      loop$acc = prepend(first$1, prepend(separator, acc));
    }
  }
}
function intersperse(list4, elem) {
  if (list4 instanceof Empty) {
    return list4;
  } else {
    let $ = list4.tail;
    if ($ instanceof Empty) {
      return list4;
    } else {
      let first$1 = list4.head;
      let rest$1 = $;
      return intersperse_loop(rest$1, elem, toList([first$1]));
    }
  }
}
function sequences(loop$list, loop$compare, loop$growing, loop$direction, loop$prev, loop$acc) {
  while (true) {
    let list4 = loop$list;
    let compare5 = loop$compare;
    let growing = loop$growing;
    let direction = loop$direction;
    let prev = loop$prev;
    let acc = loop$acc;
    let growing$1 = prepend(prev, growing);
    if (list4 instanceof Empty) {
      if (direction instanceof Ascending) {
        return prepend(reverse(growing$1), acc);
      } else {
        return prepend(growing$1, acc);
      }
    } else {
      let new$1 = list4.head;
      let rest$1 = list4.tail;
      let $ = compare5(prev, new$1);
      if (direction instanceof Ascending) {
        if ($ instanceof Lt) {
          loop$list = rest$1;
          loop$compare = compare5;
          loop$growing = growing$1;
          loop$direction = direction;
          loop$prev = new$1;
          loop$acc = acc;
        } else if ($ instanceof Eq) {
          loop$list = rest$1;
          loop$compare = compare5;
          loop$growing = growing$1;
          loop$direction = direction;
          loop$prev = new$1;
          loop$acc = acc;
        } else {
          let _block;
          if (direction instanceof Ascending) {
            _block = prepend(reverse(growing$1), acc);
          } else {
            _block = prepend(growing$1, acc);
          }
          let acc$1 = _block;
          if (rest$1 instanceof Empty) {
            return prepend(toList([new$1]), acc$1);
          } else {
            let next2 = rest$1.head;
            let rest$2 = rest$1.tail;
            let _block$1;
            let $1 = compare5(new$1, next2);
            if ($1 instanceof Lt) {
              _block$1 = new Ascending();
            } else if ($1 instanceof Eq) {
              _block$1 = new Ascending();
            } else {
              _block$1 = new Descending();
            }
            let direction$1 = _block$1;
            loop$list = rest$2;
            loop$compare = compare5;
            loop$growing = toList([new$1]);
            loop$direction = direction$1;
            loop$prev = next2;
            loop$acc = acc$1;
          }
        }
      } else if ($ instanceof Lt) {
        let _block;
        if (direction instanceof Ascending) {
          _block = prepend(reverse(growing$1), acc);
        } else {
          _block = prepend(growing$1, acc);
        }
        let acc$1 = _block;
        if (rest$1 instanceof Empty) {
          return prepend(toList([new$1]), acc$1);
        } else {
          let next2 = rest$1.head;
          let rest$2 = rest$1.tail;
          let _block$1;
          let $1 = compare5(new$1, next2);
          if ($1 instanceof Lt) {
            _block$1 = new Ascending();
          } else if ($1 instanceof Eq) {
            _block$1 = new Ascending();
          } else {
            _block$1 = new Descending();
          }
          let direction$1 = _block$1;
          loop$list = rest$2;
          loop$compare = compare5;
          loop$growing = toList([new$1]);
          loop$direction = direction$1;
          loop$prev = next2;
          loop$acc = acc$1;
        }
      } else if ($ instanceof Eq) {
        let _block;
        if (direction instanceof Ascending) {
          _block = prepend(reverse(growing$1), acc);
        } else {
          _block = prepend(growing$1, acc);
        }
        let acc$1 = _block;
        if (rest$1 instanceof Empty) {
          return prepend(toList([new$1]), acc$1);
        } else {
          let next2 = rest$1.head;
          let rest$2 = rest$1.tail;
          let _block$1;
          let $1 = compare5(new$1, next2);
          if ($1 instanceof Lt) {
            _block$1 = new Ascending();
          } else if ($1 instanceof Eq) {
            _block$1 = new Ascending();
          } else {
            _block$1 = new Descending();
          }
          let direction$1 = _block$1;
          loop$list = rest$2;
          loop$compare = compare5;
          loop$growing = toList([new$1]);
          loop$direction = direction$1;
          loop$prev = next2;
          loop$acc = acc$1;
        }
      } else {
        loop$list = rest$1;
        loop$compare = compare5;
        loop$growing = growing$1;
        loop$direction = direction;
        loop$prev = new$1;
        loop$acc = acc;
      }
    }
  }
}
function merge_ascendings(loop$list1, loop$list2, loop$compare, loop$acc) {
  while (true) {
    let list1 = loop$list1;
    let list22 = loop$list2;
    let compare5 = loop$compare;
    let acc = loop$acc;
    if (list1 instanceof Empty) {
      let list4 = list22;
      return reverse_and_prepend(list4, acc);
    } else if (list22 instanceof Empty) {
      let list4 = list1;
      return reverse_and_prepend(list4, acc);
    } else {
      let first1 = list1.head;
      let rest1 = list1.tail;
      let first22 = list22.head;
      let rest2 = list22.tail;
      let $ = compare5(first1, first22);
      if ($ instanceof Lt) {
        loop$list1 = rest1;
        loop$list2 = list22;
        loop$compare = compare5;
        loop$acc = prepend(first1, acc);
      } else if ($ instanceof Eq) {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare5;
        loop$acc = prepend(first22, acc);
      } else {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare5;
        loop$acc = prepend(first22, acc);
      }
    }
  }
}
function merge_ascending_pairs(loop$sequences, loop$compare, loop$acc) {
  while (true) {
    let sequences2 = loop$sequences;
    let compare5 = loop$compare;
    let acc = loop$acc;
    if (sequences2 instanceof Empty) {
      return reverse(acc);
    } else {
      let $ = sequences2.tail;
      if ($ instanceof Empty) {
        let sequence2 = sequences2.head;
        return reverse(prepend(reverse(sequence2), acc));
      } else {
        let ascending1 = sequences2.head;
        let ascending2 = $.head;
        let rest$1 = $.tail;
        let descending = merge_ascendings(
          ascending1,
          ascending2,
          compare5,
          toList([])
        );
        loop$sequences = rest$1;
        loop$compare = compare5;
        loop$acc = prepend(descending, acc);
      }
    }
  }
}
function merge_descendings(loop$list1, loop$list2, loop$compare, loop$acc) {
  while (true) {
    let list1 = loop$list1;
    let list22 = loop$list2;
    let compare5 = loop$compare;
    let acc = loop$acc;
    if (list1 instanceof Empty) {
      let list4 = list22;
      return reverse_and_prepend(list4, acc);
    } else if (list22 instanceof Empty) {
      let list4 = list1;
      return reverse_and_prepend(list4, acc);
    } else {
      let first1 = list1.head;
      let rest1 = list1.tail;
      let first22 = list22.head;
      let rest2 = list22.tail;
      let $ = compare5(first1, first22);
      if ($ instanceof Lt) {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare5;
        loop$acc = prepend(first22, acc);
      } else if ($ instanceof Eq) {
        loop$list1 = rest1;
        loop$list2 = list22;
        loop$compare = compare5;
        loop$acc = prepend(first1, acc);
      } else {
        loop$list1 = rest1;
        loop$list2 = list22;
        loop$compare = compare5;
        loop$acc = prepend(first1, acc);
      }
    }
  }
}
function merge_descending_pairs(loop$sequences, loop$compare, loop$acc) {
  while (true) {
    let sequences2 = loop$sequences;
    let compare5 = loop$compare;
    let acc = loop$acc;
    if (sequences2 instanceof Empty) {
      return reverse(acc);
    } else {
      let $ = sequences2.tail;
      if ($ instanceof Empty) {
        let sequence2 = sequences2.head;
        return reverse(prepend(reverse(sequence2), acc));
      } else {
        let descending1 = sequences2.head;
        let descending2 = $.head;
        let rest$1 = $.tail;
        let ascending = merge_descendings(
          descending1,
          descending2,
          compare5,
          toList([])
        );
        loop$sequences = rest$1;
        loop$compare = compare5;
        loop$acc = prepend(ascending, acc);
      }
    }
  }
}
function merge_all(loop$sequences, loop$direction, loop$compare) {
  while (true) {
    let sequences2 = loop$sequences;
    let direction = loop$direction;
    let compare5 = loop$compare;
    if (sequences2 instanceof Empty) {
      return sequences2;
    } else if (direction instanceof Ascending) {
      let $ = sequences2.tail;
      if ($ instanceof Empty) {
        let sequence2 = sequences2.head;
        return sequence2;
      } else {
        let sequences$1 = merge_ascending_pairs(sequences2, compare5, toList([]));
        loop$sequences = sequences$1;
        loop$direction = new Descending();
        loop$compare = compare5;
      }
    } else {
      let $ = sequences2.tail;
      if ($ instanceof Empty) {
        let sequence2 = sequences2.head;
        return reverse(sequence2);
      } else {
        let sequences$1 = merge_descending_pairs(sequences2, compare5, toList([]));
        loop$sequences = sequences$1;
        loop$direction = new Ascending();
        loop$compare = compare5;
      }
    }
  }
}
function sort(list4, compare5) {
  if (list4 instanceof Empty) {
    return list4;
  } else {
    let $ = list4.tail;
    if ($ instanceof Empty) {
      return list4;
    } else {
      let x = list4.head;
      let y = $.head;
      let rest$1 = $.tail;
      let _block;
      let $1 = compare5(x, y);
      if ($1 instanceof Lt) {
        _block = new Ascending();
      } else if ($1 instanceof Eq) {
        _block = new Ascending();
      } else {
        _block = new Descending();
      }
      let direction = _block;
      let sequences$1 = sequences(
        rest$1,
        compare5,
        toList([x]),
        direction,
        y,
        toList([])
      );
      return merge_all(sequences$1, new Ascending(), compare5);
    }
  }
}
function max_loop(loop$list, loop$compare, loop$max) {
  while (true) {
    let list4 = loop$list;
    let compare5 = loop$compare;
    let max4 = loop$max;
    if (list4 instanceof Empty) {
      return max4;
    } else {
      let first$1 = list4.head;
      let rest$1 = list4.tail;
      let $ = compare5(first$1, max4);
      if ($ instanceof Lt) {
        loop$list = rest$1;
        loop$compare = compare5;
        loop$max = max4;
      } else if ($ instanceof Eq) {
        loop$list = rest$1;
        loop$compare = compare5;
        loop$max = max4;
      } else {
        loop$list = rest$1;
        loop$compare = compare5;
        loop$max = first$1;
      }
    }
  }
}
function max2(list4, compare5) {
  if (list4 instanceof Empty) {
    return new Error2(void 0);
  } else {
    let first$1 = list4.head;
    let rest$1 = list4.tail;
    return new Ok(max_loop(rest$1, compare5, first$1));
  }
}

// build/dev/javascript/gleam_stdlib/gleam/result.mjs
function is_ok(result) {
  if (result instanceof Ok) {
    return true;
  } else {
    return false;
  }
}
function map3(result, fun) {
  if (result instanceof Ok) {
    let x = result[0];
    return new Ok(fun(x));
  } else {
    return result;
  }
}
function map_error(result, fun) {
  if (result instanceof Ok) {
    return result;
  } else {
    let error = result[0];
    return new Error2(fun(error));
  }
}
function try$(result, fun) {
  if (result instanceof Ok) {
    let x = result[0];
    return fun(x);
  } else {
    return result;
  }
}
function unwrap(result, default$2) {
  if (result instanceof Ok) {
    let v = result[0];
    return v;
  } else {
    return default$2;
  }
}
function unwrap_both(result) {
  if (result instanceof Ok) {
    let a2 = result[0];
    return a2;
  } else {
    let a2 = result[0];
    return a2;
  }
}

// build/dev/javascript/gleam_stdlib/gleam/bool.mjs
function guard(requirement, consequence, alternative) {
  if (requirement) {
    return consequence;
  } else {
    return alternative();
  }
}

// build/dev/javascript/gleam_stdlib/gleam/function.mjs
function identity2(x) {
  return x;
}

// build/dev/javascript/gleam_json/gleam_json_ffi.mjs
function identity3(x) {
  return x;
}

// build/dev/javascript/gleam_json/gleam/json.mjs
function string3(input) {
  return identity3(input);
}
function bool(input) {
  return identity3(input);
}

// build/dev/javascript/gleam_stdlib/gleam/set.mjs
var Set2 = class extends CustomType {
  constructor(dict3) {
    super();
    this.dict = dict3;
  }
};
function new$() {
  return new Set2(new_map());
}
function size(set) {
  return map_size(set.dict);
}
function contains(set, member) {
  let _pipe = set.dict;
  let _pipe$1 = map_get(_pipe, member);
  return is_ok(_pipe$1);
}
function delete$2(set, member) {
  return new Set2(delete$(set.dict, member));
}
function to_list(set) {
  return keys(set.dict);
}
function fold3(set, initial, reducer) {
  return fold(set.dict, initial, (a2, k, _) => {
    return reducer(a2, k);
  });
}
function drop(set, disallowed) {
  return fold2(disallowed, set, delete$2);
}
function order(first3, second2) {
  let $ = map_size(first3.dict) > map_size(second2.dict);
  if ($) {
    return [first3, second2];
  } else {
    return [second2, first3];
  }
}
function difference(first3, second2) {
  return drop(first3, to_list(second2));
}
var token = void 0;
function insert2(set, member) {
  return new Set2(insert(set.dict, member, token));
}
function from_list2(members) {
  let dict3 = fold2(
    members,
    new_map(),
    (m, k) => {
      return insert(m, k, token);
    }
  );
  return new Set2(dict3);
}
function union(first3, second2) {
  let $ = order(first3, second2);
  let larger;
  let smaller;
  larger = $[0];
  smaller = $[1];
  return fold3(smaller, larger, insert2);
}

// build/dev/javascript/lustre/lustre/internals/constants.ffi.mjs
var document = () => globalThis?.document;
var NAMESPACE_HTML = "http://www.w3.org/1999/xhtml";
var ELEMENT_NODE = 1;
var TEXT_NODE = 3;
var SUPPORTS_MOVE_BEFORE = !!globalThis.HTMLElement?.prototype?.moveBefore;

// build/dev/javascript/lustre/lustre/internals/constants.mjs
var empty_list = /* @__PURE__ */ toList([]);
var option_none = /* @__PURE__ */ new None();

// build/dev/javascript/lustre/lustre/vdom/vattr.ffi.mjs
var GT = /* @__PURE__ */ new Gt();
var LT = /* @__PURE__ */ new Lt();
var EQ = /* @__PURE__ */ new Eq();
function compare4(a2, b) {
  if (a2.name === b.name) {
    return EQ;
  } else if (a2.name < b.name) {
    return LT;
  } else {
    return GT;
  }
}

// build/dev/javascript/lustre/lustre/vdom/vattr.mjs
var Attribute = class extends CustomType {
  constructor(kind, name, value) {
    super();
    this.kind = kind;
    this.name = name;
    this.value = value;
  }
};
var Property = class extends CustomType {
  constructor(kind, name, value) {
    super();
    this.kind = kind;
    this.name = name;
    this.value = value;
  }
};
var Event2 = class extends CustomType {
  constructor(kind, name, handler, include, prevent_default, stop_propagation, immediate, debounce, throttle) {
    super();
    this.kind = kind;
    this.name = name;
    this.handler = handler;
    this.include = include;
    this.prevent_default = prevent_default;
    this.stop_propagation = stop_propagation;
    this.immediate = immediate;
    this.debounce = debounce;
    this.throttle = throttle;
  }
};
var Handler = class extends CustomType {
  constructor(prevent_default, stop_propagation, message) {
    super();
    this.prevent_default = prevent_default;
    this.stop_propagation = stop_propagation;
    this.message = message;
  }
};
var Never = class extends CustomType {
  constructor(kind) {
    super();
    this.kind = kind;
  }
};
function merge(loop$attributes, loop$merged) {
  while (true) {
    let attributes = loop$attributes;
    let merged = loop$merged;
    if (attributes instanceof Empty) {
      return merged;
    } else {
      let $ = attributes.head;
      if ($ instanceof Attribute) {
        let $1 = $.name;
        if ($1 === "") {
          let rest = attributes.tail;
          loop$attributes = rest;
          loop$merged = merged;
        } else if ($1 === "class") {
          let $2 = $.value;
          if ($2 === "") {
            let rest = attributes.tail;
            loop$attributes = rest;
            loop$merged = merged;
          } else {
            let $3 = attributes.tail;
            if ($3 instanceof Empty) {
              let attribute$1 = $;
              let rest = $3;
              loop$attributes = rest;
              loop$merged = prepend(attribute$1, merged);
            } else {
              let $4 = $3.head;
              if ($4 instanceof Attribute) {
                let $5 = $4.name;
                if ($5 === "class") {
                  let kind = $.kind;
                  let class1 = $2;
                  let rest = $3.tail;
                  let class2 = $4.value;
                  let value = class1 + " " + class2;
                  let attribute$1 = new Attribute(kind, "class", value);
                  loop$attributes = prepend(attribute$1, rest);
                  loop$merged = merged;
                } else {
                  let attribute$1 = $;
                  let rest = $3;
                  loop$attributes = rest;
                  loop$merged = prepend(attribute$1, merged);
                }
              } else {
                let attribute$1 = $;
                let rest = $3;
                loop$attributes = rest;
                loop$merged = prepend(attribute$1, merged);
              }
            }
          }
        } else if ($1 === "style") {
          let $2 = $.value;
          if ($2 === "") {
            let rest = attributes.tail;
            loop$attributes = rest;
            loop$merged = merged;
          } else {
            let $3 = attributes.tail;
            if ($3 instanceof Empty) {
              let attribute$1 = $;
              let rest = $3;
              loop$attributes = rest;
              loop$merged = prepend(attribute$1, merged);
            } else {
              let $4 = $3.head;
              if ($4 instanceof Attribute) {
                let $5 = $4.name;
                if ($5 === "style") {
                  let kind = $.kind;
                  let style1 = $2;
                  let rest = $3.tail;
                  let style22 = $4.value;
                  let value = style1 + ";" + style22;
                  let attribute$1 = new Attribute(kind, "style", value);
                  loop$attributes = prepend(attribute$1, rest);
                  loop$merged = merged;
                } else {
                  let attribute$1 = $;
                  let rest = $3;
                  loop$attributes = rest;
                  loop$merged = prepend(attribute$1, merged);
                }
              } else {
                let attribute$1 = $;
                let rest = $3;
                loop$attributes = rest;
                loop$merged = prepend(attribute$1, merged);
              }
            }
          }
        } else {
          let attribute$1 = $;
          let rest = attributes.tail;
          loop$attributes = rest;
          loop$merged = prepend(attribute$1, merged);
        }
      } else {
        let attribute$1 = $;
        let rest = attributes.tail;
        loop$attributes = rest;
        loop$merged = prepend(attribute$1, merged);
      }
    }
  }
}
function prepare(attributes) {
  if (attributes instanceof Empty) {
    return attributes;
  } else {
    let $ = attributes.tail;
    if ($ instanceof Empty) {
      return attributes;
    } else {
      let _pipe = attributes;
      let _pipe$1 = sort(_pipe, (a2, b) => {
        return compare4(b, a2);
      });
      return merge(_pipe$1, empty_list);
    }
  }
}
var attribute_kind = 0;
function attribute(name, value) {
  return new Attribute(attribute_kind, name, value);
}
var property_kind = 1;
function property(name, value) {
  return new Property(property_kind, name, value);
}
var event_kind = 2;
function event(name, handler, include, prevent_default, stop_propagation, immediate, debounce, throttle) {
  return new Event2(
    event_kind,
    name,
    handler,
    include,
    prevent_default,
    stop_propagation,
    immediate,
    debounce,
    throttle
  );
}
var never_kind = 0;
var never = /* @__PURE__ */ new Never(never_kind);
var always_kind = 2;

// build/dev/javascript/lustre/lustre/attribute.mjs
function attribute2(name, value) {
  return attribute(name, value);
}
function property2(name, value) {
  return property(name, value);
}
function boolean_attribute(name, value) {
  if (value) {
    return attribute2(name, "");
  } else {
    return property2(name, bool(false));
  }
}
function class$(name) {
  return attribute2("class", name);
}
function style(property3, value) {
  if (property3 === "") {
    return class$("");
  } else if (value === "") {
    return class$("");
  } else {
    return attribute2("style", property3 + ":" + value + ";");
  }
}
function autocomplete(value) {
  return attribute2("autocomplete", value);
}
function readonly(is_readonly) {
  return boolean_attribute("readonly", is_readonly);
}
function role(name) {
  return attribute2("role", name);
}

// build/dev/javascript/lustre/lustre/effect.mjs
var Effect = class extends CustomType {
  constructor(synchronous, before_paint2, after_paint) {
    super();
    this.synchronous = synchronous;
    this.before_paint = before_paint2;
    this.after_paint = after_paint;
  }
};
var empty = /* @__PURE__ */ new Effect(
  /* @__PURE__ */ toList([]),
  /* @__PURE__ */ toList([]),
  /* @__PURE__ */ toList([])
);
function none() {
  return empty;
}

// build/dev/javascript/lustre/lustre/internals/mutable_map.ffi.mjs
function empty2() {
  return null;
}
function get(map7, key) {
  const value = map7?.get(key);
  if (value != null) {
    return new Ok(value);
  } else {
    return new Error2(void 0);
  }
}
function has_key2(map7, key) {
  return map7 && map7.has(key);
}
function insert3(map7, key, value) {
  map7 ??= /* @__PURE__ */ new Map();
  map7.set(key, value);
  return map7;
}
function remove(map7, key) {
  map7?.delete(key);
  return map7;
}

// build/dev/javascript/lustre/lustre/vdom/path.mjs
var Root = class extends CustomType {
};
var Key = class extends CustomType {
  constructor(key, parent) {
    super();
    this.key = key;
    this.parent = parent;
  }
};
var Index = class extends CustomType {
  constructor(index4, parent) {
    super();
    this.index = index4;
    this.parent = parent;
  }
};
function do_matches(loop$path, loop$candidates) {
  while (true) {
    let path = loop$path;
    let candidates = loop$candidates;
    if (candidates instanceof Empty) {
      return false;
    } else {
      let candidate = candidates.head;
      let rest = candidates.tail;
      let $ = starts_with(path, candidate);
      if ($) {
        return $;
      } else {
        loop$path = path;
        loop$candidates = rest;
      }
    }
  }
}
function add2(parent, index4, key) {
  if (key === "") {
    return new Index(index4, parent);
  } else {
    return new Key(key, parent);
  }
}
var root2 = /* @__PURE__ */ new Root();
var separator_element = "	";
function do_to_string(loop$path, loop$acc) {
  while (true) {
    let path = loop$path;
    let acc = loop$acc;
    if (path instanceof Root) {
      if (acc instanceof Empty) {
        return "";
      } else {
        let segments = acc.tail;
        return concat2(segments);
      }
    } else if (path instanceof Key) {
      let key = path.key;
      let parent = path.parent;
      loop$path = parent;
      loop$acc = prepend(separator_element, prepend(key, acc));
    } else {
      let index4 = path.index;
      let parent = path.parent;
      loop$path = parent;
      loop$acc = prepend(
        separator_element,
        prepend(to_string(index4), acc)
      );
    }
  }
}
function to_string2(path) {
  return do_to_string(path, toList([]));
}
function matches(path, candidates) {
  if (candidates instanceof Empty) {
    return false;
  } else {
    return do_matches(to_string2(path), candidates);
  }
}
var separator_event = "\n";
function event2(path, event4) {
  return do_to_string(path, toList([separator_event, event4]));
}

// build/dev/javascript/lustre/lustre/vdom/vnode.mjs
var Fragment = class extends CustomType {
  constructor(kind, key, mapper, children, keyed_children) {
    super();
    this.kind = kind;
    this.key = key;
    this.mapper = mapper;
    this.children = children;
    this.keyed_children = keyed_children;
  }
};
var Element = class extends CustomType {
  constructor(kind, key, mapper, namespace, tag, attributes, children, keyed_children, self_closing, void$) {
    super();
    this.kind = kind;
    this.key = key;
    this.mapper = mapper;
    this.namespace = namespace;
    this.tag = tag;
    this.attributes = attributes;
    this.children = children;
    this.keyed_children = keyed_children;
    this.self_closing = self_closing;
    this.void = void$;
  }
};
var Text = class extends CustomType {
  constructor(kind, key, mapper, content) {
    super();
    this.kind = kind;
    this.key = key;
    this.mapper = mapper;
    this.content = content;
  }
};
var UnsafeInnerHtml = class extends CustomType {
  constructor(kind, key, mapper, namespace, tag, attributes, inner_html) {
    super();
    this.kind = kind;
    this.key = key;
    this.mapper = mapper;
    this.namespace = namespace;
    this.tag = tag;
    this.attributes = attributes;
    this.inner_html = inner_html;
  }
};
function is_void_element(tag, namespace) {
  if (namespace === "") {
    if (tag === "area") {
      return true;
    } else if (tag === "base") {
      return true;
    } else if (tag === "br") {
      return true;
    } else if (tag === "col") {
      return true;
    } else if (tag === "embed") {
      return true;
    } else if (tag === "hr") {
      return true;
    } else if (tag === "img") {
      return true;
    } else if (tag === "input") {
      return true;
    } else if (tag === "link") {
      return true;
    } else if (tag === "meta") {
      return true;
    } else if (tag === "param") {
      return true;
    } else if (tag === "source") {
      return true;
    } else if (tag === "track") {
      return true;
    } else if (tag === "wbr") {
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}
function to_keyed(key, node) {
  if (node instanceof Fragment) {
    return new Fragment(
      node.kind,
      key,
      node.mapper,
      node.children,
      node.keyed_children
    );
  } else if (node instanceof Element) {
    return new Element(
      node.kind,
      key,
      node.mapper,
      node.namespace,
      node.tag,
      node.attributes,
      node.children,
      node.keyed_children,
      node.self_closing,
      node.void
    );
  } else if (node instanceof Text) {
    return new Text(node.kind, key, node.mapper, node.content);
  } else {
    return new UnsafeInnerHtml(
      node.kind,
      key,
      node.mapper,
      node.namespace,
      node.tag,
      node.attributes,
      node.inner_html
    );
  }
}
var fragment_kind = 0;
function fragment(key, mapper, children, keyed_children) {
  return new Fragment(fragment_kind, key, mapper, children, keyed_children);
}
var element_kind = 1;
function element(key, mapper, namespace, tag, attributes, children, keyed_children, self_closing, void$) {
  return new Element(
    element_kind,
    key,
    mapper,
    namespace,
    tag,
    prepare(attributes),
    children,
    keyed_children,
    self_closing,
    void$ || is_void_element(tag, namespace)
  );
}
var text_kind = 2;
function text(key, mapper, content) {
  return new Text(text_kind, key, mapper, content);
}
var unsafe_inner_html_kind = 3;
function unsafe_inner_html(key, mapper, namespace, tag, attributes, inner_html) {
  return new UnsafeInnerHtml(
    unsafe_inner_html_kind,
    key,
    mapper,
    namespace,
    tag,
    prepare(attributes),
    inner_html
  );
}

// build/dev/javascript/lustre/lustre/internals/equals.ffi.mjs
var isReferenceEqual = (a2, b) => a2 === b;
var isEqual2 = (a2, b) => {
  if (a2 === b) {
    return true;
  }
  if (a2 == null || b == null) {
    return false;
  }
  const type = typeof a2;
  if (type !== typeof b) {
    return false;
  }
  if (type !== "object") {
    return false;
  }
  const ctor = a2.constructor;
  if (ctor !== b.constructor) {
    return false;
  }
  if (Array.isArray(a2)) {
    return areArraysEqual(a2, b);
  }
  return areObjectsEqual(a2, b);
};
var areArraysEqual = (a2, b) => {
  let index4 = a2.length;
  if (index4 !== b.length) {
    return false;
  }
  while (index4--) {
    if (!isEqual2(a2[index4], b[index4])) {
      return false;
    }
  }
  return true;
};
var areObjectsEqual = (a2, b) => {
  const properties = Object.keys(a2);
  let index4 = properties.length;
  if (Object.keys(b).length !== index4) {
    return false;
  }
  while (index4--) {
    const property3 = properties[index4];
    if (!Object.hasOwn(b, property3)) {
      return false;
    }
    if (!isEqual2(a2[property3], b[property3])) {
      return false;
    }
  }
  return true;
};

// build/dev/javascript/lustre/lustre/vdom/events.mjs
var Events = class extends CustomType {
  constructor(handlers, dispatched_paths, next_dispatched_paths) {
    super();
    this.handlers = handlers;
    this.dispatched_paths = dispatched_paths;
    this.next_dispatched_paths = next_dispatched_paths;
  }
};
function new$3() {
  return new Events(
    empty2(),
    empty_list,
    empty_list
  );
}
function tick(events) {
  return new Events(
    events.handlers,
    events.next_dispatched_paths,
    empty_list
  );
}
function do_remove_event(handlers, path, name) {
  return remove(handlers, event2(path, name));
}
function remove_event(events, path, name) {
  let handlers = do_remove_event(events.handlers, path, name);
  return new Events(
    handlers,
    events.dispatched_paths,
    events.next_dispatched_paths
  );
}
function remove_attributes(handlers, path, attributes) {
  return fold2(
    attributes,
    handlers,
    (events, attribute3) => {
      if (attribute3 instanceof Event2) {
        let name = attribute3.name;
        return do_remove_event(events, path, name);
      } else {
        return events;
      }
    }
  );
}
function handle(events, path, name, event4) {
  let next_dispatched_paths = prepend(path, events.next_dispatched_paths);
  let events$1 = new Events(
    events.handlers,
    events.dispatched_paths,
    next_dispatched_paths
  );
  let $ = get(
    events$1.handlers,
    path + separator_event + name
  );
  if ($ instanceof Ok) {
    let handler = $[0];
    return [events$1, run(event4, handler)];
  } else {
    return [events$1, new Error2(toList([]))];
  }
}
function has_dispatched_events(events, path) {
  return matches(path, events.dispatched_paths);
}
function do_add_event(handlers, mapper, path, name, handler) {
  return insert3(
    handlers,
    event2(path, name),
    map2(
      handler,
      (handler2) => {
        return new Handler(
          handler2.prevent_default,
          handler2.stop_propagation,
          identity2(mapper)(handler2.message)
        );
      }
    )
  );
}
function add_event(events, mapper, path, name, handler) {
  let handlers = do_add_event(events.handlers, mapper, path, name, handler);
  return new Events(
    handlers,
    events.dispatched_paths,
    events.next_dispatched_paths
  );
}
function add_attributes(handlers, mapper, path, attributes) {
  return fold2(
    attributes,
    handlers,
    (events, attribute3) => {
      if (attribute3 instanceof Event2) {
        let name = attribute3.name;
        let handler = attribute3.handler;
        return do_add_event(events, mapper, path, name, handler);
      } else {
        return events;
      }
    }
  );
}
function compose_mapper(mapper, child_mapper) {
  let $ = isReferenceEqual(mapper, identity2);
  let $1 = isReferenceEqual(child_mapper, identity2);
  if ($1) {
    return mapper;
  } else if ($) {
    return child_mapper;
  } else {
    return (msg) => {
      return mapper(child_mapper(msg));
    };
  }
}
function do_remove_children(loop$handlers, loop$path, loop$child_index, loop$children) {
  while (true) {
    let handlers = loop$handlers;
    let path = loop$path;
    let child_index = loop$child_index;
    let children = loop$children;
    if (children instanceof Empty) {
      return handlers;
    } else {
      let child = children.head;
      let rest = children.tail;
      let _pipe = handlers;
      let _pipe$1 = do_remove_child(_pipe, path, child_index, child);
      loop$handlers = _pipe$1;
      loop$path = path;
      loop$child_index = child_index + 1;
      loop$children = rest;
    }
  }
}
function do_remove_child(handlers, parent, child_index, child) {
  if (child instanceof Fragment) {
    let children = child.children;
    let path = add2(parent, child_index, child.key);
    return do_remove_children(handlers, path, 0, children);
  } else if (child instanceof Element) {
    let attributes = child.attributes;
    let children = child.children;
    let path = add2(parent, child_index, child.key);
    let _pipe = handlers;
    let _pipe$1 = remove_attributes(_pipe, path, attributes);
    return do_remove_children(_pipe$1, path, 0, children);
  } else if (child instanceof Text) {
    return handlers;
  } else {
    let attributes = child.attributes;
    let path = add2(parent, child_index, child.key);
    return remove_attributes(handlers, path, attributes);
  }
}
function remove_child(events, parent, child_index, child) {
  let handlers = do_remove_child(events.handlers, parent, child_index, child);
  return new Events(
    handlers,
    events.dispatched_paths,
    events.next_dispatched_paths
  );
}
function do_add_children(loop$handlers, loop$mapper, loop$path, loop$child_index, loop$children) {
  while (true) {
    let handlers = loop$handlers;
    let mapper = loop$mapper;
    let path = loop$path;
    let child_index = loop$child_index;
    let children = loop$children;
    if (children instanceof Empty) {
      return handlers;
    } else {
      let child = children.head;
      let rest = children.tail;
      let _pipe = handlers;
      let _pipe$1 = do_add_child(_pipe, mapper, path, child_index, child);
      loop$handlers = _pipe$1;
      loop$mapper = mapper;
      loop$path = path;
      loop$child_index = child_index + 1;
      loop$children = rest;
    }
  }
}
function do_add_child(handlers, mapper, parent, child_index, child) {
  if (child instanceof Fragment) {
    let children = child.children;
    let path = add2(parent, child_index, child.key);
    let composed_mapper = compose_mapper(mapper, child.mapper);
    return do_add_children(handlers, composed_mapper, path, 0, children);
  } else if (child instanceof Element) {
    let attributes = child.attributes;
    let children = child.children;
    let path = add2(parent, child_index, child.key);
    let composed_mapper = compose_mapper(mapper, child.mapper);
    let _pipe = handlers;
    let _pipe$1 = add_attributes(_pipe, composed_mapper, path, attributes);
    return do_add_children(_pipe$1, composed_mapper, path, 0, children);
  } else if (child instanceof Text) {
    return handlers;
  } else {
    let attributes = child.attributes;
    let path = add2(parent, child_index, child.key);
    let composed_mapper = compose_mapper(mapper, child.mapper);
    return add_attributes(handlers, composed_mapper, path, attributes);
  }
}
function add_child(events, mapper, parent, index4, child) {
  let handlers = do_add_child(events.handlers, mapper, parent, index4, child);
  return new Events(
    handlers,
    events.dispatched_paths,
    events.next_dispatched_paths
  );
}
function add_children(events, mapper, path, child_index, children) {
  let handlers = do_add_children(
    events.handlers,
    mapper,
    path,
    child_index,
    children
  );
  return new Events(
    handlers,
    events.dispatched_paths,
    events.next_dispatched_paths
  );
}

// build/dev/javascript/lustre/lustre/element.mjs
function element2(tag, attributes, children) {
  return element(
    "",
    identity2,
    "",
    tag,
    attributes,
    children,
    empty2(),
    false,
    false
  );
}
function text2(content) {
  return text("", identity2, content);
}
function none2() {
  return text("", identity2, "");
}
function fragment2(children) {
  return fragment("", identity2, children, empty2());
}
function unsafe_raw_html(namespace, tag, attributes, inner_html) {
  return unsafe_inner_html(
    "",
    identity2,
    namespace,
    tag,
    attributes,
    inner_html
  );
}

// build/dev/javascript/lustre/lustre/element/html.mjs
function style2(attrs, css) {
  return unsafe_raw_html("", "style", attrs, css);
}
function h1(attrs, children) {
  return element2("h1", attrs, children);
}
function div(attrs, children) {
  return element2("div", attrs, children);
}
function button(attrs, children) {
  return element2("button", attrs, children);
}
function textarea(attrs, content) {
  return element2(
    "textarea",
    prepend(property2("value", string3(content)), attrs),
    toList([text2(content)])
  );
}

// build/dev/javascript/lustre/lustre/vdom/patch.mjs
var Patch = class extends CustomType {
  constructor(index4, removed, changes, children) {
    super();
    this.index = index4;
    this.removed = removed;
    this.changes = changes;
    this.children = children;
  }
};
var ReplaceText = class extends CustomType {
  constructor(kind, content) {
    super();
    this.kind = kind;
    this.content = content;
  }
};
var ReplaceInnerHtml = class extends CustomType {
  constructor(kind, inner_html) {
    super();
    this.kind = kind;
    this.inner_html = inner_html;
  }
};
var Update = class extends CustomType {
  constructor(kind, added, removed) {
    super();
    this.kind = kind;
    this.added = added;
    this.removed = removed;
  }
};
var Move = class extends CustomType {
  constructor(kind, key, before) {
    super();
    this.kind = kind;
    this.key = key;
    this.before = before;
  }
};
var Replace = class extends CustomType {
  constructor(kind, index4, with$) {
    super();
    this.kind = kind;
    this.index = index4;
    this.with = with$;
  }
};
var Remove = class extends CustomType {
  constructor(kind, index4) {
    super();
    this.kind = kind;
    this.index = index4;
  }
};
var Insert = class extends CustomType {
  constructor(kind, children, before) {
    super();
    this.kind = kind;
    this.children = children;
    this.before = before;
  }
};
function new$5(index4, removed, changes, children) {
  return new Patch(index4, removed, changes, children);
}
var replace_text_kind = 0;
function replace_text(content) {
  return new ReplaceText(replace_text_kind, content);
}
var replace_inner_html_kind = 1;
function replace_inner_html(inner_html) {
  return new ReplaceInnerHtml(replace_inner_html_kind, inner_html);
}
var update_kind = 2;
function update(added, removed) {
  return new Update(update_kind, added, removed);
}
var move_kind = 3;
function move(key, before) {
  return new Move(move_kind, key, before);
}
var remove_kind = 4;
function remove2(index4) {
  return new Remove(remove_kind, index4);
}
var replace_kind = 5;
function replace2(index4, with$) {
  return new Replace(replace_kind, index4, with$);
}
var insert_kind = 6;
function insert4(children, before) {
  return new Insert(insert_kind, children, before);
}

// build/dev/javascript/lustre/lustre/vdom/diff.mjs
var Diff = class extends CustomType {
  constructor(patch, events) {
    super();
    this.patch = patch;
    this.events = events;
  }
};
var AttributeChange = class extends CustomType {
  constructor(added, removed, events) {
    super();
    this.added = added;
    this.removed = removed;
    this.events = events;
  }
};
function is_controlled(events, namespace, tag, path) {
  if (tag === "input" && namespace === "") {
    return has_dispatched_events(events, path);
  } else if (tag === "select" && namespace === "") {
    return has_dispatched_events(events, path);
  } else if (tag === "textarea" && namespace === "") {
    return has_dispatched_events(events, path);
  } else {
    return false;
  }
}
function diff_attributes(loop$controlled, loop$path, loop$mapper, loop$events, loop$old, loop$new, loop$added, loop$removed) {
  while (true) {
    let controlled = loop$controlled;
    let path = loop$path;
    let mapper = loop$mapper;
    let events = loop$events;
    let old = loop$old;
    let new$12 = loop$new;
    let added = loop$added;
    let removed = loop$removed;
    if (new$12 instanceof Empty) {
      if (old instanceof Empty) {
        return new AttributeChange(added, removed, events);
      } else {
        let $ = old.head;
        if ($ instanceof Event2) {
          let prev = $;
          let old$1 = old.tail;
          let name = $.name;
          let removed$1 = prepend(prev, removed);
          let events$1 = remove_event(events, path, name);
          loop$controlled = controlled;
          loop$path = path;
          loop$mapper = mapper;
          loop$events = events$1;
          loop$old = old$1;
          loop$new = new$12;
          loop$added = added;
          loop$removed = removed$1;
        } else {
          let prev = $;
          let old$1 = old.tail;
          let removed$1 = prepend(prev, removed);
          loop$controlled = controlled;
          loop$path = path;
          loop$mapper = mapper;
          loop$events = events;
          loop$old = old$1;
          loop$new = new$12;
          loop$added = added;
          loop$removed = removed$1;
        }
      }
    } else if (old instanceof Empty) {
      let $ = new$12.head;
      if ($ instanceof Event2) {
        let next2 = $;
        let new$1 = new$12.tail;
        let name = $.name;
        let handler = $.handler;
        let added$1 = prepend(next2, added);
        let events$1 = add_event(events, mapper, path, name, handler);
        loop$controlled = controlled;
        loop$path = path;
        loop$mapper = mapper;
        loop$events = events$1;
        loop$old = old;
        loop$new = new$1;
        loop$added = added$1;
        loop$removed = removed;
      } else {
        let next2 = $;
        let new$1 = new$12.tail;
        let added$1 = prepend(next2, added);
        loop$controlled = controlled;
        loop$path = path;
        loop$mapper = mapper;
        loop$events = events;
        loop$old = old;
        loop$new = new$1;
        loop$added = added$1;
        loop$removed = removed;
      }
    } else {
      let next2 = new$12.head;
      let remaining_new = new$12.tail;
      let prev = old.head;
      let remaining_old = old.tail;
      let $ = compare4(prev, next2);
      if ($ instanceof Lt) {
        if (prev instanceof Event2) {
          let name = prev.name;
          let removed$1 = prepend(prev, removed);
          let events$1 = remove_event(events, path, name);
          loop$controlled = controlled;
          loop$path = path;
          loop$mapper = mapper;
          loop$events = events$1;
          loop$old = remaining_old;
          loop$new = new$12;
          loop$added = added;
          loop$removed = removed$1;
        } else {
          let removed$1 = prepend(prev, removed);
          loop$controlled = controlled;
          loop$path = path;
          loop$mapper = mapper;
          loop$events = events;
          loop$old = remaining_old;
          loop$new = new$12;
          loop$added = added;
          loop$removed = removed$1;
        }
      } else if ($ instanceof Eq) {
        if (next2 instanceof Attribute) {
          if (prev instanceof Attribute) {
            let _block;
            let $1 = next2.name;
            if ($1 === "value") {
              _block = controlled || prev.value !== next2.value;
            } else if ($1 === "checked") {
              _block = controlled || prev.value !== next2.value;
            } else if ($1 === "selected") {
              _block = controlled || prev.value !== next2.value;
            } else {
              _block = prev.value !== next2.value;
            }
            let has_changes = _block;
            let _block$1;
            if (has_changes) {
              _block$1 = prepend(next2, added);
            } else {
              _block$1 = added;
            }
            let added$1 = _block$1;
            loop$controlled = controlled;
            loop$path = path;
            loop$mapper = mapper;
            loop$events = events;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed;
          } else if (prev instanceof Event2) {
            let name = prev.name;
            let added$1 = prepend(next2, added);
            let removed$1 = prepend(prev, removed);
            let events$1 = remove_event(events, path, name);
            loop$controlled = controlled;
            loop$path = path;
            loop$mapper = mapper;
            loop$events = events$1;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed$1;
          } else {
            let added$1 = prepend(next2, added);
            let removed$1 = prepend(prev, removed);
            loop$controlled = controlled;
            loop$path = path;
            loop$mapper = mapper;
            loop$events = events;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed$1;
          }
        } else if (next2 instanceof Property) {
          if (prev instanceof Property) {
            let _block;
            let $1 = next2.name;
            if ($1 === "scrollLeft") {
              _block = true;
            } else if ($1 === "scrollRight") {
              _block = true;
            } else if ($1 === "value") {
              _block = controlled || !isEqual2(
                prev.value,
                next2.value
              );
            } else if ($1 === "checked") {
              _block = controlled || !isEqual2(
                prev.value,
                next2.value
              );
            } else if ($1 === "selected") {
              _block = controlled || !isEqual2(
                prev.value,
                next2.value
              );
            } else {
              _block = !isEqual2(prev.value, next2.value);
            }
            let has_changes = _block;
            let _block$1;
            if (has_changes) {
              _block$1 = prepend(next2, added);
            } else {
              _block$1 = added;
            }
            let added$1 = _block$1;
            loop$controlled = controlled;
            loop$path = path;
            loop$mapper = mapper;
            loop$events = events;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed;
          } else if (prev instanceof Event2) {
            let name = prev.name;
            let added$1 = prepend(next2, added);
            let removed$1 = prepend(prev, removed);
            let events$1 = remove_event(events, path, name);
            loop$controlled = controlled;
            loop$path = path;
            loop$mapper = mapper;
            loop$events = events$1;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed$1;
          } else {
            let added$1 = prepend(next2, added);
            let removed$1 = prepend(prev, removed);
            loop$controlled = controlled;
            loop$path = path;
            loop$mapper = mapper;
            loop$events = events;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed$1;
          }
        } else if (prev instanceof Event2) {
          let name = next2.name;
          let handler = next2.handler;
          let has_changes = prev.prevent_default.kind !== next2.prevent_default.kind || prev.stop_propagation.kind !== next2.stop_propagation.kind || prev.immediate !== next2.immediate || prev.debounce !== next2.debounce || prev.throttle !== next2.throttle;
          let _block;
          if (has_changes) {
            _block = prepend(next2, added);
          } else {
            _block = added;
          }
          let added$1 = _block;
          let events$1 = add_event(events, mapper, path, name, handler);
          loop$controlled = controlled;
          loop$path = path;
          loop$mapper = mapper;
          loop$events = events$1;
          loop$old = remaining_old;
          loop$new = remaining_new;
          loop$added = added$1;
          loop$removed = removed;
        } else {
          let name = next2.name;
          let handler = next2.handler;
          let added$1 = prepend(next2, added);
          let removed$1 = prepend(prev, removed);
          let events$1 = add_event(events, mapper, path, name, handler);
          loop$controlled = controlled;
          loop$path = path;
          loop$mapper = mapper;
          loop$events = events$1;
          loop$old = remaining_old;
          loop$new = remaining_new;
          loop$added = added$1;
          loop$removed = removed$1;
        }
      } else if (next2 instanceof Event2) {
        let name = next2.name;
        let handler = next2.handler;
        let added$1 = prepend(next2, added);
        let events$1 = add_event(events, mapper, path, name, handler);
        loop$controlled = controlled;
        loop$path = path;
        loop$mapper = mapper;
        loop$events = events$1;
        loop$old = old;
        loop$new = remaining_new;
        loop$added = added$1;
        loop$removed = removed;
      } else {
        let added$1 = prepend(next2, added);
        loop$controlled = controlled;
        loop$path = path;
        loop$mapper = mapper;
        loop$events = events;
        loop$old = old;
        loop$new = remaining_new;
        loop$added = added$1;
        loop$removed = removed;
      }
    }
  }
}
function do_diff(loop$old, loop$old_keyed, loop$new, loop$new_keyed, loop$moved, loop$moved_offset, loop$removed, loop$node_index, loop$patch_index, loop$path, loop$changes, loop$children, loop$mapper, loop$events) {
  while (true) {
    let old = loop$old;
    let old_keyed = loop$old_keyed;
    let new$12 = loop$new;
    let new_keyed = loop$new_keyed;
    let moved = loop$moved;
    let moved_offset = loop$moved_offset;
    let removed = loop$removed;
    let node_index = loop$node_index;
    let patch_index = loop$patch_index;
    let path = loop$path;
    let changes = loop$changes;
    let children = loop$children;
    let mapper = loop$mapper;
    let events = loop$events;
    if (new$12 instanceof Empty) {
      if (old instanceof Empty) {
        return new Diff(
          new Patch(patch_index, removed, changes, children),
          events
        );
      } else {
        let prev = old.head;
        let old$1 = old.tail;
        let _block;
        let $ = prev.key === "" || !has_key2(moved, prev.key);
        if ($) {
          _block = removed + 1;
        } else {
          _block = removed;
        }
        let removed$1 = _block;
        let events$1 = remove_child(events, path, node_index, prev);
        loop$old = old$1;
        loop$old_keyed = old_keyed;
        loop$new = new$12;
        loop$new_keyed = new_keyed;
        loop$moved = moved;
        loop$moved_offset = moved_offset;
        loop$removed = removed$1;
        loop$node_index = node_index;
        loop$patch_index = patch_index;
        loop$path = path;
        loop$changes = changes;
        loop$children = children;
        loop$mapper = mapper;
        loop$events = events$1;
      }
    } else if (old instanceof Empty) {
      let events$1 = add_children(
        events,
        mapper,
        path,
        node_index,
        new$12
      );
      let insert5 = insert4(new$12, node_index - moved_offset);
      let changes$1 = prepend(insert5, changes);
      return new Diff(
        new Patch(patch_index, removed, changes$1, children),
        events$1
      );
    } else {
      let next2 = new$12.head;
      let prev = old.head;
      if (prev.key !== next2.key) {
        let new_remaining = new$12.tail;
        let old_remaining = old.tail;
        let next_did_exist = get(old_keyed, next2.key);
        let prev_does_exist = has_key2(new_keyed, prev.key);
        if (next_did_exist instanceof Ok) {
          if (prev_does_exist) {
            let match2 = next_did_exist[0];
            let $ = has_key2(moved, prev.key);
            if ($) {
              loop$old = old_remaining;
              loop$old_keyed = old_keyed;
              loop$new = new$12;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset - 1;
              loop$removed = removed;
              loop$node_index = node_index;
              loop$patch_index = patch_index;
              loop$path = path;
              loop$changes = changes;
              loop$children = children;
              loop$mapper = mapper;
              loop$events = events;
            } else {
              let before = node_index - moved_offset;
              let changes$1 = prepend(
                move(next2.key, before),
                changes
              );
              let moved$1 = insert3(moved, next2.key, void 0);
              let moved_offset$1 = moved_offset + 1;
              loop$old = prepend(match2, old);
              loop$old_keyed = old_keyed;
              loop$new = new$12;
              loop$new_keyed = new_keyed;
              loop$moved = moved$1;
              loop$moved_offset = moved_offset$1;
              loop$removed = removed;
              loop$node_index = node_index;
              loop$patch_index = patch_index;
              loop$path = path;
              loop$changes = changes$1;
              loop$children = children;
              loop$mapper = mapper;
              loop$events = events;
            }
          } else {
            let index4 = node_index - moved_offset;
            let changes$1 = prepend(remove2(index4), changes);
            let events$1 = remove_child(events, path, node_index, prev);
            let moved_offset$1 = moved_offset - 1;
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new$12;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset$1;
            loop$removed = removed;
            loop$node_index = node_index;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = changes$1;
            loop$children = children;
            loop$mapper = mapper;
            loop$events = events$1;
          }
        } else if (prev_does_exist) {
          let before = node_index - moved_offset;
          let events$1 = add_child(
            events,
            mapper,
            path,
            node_index,
            next2
          );
          let insert5 = insert4(toList([next2]), before);
          let changes$1 = prepend(insert5, changes);
          loop$old = old;
          loop$old_keyed = old_keyed;
          loop$new = new_remaining;
          loop$new_keyed = new_keyed;
          loop$moved = moved;
          loop$moved_offset = moved_offset + 1;
          loop$removed = removed;
          loop$node_index = node_index + 1;
          loop$patch_index = patch_index;
          loop$path = path;
          loop$changes = changes$1;
          loop$children = children;
          loop$mapper = mapper;
          loop$events = events$1;
        } else {
          let change = replace2(node_index - moved_offset, next2);
          let _block;
          let _pipe = events;
          let _pipe$1 = remove_child(_pipe, path, node_index, prev);
          _block = add_child(_pipe$1, mapper, path, node_index, next2);
          let events$1 = _block;
          loop$old = old_remaining;
          loop$old_keyed = old_keyed;
          loop$new = new_remaining;
          loop$new_keyed = new_keyed;
          loop$moved = moved;
          loop$moved_offset = moved_offset;
          loop$removed = removed;
          loop$node_index = node_index + 1;
          loop$patch_index = patch_index;
          loop$path = path;
          loop$changes = prepend(change, changes);
          loop$children = children;
          loop$mapper = mapper;
          loop$events = events$1;
        }
      } else {
        let $ = old.head;
        if ($ instanceof Fragment) {
          let $1 = new$12.head;
          if ($1 instanceof Fragment) {
            let next$1 = $1;
            let new$1 = new$12.tail;
            let prev$1 = $;
            let old$1 = old.tail;
            let composed_mapper = compose_mapper(mapper, next$1.mapper);
            let child_path = add2(path, node_index, next$1.key);
            let child = do_diff(
              prev$1.children,
              prev$1.keyed_children,
              next$1.children,
              next$1.keyed_children,
              empty2(),
              0,
              0,
              0,
              node_index,
              child_path,
              empty_list,
              empty_list,
              composed_mapper,
              events
            );
            let _block;
            let $2 = child.patch;
            let $3 = $2.children;
            if ($3 instanceof Empty) {
              let $4 = $2.changes;
              if ($4 instanceof Empty) {
                let $5 = $2.removed;
                if ($5 === 0) {
                  _block = children;
                } else {
                  _block = prepend(child.patch, children);
                }
              } else {
                _block = prepend(child.patch, children);
              }
            } else {
              _block = prepend(child.patch, children);
            }
            let children$1 = _block;
            loop$old = old$1;
            loop$old_keyed = old_keyed;
            loop$new = new$1;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = changes;
            loop$children = children$1;
            loop$mapper = mapper;
            loop$events = child.events;
          } else {
            let next$1 = $1;
            let new_remaining = new$12.tail;
            let prev$1 = $;
            let old_remaining = old.tail;
            let change = replace2(node_index - moved_offset, next$1);
            let _block;
            let _pipe = events;
            let _pipe$1 = remove_child(_pipe, path, node_index, prev$1);
            _block = add_child(
              _pipe$1,
              mapper,
              path,
              node_index,
              next$1
            );
            let events$1 = _block;
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$mapper = mapper;
            loop$events = events$1;
          }
        } else if ($ instanceof Element) {
          let $1 = new$12.head;
          if ($1 instanceof Element) {
            let next$1 = $1;
            let prev$1 = $;
            if (prev$1.namespace === next$1.namespace && prev$1.tag === next$1.tag) {
              let new$1 = new$12.tail;
              let old$1 = old.tail;
              let composed_mapper = compose_mapper(
                mapper,
                next$1.mapper
              );
              let child_path = add2(path, node_index, next$1.key);
              let controlled = is_controlled(
                events,
                next$1.namespace,
                next$1.tag,
                child_path
              );
              let $2 = diff_attributes(
                controlled,
                child_path,
                composed_mapper,
                events,
                prev$1.attributes,
                next$1.attributes,
                empty_list,
                empty_list
              );
              let added_attrs;
              let removed_attrs;
              let events$1;
              added_attrs = $2.added;
              removed_attrs = $2.removed;
              events$1 = $2.events;
              let _block;
              if (removed_attrs instanceof Empty && added_attrs instanceof Empty) {
                _block = empty_list;
              } else {
                _block = toList([update(added_attrs, removed_attrs)]);
              }
              let initial_child_changes = _block;
              let child = do_diff(
                prev$1.children,
                prev$1.keyed_children,
                next$1.children,
                next$1.keyed_children,
                empty2(),
                0,
                0,
                0,
                node_index,
                child_path,
                initial_child_changes,
                empty_list,
                composed_mapper,
                events$1
              );
              let _block$1;
              let $3 = child.patch;
              let $4 = $3.children;
              if ($4 instanceof Empty) {
                let $5 = $3.changes;
                if ($5 instanceof Empty) {
                  let $6 = $3.removed;
                  if ($6 === 0) {
                    _block$1 = children;
                  } else {
                    _block$1 = prepend(child.patch, children);
                  }
                } else {
                  _block$1 = prepend(child.patch, children);
                }
              } else {
                _block$1 = prepend(child.patch, children);
              }
              let children$1 = _block$1;
              loop$old = old$1;
              loop$old_keyed = old_keyed;
              loop$new = new$1;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset;
              loop$removed = removed;
              loop$node_index = node_index + 1;
              loop$patch_index = patch_index;
              loop$path = path;
              loop$changes = changes;
              loop$children = children$1;
              loop$mapper = mapper;
              loop$events = child.events;
            } else {
              let next$2 = $1;
              let new_remaining = new$12.tail;
              let prev$2 = $;
              let old_remaining = old.tail;
              let change = replace2(node_index - moved_offset, next$2);
              let _block;
              let _pipe = events;
              let _pipe$1 = remove_child(
                _pipe,
                path,
                node_index,
                prev$2
              );
              _block = add_child(
                _pipe$1,
                mapper,
                path,
                node_index,
                next$2
              );
              let events$1 = _block;
              loop$old = old_remaining;
              loop$old_keyed = old_keyed;
              loop$new = new_remaining;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset;
              loop$removed = removed;
              loop$node_index = node_index + 1;
              loop$patch_index = patch_index;
              loop$path = path;
              loop$changes = prepend(change, changes);
              loop$children = children;
              loop$mapper = mapper;
              loop$events = events$1;
            }
          } else {
            let next$1 = $1;
            let new_remaining = new$12.tail;
            let prev$1 = $;
            let old_remaining = old.tail;
            let change = replace2(node_index - moved_offset, next$1);
            let _block;
            let _pipe = events;
            let _pipe$1 = remove_child(_pipe, path, node_index, prev$1);
            _block = add_child(
              _pipe$1,
              mapper,
              path,
              node_index,
              next$1
            );
            let events$1 = _block;
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$mapper = mapper;
            loop$events = events$1;
          }
        } else if ($ instanceof Text) {
          let $1 = new$12.head;
          if ($1 instanceof Text) {
            let next$1 = $1;
            let prev$1 = $;
            if (prev$1.content === next$1.content) {
              let new$1 = new$12.tail;
              let old$1 = old.tail;
              loop$old = old$1;
              loop$old_keyed = old_keyed;
              loop$new = new$1;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset;
              loop$removed = removed;
              loop$node_index = node_index + 1;
              loop$patch_index = patch_index;
              loop$path = path;
              loop$changes = changes;
              loop$children = children;
              loop$mapper = mapper;
              loop$events = events;
            } else {
              let next$2 = $1;
              let new$1 = new$12.tail;
              let old$1 = old.tail;
              let child = new$5(
                node_index,
                0,
                toList([replace_text(next$2.content)]),
                empty_list
              );
              loop$old = old$1;
              loop$old_keyed = old_keyed;
              loop$new = new$1;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset;
              loop$removed = removed;
              loop$node_index = node_index + 1;
              loop$patch_index = patch_index;
              loop$path = path;
              loop$changes = changes;
              loop$children = prepend(child, children);
              loop$mapper = mapper;
              loop$events = events;
            }
          } else {
            let next$1 = $1;
            let new_remaining = new$12.tail;
            let prev$1 = $;
            let old_remaining = old.tail;
            let change = replace2(node_index - moved_offset, next$1);
            let _block;
            let _pipe = events;
            let _pipe$1 = remove_child(_pipe, path, node_index, prev$1);
            _block = add_child(
              _pipe$1,
              mapper,
              path,
              node_index,
              next$1
            );
            let events$1 = _block;
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$mapper = mapper;
            loop$events = events$1;
          }
        } else {
          let $1 = new$12.head;
          if ($1 instanceof UnsafeInnerHtml) {
            let next$1 = $1;
            let new$1 = new$12.tail;
            let prev$1 = $;
            let old$1 = old.tail;
            let composed_mapper = compose_mapper(mapper, next$1.mapper);
            let child_path = add2(path, node_index, next$1.key);
            let $2 = diff_attributes(
              false,
              child_path,
              composed_mapper,
              events,
              prev$1.attributes,
              next$1.attributes,
              empty_list,
              empty_list
            );
            let added_attrs;
            let removed_attrs;
            let events$1;
            added_attrs = $2.added;
            removed_attrs = $2.removed;
            events$1 = $2.events;
            let _block;
            if (removed_attrs instanceof Empty && added_attrs instanceof Empty) {
              _block = empty_list;
            } else {
              _block = toList([update(added_attrs, removed_attrs)]);
            }
            let child_changes = _block;
            let _block$1;
            let $3 = prev$1.inner_html === next$1.inner_html;
            if ($3) {
              _block$1 = child_changes;
            } else {
              _block$1 = prepend(
                replace_inner_html(next$1.inner_html),
                child_changes
              );
            }
            let child_changes$1 = _block$1;
            let _block$2;
            if (child_changes$1 instanceof Empty) {
              _block$2 = children;
            } else {
              _block$2 = prepend(
                new$5(node_index, 0, child_changes$1, toList([])),
                children
              );
            }
            let children$1 = _block$2;
            loop$old = old$1;
            loop$old_keyed = old_keyed;
            loop$new = new$1;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = changes;
            loop$children = children$1;
            loop$mapper = mapper;
            loop$events = events$1;
          } else {
            let next$1 = $1;
            let new_remaining = new$12.tail;
            let prev$1 = $;
            let old_remaining = old.tail;
            let change = replace2(node_index - moved_offset, next$1);
            let _block;
            let _pipe = events;
            let _pipe$1 = remove_child(_pipe, path, node_index, prev$1);
            _block = add_child(
              _pipe$1,
              mapper,
              path,
              node_index,
              next$1
            );
            let events$1 = _block;
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$mapper = mapper;
            loop$events = events$1;
          }
        }
      }
    }
  }
}
function diff(events, old, new$12) {
  return do_diff(
    toList([old]),
    empty2(),
    toList([new$12]),
    empty2(),
    empty2(),
    0,
    0,
    0,
    0,
    root2,
    empty_list,
    empty_list,
    identity2,
    tick(events)
  );
}

// build/dev/javascript/lustre/lustre/vdom/reconciler.ffi.mjs
var setTimeout = globalThis.setTimeout;
var clearTimeout = globalThis.clearTimeout;
var createElementNS = (ns, name) => document().createElementNS(ns, name);
var createTextNode = (data) => document().createTextNode(data);
var createDocumentFragment = () => document().createDocumentFragment();
var insertBefore = (parent, node, reference) => parent.insertBefore(node, reference);
var moveBefore = SUPPORTS_MOVE_BEFORE ? (parent, node, reference) => parent.moveBefore(node, reference) : insertBefore;
var removeChild = (parent, child) => parent.removeChild(child);
var getAttribute = (node, name) => node.getAttribute(name);
var setAttribute = (node, name, value) => node.setAttribute(name, value);
var removeAttribute = (node, name) => node.removeAttribute(name);
var addEventListener = (node, name, handler, options) => node.addEventListener(name, handler, options);
var removeEventListener = (node, name, handler) => node.removeEventListener(name, handler);
var setInnerHtml = (node, innerHtml) => node.innerHTML = innerHtml;
var setData = (node, data) => node.data = data;
var meta = Symbol("lustre");
var MetadataNode = class {
  constructor(kind, parent, node, key) {
    this.kind = kind;
    this.key = key;
    this.parent = parent;
    this.children = [];
    this.node = node;
    this.handlers = /* @__PURE__ */ new Map();
    this.throttles = /* @__PURE__ */ new Map();
    this.debouncers = /* @__PURE__ */ new Map();
  }
  get parentNode() {
    return this.kind === fragment_kind ? this.node.parentNode : this.node;
  }
};
var insertMetadataChild = (kind, parent, node, index4, key) => {
  const child = new MetadataNode(kind, parent, node, key);
  node[meta] = child;
  parent?.children.splice(index4, 0, child);
  return child;
};
var getPath = (node) => {
  let path = "";
  for (let current = node[meta]; current.parent; current = current.parent) {
    if (current.key) {
      path = `${separator_element}${current.key}${path}`;
    } else {
      const index4 = current.parent.children.indexOf(current);
      path = `${separator_element}${index4}${path}`;
    }
  }
  return path.slice(1);
};
var Reconciler = class {
  #root = null;
  #dispatch = () => {
  };
  #useServerEvents = false;
  #exposeKeys = false;
  constructor(root3, dispatch, { useServerEvents = false, exposeKeys = false } = {}) {
    this.#root = root3;
    this.#dispatch = dispatch;
    this.#useServerEvents = useServerEvents;
    this.#exposeKeys = exposeKeys;
  }
  mount(vdom) {
    insertMetadataChild(element_kind, null, this.#root, 0, null);
    this.#insertChild(this.#root, null, this.#root[meta], 0, vdom);
  }
  push(patch) {
    this.#stack.push({ node: this.#root[meta], patch });
    this.#reconcile();
  }
  // PATCHING ------------------------------------------------------------------
  #stack = [];
  #reconcile() {
    const stack = this.#stack;
    while (stack.length) {
      const { node, patch } = stack.pop();
      const { children: childNodes } = node;
      const { changes, removed, children: childPatches } = patch;
      iterate(changes, (change) => this.#patch(node, change));
      if (removed) {
        this.#removeChildren(node, childNodes.length - removed, removed);
      }
      iterate(childPatches, (childPatch) => {
        const child = childNodes[childPatch.index | 0];
        this.#stack.push({ node: child, patch: childPatch });
      });
    }
  }
  #patch(node, change) {
    switch (change.kind) {
      case replace_text_kind:
        this.#replaceText(node, change);
        break;
      case replace_inner_html_kind:
        this.#replaceInnerHtml(node, change);
        break;
      case update_kind:
        this.#update(node, change);
        break;
      case move_kind:
        this.#move(node, change);
        break;
      case remove_kind:
        this.#remove(node, change);
        break;
      case replace_kind:
        this.#replace(node, change);
        break;
      case insert_kind:
        this.#insert(node, change);
        break;
    }
  }
  // CHANGES -------------------------------------------------------------------
  #insert(parent, { children, before }) {
    const fragment4 = createDocumentFragment();
    const beforeEl = this.#getReference(parent, before);
    this.#insertChildren(fragment4, null, parent, before | 0, children);
    insertBefore(parent.parentNode, fragment4, beforeEl);
  }
  #replace(parent, { index: index4, with: child }) {
    this.#removeChildren(parent, index4 | 0, 1);
    const beforeEl = this.#getReference(parent, index4);
    this.#insertChild(parent.parentNode, beforeEl, parent, index4 | 0, child);
  }
  #getReference(node, index4) {
    index4 = index4 | 0;
    const { children } = node;
    const childCount = children.length;
    if (index4 < childCount) {
      return children[index4].node;
    }
    let lastChild = children[childCount - 1];
    if (!lastChild && node.kind !== fragment_kind) return null;
    if (!lastChild) lastChild = node;
    while (lastChild.kind === fragment_kind && lastChild.children.length) {
      lastChild = lastChild.children[lastChild.children.length - 1];
    }
    return lastChild.node.nextSibling;
  }
  #move(parent, { key, before }) {
    before = before | 0;
    const { children, parentNode } = parent;
    const beforeEl = children[before].node;
    let prev = children[before];
    for (let i = before + 1; i < children.length; ++i) {
      const next2 = children[i];
      children[i] = prev;
      prev = next2;
      if (next2.key === key) {
        children[before] = next2;
        break;
      }
    }
    const { kind, node, children: prevChildren } = prev;
    moveBefore(parentNode, node, beforeEl);
    if (kind === fragment_kind) {
      this.#moveChildren(parentNode, prevChildren, beforeEl);
    }
  }
  #moveChildren(domParent, children, beforeEl) {
    for (let i = 0; i < children.length; ++i) {
      const { kind, node, children: nestedChildren } = children[i];
      moveBefore(domParent, node, beforeEl);
      if (kind === fragment_kind) {
        this.#moveChildren(domParent, nestedChildren, beforeEl);
      }
    }
  }
  #remove(parent, { index: index4 }) {
    this.#removeChildren(parent, index4, 1);
  }
  #removeChildren(parent, index4, count) {
    const { children, parentNode } = parent;
    const deleted = children.splice(index4, count);
    for (let i = 0; i < deleted.length; ++i) {
      const { kind, node, children: nestedChildren } = deleted[i];
      removeChild(parentNode, node);
      this.#removeDebouncers(deleted[i]);
      if (kind === fragment_kind) {
        deleted.push(...nestedChildren);
      }
    }
  }
  #removeDebouncers(node) {
    const { debouncers, children } = node;
    for (const { timeout } of debouncers.values()) {
      if (timeout) {
        clearTimeout(timeout);
      }
    }
    debouncers.clear();
    iterate(children, (child) => this.#removeDebouncers(child));
  }
  #update({ node, handlers, throttles, debouncers }, { added, removed }) {
    iterate(removed, ({ name }) => {
      if (handlers.delete(name)) {
        removeEventListener(node, name, handleEvent);
        this.#updateDebounceThrottle(throttles, name, 0);
        this.#updateDebounceThrottle(debouncers, name, 0);
      } else {
        removeAttribute(node, name);
        SYNCED_ATTRIBUTES[name]?.removed?.(node, name);
      }
    });
    iterate(added, (attribute3) => this.#createAttribute(node, attribute3));
  }
  #replaceText({ node }, { content }) {
    setData(node, content ?? "");
  }
  #replaceInnerHtml({ node }, { inner_html }) {
    setInnerHtml(node, inner_html ?? "");
  }
  // INSERT --------------------------------------------------------------------
  #insertChildren(domParent, beforeEl, metaParent, index4, children) {
    iterate(
      children,
      (child) => this.#insertChild(domParent, beforeEl, metaParent, index4++, child)
    );
  }
  #insertChild(domParent, beforeEl, metaParent, index4, vnode) {
    switch (vnode.kind) {
      case element_kind: {
        const node = this.#createElement(metaParent, index4, vnode);
        this.#insertChildren(node, null, node[meta], 0, vnode.children);
        insertBefore(domParent, node, beforeEl);
        break;
      }
      case text_kind: {
        const node = this.#createTextNode(metaParent, index4, vnode);
        insertBefore(domParent, node, beforeEl);
        break;
      }
      case fragment_kind: {
        const head = this.#createTextNode(metaParent, index4, vnode);
        insertBefore(domParent, head, beforeEl);
        this.#insertChildren(
          domParent,
          beforeEl,
          head[meta],
          0,
          vnode.children
        );
        break;
      }
      case unsafe_inner_html_kind: {
        const node = this.#createElement(metaParent, index4, vnode);
        this.#replaceInnerHtml({ node }, vnode);
        insertBefore(domParent, node, beforeEl);
        break;
      }
    }
  }
  #createElement(parent, index4, { kind, key, tag, namespace, attributes }) {
    const node = createElementNS(namespace || NAMESPACE_HTML, tag);
    insertMetadataChild(kind, parent, node, index4, key);
    if (this.#exposeKeys && key) {
      setAttribute(node, "data-lustre-key", key);
    }
    iterate(attributes, (attribute3) => this.#createAttribute(node, attribute3));
    return node;
  }
  #createTextNode(parent, index4, { kind, key, content }) {
    const node = createTextNode(content ?? "");
    insertMetadataChild(kind, parent, node, index4, key);
    return node;
  }
  #createAttribute(node, attribute3) {
    const { debouncers, handlers, throttles } = node[meta];
    const {
      kind,
      name,
      value,
      prevent_default: prevent,
      debounce: debounceDelay,
      throttle: throttleDelay
    } = attribute3;
    switch (kind) {
      case attribute_kind: {
        const valueOrDefault = value ?? "";
        if (name === "virtual:defaultValue") {
          node.defaultValue = valueOrDefault;
          return;
        }
        if (valueOrDefault !== getAttribute(node, name)) {
          setAttribute(node, name, valueOrDefault);
        }
        SYNCED_ATTRIBUTES[name]?.added?.(node, valueOrDefault);
        break;
      }
      case property_kind:
        node[name] = value;
        break;
      case event_kind: {
        if (handlers.has(name)) {
          removeEventListener(node, name, handleEvent);
        }
        const passive = prevent.kind === never_kind;
        addEventListener(node, name, handleEvent, { passive });
        this.#updateDebounceThrottle(throttles, name, throttleDelay);
        this.#updateDebounceThrottle(debouncers, name, debounceDelay);
        handlers.set(name, (event4) => this.#handleEvent(attribute3, event4));
        break;
      }
    }
  }
  #updateDebounceThrottle(map7, name, delay) {
    const debounceOrThrottle = map7.get(name);
    if (delay > 0) {
      if (debounceOrThrottle) {
        debounceOrThrottle.delay = delay;
      } else {
        map7.set(name, { delay });
      }
    } else if (debounceOrThrottle) {
      const { timeout } = debounceOrThrottle;
      if (timeout) {
        clearTimeout(timeout);
      }
      map7.delete(name);
    }
  }
  #handleEvent(attribute3, event4) {
    const { currentTarget, type } = event4;
    const { debouncers, throttles } = currentTarget[meta];
    const path = getPath(currentTarget);
    const {
      prevent_default: prevent,
      stop_propagation: stop,
      include,
      immediate
    } = attribute3;
    if (prevent.kind === always_kind) event4.preventDefault();
    if (stop.kind === always_kind) event4.stopPropagation();
    if (type === "submit") {
      event4.detail ??= {};
      event4.detail.formData = [
        ...new FormData(event4.target, event4.submitter).entries()
      ];
    }
    const data = this.#useServerEvents ? createServerEvent(event4, include ?? []) : event4;
    const throttle = throttles.get(type);
    if (throttle) {
      const now = Date.now();
      const last = throttle.last || 0;
      if (now > last + throttle.delay) {
        throttle.last = now;
        throttle.lastEvent = event4;
        this.#dispatch(data, path, type, immediate);
      }
    }
    const debounce = debouncers.get(type);
    if (debounce) {
      clearTimeout(debounce.timeout);
      debounce.timeout = setTimeout(() => {
        if (event4 === throttles.get(type)?.lastEvent) return;
        this.#dispatch(data, path, type, immediate);
      }, debounce.delay);
    }
    if (!throttle && !debounce) {
      this.#dispatch(data, path, type, immediate);
    }
  }
};
var iterate = (list4, callback) => {
  if (Array.isArray(list4)) {
    for (let i = 0; i < list4.length; i++) {
      callback(list4[i]);
    }
  } else if (list4) {
    for (list4; list4.head; list4 = list4.tail) {
      callback(list4.head);
    }
  }
};
var handleEvent = (event4) => {
  const { currentTarget, type } = event4;
  const handler = currentTarget[meta].handlers.get(type);
  handler(event4);
};
var createServerEvent = (event4, include = []) => {
  const data = {};
  if (event4.type === "input" || event4.type === "change") {
    include.push("target.value");
  }
  if (event4.type === "submit") {
    include.push("detail.formData");
  }
  for (const property3 of include) {
    const path = property3.split(".");
    for (let i = 0, input = event4, output = data; i < path.length; i++) {
      if (i === path.length - 1) {
        output[path[i]] = input[path[i]];
        break;
      }
      output = output[path[i]] ??= {};
      input = input[path[i]];
    }
  }
  return data;
};
var syncedBooleanAttribute = /* @__NO_SIDE_EFFECTS__ */ (name) => {
  return {
    added(node) {
      node[name] = true;
    },
    removed(node) {
      node[name] = false;
    }
  };
};
var syncedAttribute = /* @__NO_SIDE_EFFECTS__ */ (name) => {
  return {
    added(node, value) {
      node[name] = value;
    }
  };
};
var SYNCED_ATTRIBUTES = {
  checked: /* @__PURE__ */ syncedBooleanAttribute("checked"),
  selected: /* @__PURE__ */ syncedBooleanAttribute("selected"),
  value: /* @__PURE__ */ syncedAttribute("value"),
  autofocus: {
    added(node) {
      queueMicrotask(() => {
        node.focus?.();
      });
    }
  },
  autoplay: {
    added(node) {
      try {
        node.play?.();
      } catch (e) {
        console.error(e);
      }
    }
  }
};

// build/dev/javascript/lustre/lustre/element/keyed.mjs
function do_extract_keyed_children(loop$key_children_pairs, loop$keyed_children, loop$children) {
  while (true) {
    let key_children_pairs = loop$key_children_pairs;
    let keyed_children = loop$keyed_children;
    let children = loop$children;
    if (key_children_pairs instanceof Empty) {
      return [keyed_children, reverse(children)];
    } else {
      let rest = key_children_pairs.tail;
      let key = key_children_pairs.head[0];
      let element$1 = key_children_pairs.head[1];
      let keyed_element = to_keyed(key, element$1);
      let _block;
      if (key === "") {
        _block = keyed_children;
      } else {
        _block = insert3(keyed_children, key, keyed_element);
      }
      let keyed_children$1 = _block;
      let children$1 = prepend(keyed_element, children);
      loop$key_children_pairs = rest;
      loop$keyed_children = keyed_children$1;
      loop$children = children$1;
    }
  }
}
function extract_keyed_children(children) {
  return do_extract_keyed_children(
    children,
    empty2(),
    empty_list
  );
}
function element3(tag, attributes, children) {
  let $ = extract_keyed_children(children);
  let keyed_children;
  let children$1;
  keyed_children = $[0];
  children$1 = $[1];
  return element(
    "",
    identity2,
    "",
    tag,
    attributes,
    children$1,
    keyed_children,
    false,
    false
  );
}
function namespaced2(namespace, tag, attributes, children) {
  let $ = extract_keyed_children(children);
  let keyed_children;
  let children$1;
  keyed_children = $[0];
  children$1 = $[1];
  return element(
    "",
    identity2,
    namespace,
    tag,
    attributes,
    children$1,
    keyed_children,
    false,
    false
  );
}
function fragment3(children) {
  let $ = extract_keyed_children(children);
  let keyed_children;
  let children$1;
  keyed_children = $[0];
  children$1 = $[1];
  return fragment("", identity2, children$1, keyed_children);
}

// build/dev/javascript/lustre/lustre/vdom/virtualise.ffi.mjs
var virtualise = (root3) => {
  const rootMeta = insertMetadataChild(element_kind, null, root3, 0, null);
  let virtualisableRootChildren = 0;
  for (let child = root3.firstChild; child; child = child.nextSibling) {
    if (canVirtualiseNode(child)) virtualisableRootChildren += 1;
  }
  if (virtualisableRootChildren === 0) {
    const placeholder = document().createTextNode("");
    insertMetadataChild(text_kind, rootMeta, placeholder, 0, null);
    root3.replaceChildren(placeholder);
    return none2();
  }
  if (virtualisableRootChildren === 1) {
    const children2 = virtualiseChildNodes(rootMeta, root3);
    return children2.head[1];
  }
  const fragmentHead = document().createTextNode("");
  const fragmentMeta = insertMetadataChild(fragment_kind, rootMeta, fragmentHead, 0, null);
  const children = virtualiseChildNodes(fragmentMeta, root3);
  root3.insertBefore(fragmentHead, root3.firstChild);
  return fragment3(children);
};
var canVirtualiseNode = (node) => {
  switch (node.nodeType) {
    case ELEMENT_NODE:
      return true;
    case TEXT_NODE:
      return !!node.data;
    default:
      return false;
  }
};
var virtualiseNode = (meta2, node, key, index4) => {
  if (!canVirtualiseNode(node)) {
    return null;
  }
  switch (node.nodeType) {
    case ELEMENT_NODE: {
      const childMeta = insertMetadataChild(element_kind, meta2, node, index4, key);
      const tag = node.localName;
      const namespace = node.namespaceURI;
      const isHtmlElement = !namespace || namespace === NAMESPACE_HTML;
      if (isHtmlElement && INPUT_ELEMENTS.includes(tag)) {
        virtualiseInputEvents(tag, node);
      }
      const attributes = virtualiseAttributes(node);
      const children = virtualiseChildNodes(childMeta, node);
      const vnode = isHtmlElement ? element3(tag, attributes, children) : namespaced2(namespace, tag, attributes, children);
      return vnode;
    }
    case TEXT_NODE:
      insertMetadataChild(text_kind, meta2, node, index4, null);
      return text2(node.data);
    default:
      return null;
  }
};
var INPUT_ELEMENTS = ["input", "select", "textarea"];
var virtualiseInputEvents = (tag, node) => {
  const value = node.value;
  const checked = node.checked;
  if (tag === "input" && node.type === "checkbox" && !checked) return;
  if (tag === "input" && node.type === "radio" && !checked) return;
  if (node.type !== "checkbox" && node.type !== "radio" && !value) return;
  queueMicrotask(() => {
    node.value = value;
    node.checked = checked;
    node.dispatchEvent(new Event("input", { bubbles: true }));
    node.dispatchEvent(new Event("change", { bubbles: true }));
    if (document().activeElement !== node) {
      node.dispatchEvent(new Event("blur", { bubbles: true }));
    }
  });
};
var virtualiseChildNodes = (meta2, node) => {
  let children = null;
  let child = node.firstChild;
  let ptr = null;
  let index4 = 0;
  while (child) {
    const key = child.nodeType === ELEMENT_NODE ? child.getAttribute("data-lustre-key") : null;
    if (key != null) {
      child.removeAttribute("data-lustre-key");
    }
    const vnode = virtualiseNode(meta2, child, key, index4);
    const next2 = child.nextSibling;
    if (vnode) {
      const list_node = new NonEmpty([key ?? "", vnode], null);
      if (ptr) {
        ptr = ptr.tail = list_node;
      } else {
        ptr = children = list_node;
      }
      index4 += 1;
    } else {
      node.removeChild(child);
    }
    child = next2;
  }
  if (!ptr) return empty_list;
  ptr.tail = empty_list;
  return children;
};
var virtualiseAttributes = (node) => {
  let index4 = node.attributes.length;
  let attributes = empty_list;
  while (index4-- > 0) {
    const attr = node.attributes[index4];
    if (attr.name === "xmlns") {
      continue;
    }
    attributes = new NonEmpty(virtualiseAttribute(attr), attributes);
  }
  return attributes;
};
var virtualiseAttribute = (attr) => {
  const name = attr.localName;
  const value = attr.value;
  return attribute2(name, value);
};

// build/dev/javascript/lustre/lustre/runtime/client/runtime.ffi.mjs
var is_browser = () => !!document();
var Runtime = class {
  constructor(root3, [model, effects], view2, update4) {
    this.root = root3;
    this.#model = model;
    this.#view = view2;
    this.#update = update4;
    this.root.addEventListener("context-request", (event4) => {
      if (!(event4.context && event4.callback)) return;
      if (!this.#contexts.has(event4.context)) return;
      event4.stopImmediatePropagation();
      const context = this.#contexts.get(event4.context);
      if (event4.subscribe) {
        const callbackRef = new WeakRef(event4.callback);
        const unsubscribe = () => {
          context.subscribers = context.subscribers.filter(
            (subscriber) => subscriber !== callbackRef
          );
        };
        context.subscribers.push([callbackRef, unsubscribe]);
        event4.callback(context.value, unsubscribe);
      } else {
        event4.callback(context.value);
      }
    });
    this.#reconciler = new Reconciler(this.root, (event4, path, name) => {
      const [events, result] = handle(this.#events, path, name, event4);
      this.#events = events;
      if (result.isOk()) {
        const handler = result[0];
        if (handler.stop_propagation) event4.stopPropagation();
        if (handler.prevent_default) event4.preventDefault();
        this.dispatch(handler.message, false);
      }
    });
    this.#vdom = virtualise(this.root);
    this.#events = new$3();
    this.#shouldFlush = true;
    this.#tick(effects);
  }
  // PUBLIC API ----------------------------------------------------------------
  root = null;
  dispatch(msg, immediate = false) {
    this.#shouldFlush ||= immediate;
    if (this.#shouldQueue) {
      this.#queue.push(msg);
    } else {
      const [model, effects] = this.#update(this.#model, msg);
      this.#model = model;
      this.#tick(effects);
    }
  }
  emit(event4, data) {
    const target = this.root.host ?? this.root;
    target.dispatchEvent(
      new CustomEvent(event4, {
        detail: data,
        bubbles: true,
        composed: true
      })
    );
  }
  // Provide a context value for any child nodes that request it using the given
  // key. If the key already exists, any existing subscribers will be notified
  // of the change. Otherwise, we store the value and wait for any `context-request`
  // events to come in.
  provide(key, value) {
    if (!this.#contexts.has(key)) {
      this.#contexts.set(key, { value, subscribers: [] });
    } else {
      const context = this.#contexts.get(key);
      context.value = value;
      for (let i = context.subscribers.length - 1; i >= 0; i--) {
        const [subscriberRef, unsubscribe] = context.subscribers[i];
        const subscriber = subscriberRef.deref();
        if (!subscriber) {
          context.subscribers.splice(i, 1);
          continue;
        }
        subscriber(value, unsubscribe);
      }
    }
  }
  // PRIVATE API ---------------------------------------------------------------
  #model;
  #view;
  #update;
  #vdom;
  #events;
  #reconciler;
  #contexts = /* @__PURE__ */ new Map();
  #shouldQueue = false;
  #queue = [];
  #beforePaint = empty_list;
  #afterPaint = empty_list;
  #renderTimer = null;
  #shouldFlush = false;
  #actions = {
    dispatch: (msg, immediate) => this.dispatch(msg, immediate),
    emit: (event4, data) => this.emit(event4, data),
    select: () => {
    },
    root: () => this.root,
    provide: (key, value) => this.provide(key, value)
  };
  // A `#tick` is where we process effects and trigger any synchronous updates.
  // Once a tick has been processed a render will be scheduled if none is already.
  // p0
  #tick(effects) {
    this.#shouldQueue = true;
    while (true) {
      for (let list4 = effects.synchronous; list4.tail; list4 = list4.tail) {
        list4.head(this.#actions);
      }
      this.#beforePaint = listAppend(this.#beforePaint, effects.before_paint);
      this.#afterPaint = listAppend(this.#afterPaint, effects.after_paint);
      if (!this.#queue.length) break;
      [this.#model, effects] = this.#update(this.#model, this.#queue.shift());
    }
    this.#shouldQueue = false;
    if (this.#shouldFlush) {
      cancelAnimationFrame(this.#renderTimer);
      this.#render();
    } else if (!this.#renderTimer) {
      this.#renderTimer = requestAnimationFrame(() => {
        this.#render();
      });
    }
  }
  #render() {
    this.#shouldFlush = false;
    this.#renderTimer = null;
    const next2 = this.#view(this.#model);
    const { patch, events } = diff(this.#events, this.#vdom, next2);
    this.#events = events;
    this.#vdom = next2;
    this.#reconciler.push(patch);
    if (this.#beforePaint instanceof NonEmpty) {
      const effects = makeEffect(this.#beforePaint);
      this.#beforePaint = empty_list;
      queueMicrotask(() => {
        this.#shouldFlush = true;
        this.#tick(effects);
      });
    }
    if (this.#afterPaint instanceof NonEmpty) {
      const effects = makeEffect(this.#afterPaint);
      this.#afterPaint = empty_list;
      requestAnimationFrame(() => {
        this.#shouldFlush = true;
        this.#tick(effects);
      });
    }
  }
};
function makeEffect(synchronous) {
  return {
    synchronous,
    after_paint: empty_list,
    before_paint: empty_list
  };
}
function listAppend(a2, b) {
  if (a2 instanceof Empty) {
    return b;
  } else if (b instanceof Empty) {
    return a2;
  } else {
    return append3(a2, b);
  }
}

// build/dev/javascript/lustre/lustre/runtime/server/runtime.mjs
var EffectDispatchedMessage = class extends CustomType {
  constructor(message) {
    super();
    this.message = message;
  }
};
var EffectEmitEvent = class extends CustomType {
  constructor(name, data) {
    super();
    this.name = name;
    this.data = data;
  }
};
var SystemRequestedShutdown = class extends CustomType {
};

// build/dev/javascript/lustre/lustre/component.mjs
var Config2 = class extends CustomType {
  constructor(open_shadow_root, adopt_styles, delegates_focus, attributes, properties, contexts, is_form_associated, on_form_autofill, on_form_reset, on_form_restore) {
    super();
    this.open_shadow_root = open_shadow_root;
    this.adopt_styles = adopt_styles;
    this.delegates_focus = delegates_focus;
    this.attributes = attributes;
    this.properties = properties;
    this.contexts = contexts;
    this.is_form_associated = is_form_associated;
    this.on_form_autofill = on_form_autofill;
    this.on_form_reset = on_form_reset;
    this.on_form_restore = on_form_restore;
  }
};
function new$6(options) {
  let init2 = new Config2(
    true,
    true,
    false,
    empty_list,
    empty_list,
    empty_list,
    false,
    option_none,
    option_none,
    option_none
  );
  return fold2(
    options,
    init2,
    (config, option) => {
      return option.apply(config);
    }
  );
}

// build/dev/javascript/lustre/lustre/runtime/client/spa.ffi.mjs
var Spa = class {
  #runtime;
  constructor(root3, [init2, effects], update4, view2) {
    this.#runtime = new Runtime(root3, [init2, effects], view2, update4);
  }
  send(message) {
    switch (message.constructor) {
      case EffectDispatchedMessage: {
        this.dispatch(message.message, false);
        break;
      }
      case EffectEmitEvent: {
        this.emit(message.name, message.data);
        break;
      }
      case SystemRequestedShutdown:
        break;
    }
  }
  dispatch(msg, immediate) {
    this.#runtime.dispatch(msg, immediate);
  }
  emit(event4, data) {
    this.#runtime.emit(event4, data);
  }
};
var start = ({ init: init2, update: update4, view: view2 }, selector, flags) => {
  if (!is_browser()) return new Error2(new NotABrowser());
  const root3 = selector instanceof HTMLElement ? selector : document().querySelector(selector);
  if (!root3) return new Error2(new ElementNotFound(selector));
  return new Ok(new Spa(root3, init2(flags), update4, view2));
};

// build/dev/javascript/lustre/lustre.mjs
var App = class extends CustomType {
  constructor(init2, update4, view2, config) {
    super();
    this.init = init2;
    this.update = update4;
    this.view = view2;
    this.config = config;
  }
};
var ElementNotFound = class extends CustomType {
  constructor(selector) {
    super();
    this.selector = selector;
  }
};
var NotABrowser = class extends CustomType {
};
function application(init2, update4, view2) {
  return new App(init2, update4, view2, new$6(empty_list));
}
function simple(init2, update4, view2) {
  let init$1 = (start_args) => {
    return [init2(start_args), none()];
  };
  let update$1 = (model, msg) => {
    return [update4(model, msg), none()];
  };
  return application(init$1, update$1, view2);
}
function start3(app, selector, start_args) {
  return guard(
    !is_browser(),
    new Error2(new NotABrowser()),
    () => {
      return start(app, selector, start_args);
    }
  );
}

// build/dev/javascript/gleam_stdlib/gleam/pair.mjs
function first2(pair2) {
  let a2;
  a2 = pair2[0];
  return a2;
}
function second(pair2) {
  let a2;
  a2 = pair2[1];
  return a2;
}
function swap(pair2) {
  let a2;
  let b;
  a2 = pair2[0];
  b = pair2[1];
  return [b, a2];
}

// build/dev/javascript/lustre/lustre/event.mjs
function is_immediate_event(name) {
  if (name === "input") {
    return true;
  } else if (name === "change") {
    return true;
  } else if (name === "focus") {
    return true;
  } else if (name === "focusin") {
    return true;
  } else if (name === "focusout") {
    return true;
  } else if (name === "blur") {
    return true;
  } else if (name === "select") {
    return true;
  } else {
    return false;
  }
}
function on(name, handler) {
  return event(
    name,
    map2(handler, (msg) => {
      return new Handler(false, false, msg);
    }),
    empty_list,
    never,
    never,
    is_immediate_event(name),
    0,
    0
  );
}
function on_click(msg) {
  return on("click", success(msg));
}
function on_change(msg) {
  return on(
    "change",
    subfield(
      toList(["target", "value"]),
      string2,
      (value) => {
        return success(msg(value));
      }
    )
  );
}

// build/dev/javascript/eoc/runtime_ffi.mjs
function read_int() {
  return 0;
}

// build/dev/javascript/eoc/eoc/langs/l_while.mjs
var FILEPATH = "src/eoc/langs/l_while.gleam";
var IntegerT = class extends CustomType {
};
var BooleanT = class extends CustomType {
};
var VoidT = class extends CustomType {
};
var TypeError2 = class extends CustomType {
  constructor(expected, actual, expression2) {
    super();
    this.expected = expected;
    this.actual = actual;
    this.expression = expression2;
  }
};
var UnboundVariable = class extends CustomType {
  constructor(name) {
    super();
    this.name = name;
  }
};
var Eq2 = class extends CustomType {
};
var Lt2 = class extends CustomType {
};
var Lte = class extends CustomType {
};
var Gt2 = class extends CustomType {
};
var Gte = class extends CustomType {
};
var Read = class extends CustomType {
};
var Void = class extends CustomType {
};
var Negate = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Plus = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Minus = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Cmp = class extends CustomType {
  constructor(op, a2, b) {
    super();
    this.op = op;
    this.a = a2;
    this.b = b;
  }
};
var And = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Or = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Not = class extends CustomType {
  constructor(a2) {
    super();
    this.a = a2;
  }
};
var Int = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Bool = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Prim = class extends CustomType {
  constructor(op) {
    super();
    this.op = op;
  }
};
var Var = class extends CustomType {
  constructor(name) {
    super();
    this.name = name;
  }
};
var Let = class extends CustomType {
  constructor(var$2, binding, expr) {
    super();
    this.var = var$2;
    this.binding = binding;
    this.expr = expr;
  }
};
var If = class extends CustomType {
  constructor(condition, if_true, if_false) {
    super();
    this.condition = condition;
    this.if_true = if_true;
    this.if_false = if_false;
  }
};
var SetBang = class extends CustomType {
  constructor(var$2, value) {
    super();
    this.var = var$2;
    this.value = value;
  }
};
var Begin = class extends CustomType {
  constructor(stmts, result) {
    super();
    this.stmts = stmts;
    this.result = result;
  }
};
var WhileLoop = class extends CustomType {
  constructor(condition, body) {
    super();
    this.condition = condition;
    this.body = body;
  }
};
var Program = class extends CustomType {
  constructor(body) {
    super();
    this.body = body;
  }
};
var IntValue = class extends CustomType {
  constructor(v) {
    super();
    this.v = v;
  }
};
var BoolValue = class extends CustomType {
  constructor(v) {
    super();
    this.v = v;
  }
};
var VoidValue = class extends CustomType {
};
function get_var(env, name) {
  let $ = map_get(env, name);
  if ($ instanceof Ok) {
    let i = $[0];
    return i;
  } else {
    throw makeError(
      "panic",
      FILEPATH,
      "eoc/langs/l_while",
      182,
      "get_var",
      "referenced unknown variable",
      {}
    );
  }
}
function check_type_equal(a2, b, e) {
  let $ = isEqual(a2, b);
  if ($) {
    return new Ok(void 0);
  } else {
    return new Error2(new TypeError2(a2, b, e));
  }
}
function type_check_op(p, env) {
  if (p instanceof Read) {
    return new Ok([new Read(), new IntegerT()]);
  } else if (p instanceof Void) {
    return new Ok([new Void(), new VoidT()]);
  } else if (p instanceof Negate) {
    let e = p.value;
    return try$(
      type_check_exp(e, env),
      (_use0) => {
        let e1;
        let te;
        e1 = _use0[0];
        te = _use0[1];
        return map3(
          check_type_equal(new BooleanT(), te, e1),
          (_) => {
            return [new Negate(e1), new BooleanT()];
          }
        );
      }
    );
  } else if (p instanceof Plus) {
    let a2 = p.a;
    let b = p.b;
    return try$(
      type_check_exp(a2, env),
      (_use0) => {
        let a1;
        let ta;
        a1 = _use0[0];
        ta = _use0[1];
        return try$(
          check_type_equal(new IntegerT(), ta, a1),
          (_) => {
            return try$(
              type_check_exp(b, env),
              (_use02) => {
                let b1;
                let tb;
                b1 = _use02[0];
                tb = _use02[1];
                return map3(
                  check_type_equal(new IntegerT(), tb, b1),
                  (_2) => {
                    return [new Plus(a1, b1), new IntegerT()];
                  }
                );
              }
            );
          }
        );
      }
    );
  } else if (p instanceof Minus) {
    let a2 = p.a;
    let b = p.b;
    return try$(
      type_check_exp(a2, env),
      (_use0) => {
        let a1;
        let ta;
        a1 = _use0[0];
        ta = _use0[1];
        return try$(
          check_type_equal(new IntegerT(), ta, a1),
          (_) => {
            return try$(
              type_check_exp(b, env),
              (_use02) => {
                let b1;
                let tb;
                b1 = _use02[0];
                tb = _use02[1];
                return map3(
                  check_type_equal(new IntegerT(), tb, b1),
                  (_2) => {
                    return [new Minus(a1, b1), new IntegerT()];
                  }
                );
              }
            );
          }
        );
      }
    );
  } else if (p instanceof Cmp) {
    let $ = p.op;
    if ($ instanceof Eq2) {
      let a2 = p.a;
      let b = p.b;
      return try$(
        type_check_exp(a2, env),
        (_use0) => {
          let a1;
          let ta;
          a1 = _use0[0];
          ta = _use0[1];
          return try$(
            type_check_exp(b, env),
            (_use02) => {
              let b1;
              let tb;
              b1 = _use02[0];
              tb = _use02[1];
              return map3(
                check_type_equal(ta, tb, b1),
                (_) => {
                  return [new Cmp(new Eq2(), a1, b1), new BooleanT()];
                }
              );
            }
          );
        }
      );
    } else {
      let op = $;
      let a2 = p.a;
      let b = p.b;
      return try$(
        type_check_exp(a2, env),
        (_use0) => {
          let a1;
          let ta;
          a1 = _use0[0];
          ta = _use0[1];
          return try$(
            check_type_equal(new IntegerT(), ta, a1),
            (_) => {
              return try$(
                type_check_exp(b, env),
                (_use02) => {
                  let b1;
                  let tb;
                  b1 = _use02[0];
                  tb = _use02[1];
                  return map3(
                    check_type_equal(new IntegerT(), tb, b1),
                    (_2) => {
                      return [new Cmp(op, a1, b1), new BooleanT()];
                    }
                  );
                }
              );
            }
          );
        }
      );
    }
  } else if (p instanceof And) {
    let a2 = p.a;
    let b = p.b;
    return try$(
      type_check_exp(a2, env),
      (_use0) => {
        let a1;
        let ta;
        a1 = _use0[0];
        ta = _use0[1];
        return try$(
          check_type_equal(new BooleanT(), ta, a1),
          (_) => {
            return try$(
              type_check_exp(b, env),
              (_use02) => {
                let b1;
                let tb;
                b1 = _use02[0];
                tb = _use02[1];
                return map3(
                  check_type_equal(new BooleanT(), tb, b1),
                  (_2) => {
                    return [new And(a1, b1), new BooleanT()];
                  }
                );
              }
            );
          }
        );
      }
    );
  } else if (p instanceof Or) {
    let a2 = p.a;
    let b = p.b;
    return try$(
      type_check_exp(a2, env),
      (_use0) => {
        let a1;
        let ta;
        a1 = _use0[0];
        ta = _use0[1];
        return try$(
          check_type_equal(new BooleanT(), ta, a1),
          (_) => {
            return try$(
              type_check_exp(b, env),
              (_use02) => {
                let b1;
                let tb;
                b1 = _use02[0];
                tb = _use02[1];
                return map3(
                  check_type_equal(new BooleanT(), tb, b1),
                  (_2) => {
                    return [new Or(a1, b1), new BooleanT()];
                  }
                );
              }
            );
          }
        );
      }
    );
  } else {
    let e = p.a;
    return try$(
      type_check_exp(e, env),
      (_use0) => {
        let e1;
        let te;
        e1 = _use0[0];
        te = _use0[1];
        return map3(
          check_type_equal(new BooleanT(), te, e1),
          (_) => {
            return [new Not(e1), new BooleanT()];
          }
        );
      }
    );
  }
}
function type_check_exp(e, env) {
  if (e instanceof Int) {
    return new Ok([e, new IntegerT()]);
  } else if (e instanceof Bool) {
    return new Ok([e, new BooleanT()]);
  } else if (e instanceof Prim) {
    let p = e.op;
    return map3(
      type_check_op(p, env),
      (_use0) => {
        let op;
        let t;
        op = _use0[0];
        t = _use0[1];
        return [new Prim(op), t];
      }
    );
  } else if (e instanceof Var) {
    let v = e.name;
    let $ = map_get(env, v);
    if ($ instanceof Ok) {
      let t = $[0];
      return new Ok([e, t]);
    } else {
      return new Error2(new UnboundVariable(v));
    }
  } else if (e instanceof Let) {
    let x = e.var;
    let e$1 = e.binding;
    let body = e.expr;
    return try$(
      type_check_exp(e$1, env),
      (_use0) => {
        let e1;
        let t;
        e1 = _use0[0];
        t = _use0[1];
        return map3(
          type_check_exp(body, insert(env, x, t)),
          (_use02) => {
            let body1;
            let tb;
            body1 = _use02[0];
            tb = _use02[1];
            return [new Let(x, e1, body1), tb];
          }
        );
      }
    );
  } else if (e instanceof If) {
    let cond = e.condition;
    let thn = e.if_true;
    let els = e.if_false;
    return try$(
      type_check_exp(cond, env),
      (_use0) => {
        let c1;
        let tc;
        c1 = _use0[0];
        tc = _use0[1];
        return try$(
          check_type_equal(new BooleanT(), tc, c1),
          (_) => {
            return try$(
              type_check_exp(thn, env),
              (_use02) => {
                let t1;
                let tt;
                t1 = _use02[0];
                tt = _use02[1];
                return try$(
                  type_check_exp(els, env),
                  (_use03) => {
                    let e1;
                    let te;
                    e1 = _use03[0];
                    te = _use03[1];
                    return map3(
                      check_type_equal(tt, te, e1),
                      (_2) => {
                        return [new If(c1, t1, e1), te];
                      }
                    );
                  }
                );
              }
            );
          }
        );
      }
    );
  } else if (e instanceof SetBang) {
    let var$2 = e.var;
    let value = e.value;
    return try$(
      type_check_exp(value, env),
      (_use0) => {
        let v1;
        let tval;
        v1 = _use0[0];
        tval = _use0[1];
        return try$(
          type_check_exp(new Var(var$2), env),
          (_use02) => {
            let tvar;
            tvar = _use02[1];
            return map3(
              check_type_equal(tvar, tval, new SetBang(var$2, v1)),
              (_) => {
                return [new SetBang(var$2, v1), new VoidT()];
              }
            );
          }
        );
      }
    );
  } else if (e instanceof Begin) {
    let stmts = e.stmts;
    let result = e.result;
    let _block;
    let _pipe = stmts;
    let _pipe$1 = reverse(_pipe);
    _block = fold_until(
      _pipe$1,
      new Ok(toList([])),
      (acc, stmt) => {
        let $ = type_check_exp(stmt, env);
        if ($ instanceof Ok) {
          let s1 = $[0][0];
          return new Continue(
            map3(acc, (l) => {
              return prepend(s1, l);
            })
          );
        } else {
          let e$1 = $[0];
          return new Stop(new Error2(e$1));
        }
      }
    );
    let stmts$1 = _block;
    return try$(
      stmts$1,
      (s2) => {
        return map3(
          type_check_exp(result, env),
          (_use0) => {
            let r1;
            let tr;
            r1 = _use0[0];
            tr = _use0[1];
            return [new Begin(s2, r1), tr];
          }
        );
      }
    );
  } else {
    let condition = e.condition;
    let body = e.body;
    return try$(
      type_check_exp(condition, env),
      (_use0) => {
        let c1;
        let tc;
        c1 = _use0[0];
        tc = _use0[1];
        return try$(
          check_type_equal(new BooleanT(), tc, c1),
          (_) => {
            return map3(
              type_check_exp(body, env),
              (_use02) => {
                let b1;
                b1 = _use02[0];
                return [new WhileLoop(c1, b1), new VoidT()];
              }
            );
          }
        );
      }
    );
  }
}
function type_check_program(p) {
  let $ = type_check_exp(p.body, new_map());
  if ($ instanceof Ok) {
    let $1 = $[0][1];
    if ($1 instanceof IntegerT) {
      let expr = $[0][0];
      return new Ok(new Program(expr));
    } else if ($1 instanceof BooleanT) {
      let expr = $[0][0];
      return new Error2(new TypeError2(new IntegerT(), new BooleanT(), expr));
    } else {
      let expr = $[0][0];
      return new Error2(new TypeError2(new IntegerT(), new VoidT(), expr));
    }
  } else {
    return $;
  }
}
function interpret_op(op, env) {
  if (op instanceof Read) {
    return [new IntValue(read_int()), env];
  } else if (op instanceof Void) {
    return [new VoidValue(), env];
  } else if (op instanceof Negate) {
    let v = op.value;
    let $ = interpret_exp(v, env);
    let i;
    let e1;
    let $1 = $[0];
    if ($1 instanceof IntValue) {
      e1 = $[1];
      i = $1.v;
    } else {
      throw makeError(
        "let_assert",
        FILEPATH,
        "eoc/langs/l_while",
        112,
        "interpret_op",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $,
          start: 2513,
          end: 2566,
          pattern_start: 2524,
          pattern_end: 2542
        }
      );
    }
    return [new IntValue(-i), e1];
  } else if (op instanceof Plus) {
    let a2 = op.a;
    let b = op.b;
    let $ = interpret_exp(a2, env);
    let av;
    let e1;
    let $1 = $[0];
    if ($1 instanceof IntValue) {
      e1 = $[1];
      av = $1.v;
    } else {
      throw makeError(
        "let_assert",
        FILEPATH,
        "eoc/langs/l_while",
        121,
        "interpret_op",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $,
          start: 2804,
          end: 2858,
          pattern_start: 2815,
          pattern_end: 2834
        }
      );
    }
    let $2 = interpret_exp(b, e1);
    let bv;
    let e2;
    let $3 = $2[0];
    if ($3 instanceof IntValue) {
      e2 = $2[1];
      bv = $3.v;
    } else {
      throw makeError(
        "let_assert",
        FILEPATH,
        "eoc/langs/l_while",
        122,
        "interpret_op",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $2,
          start: 2865,
          end: 2918,
          pattern_start: 2876,
          pattern_end: 2895
        }
      );
    }
    return [new IntValue(av + bv), e2];
  } else if (op instanceof Minus) {
    let a2 = op.a;
    let b = op.b;
    let $ = interpret_exp(a2, env);
    let av;
    let e1;
    let $1 = $[0];
    if ($1 instanceof IntValue) {
      e1 = $[1];
      av = $1.v;
    } else {
      throw makeError(
        "let_assert",
        FILEPATH,
        "eoc/langs/l_while",
        116,
        "interpret_op",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $,
          start: 2626,
          end: 2680,
          pattern_start: 2637,
          pattern_end: 2656
        }
      );
    }
    let $2 = interpret_exp(b, e1);
    let bv;
    let e2;
    let $3 = $2[0];
    if ($3 instanceof IntValue) {
      e2 = $2[1];
      bv = $3.v;
    } else {
      throw makeError(
        "let_assert",
        FILEPATH,
        "eoc/langs/l_while",
        117,
        "interpret_op",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $2,
          start: 2687,
          end: 2740,
          pattern_start: 2698,
          pattern_end: 2717
        }
      );
    }
    return [new IntValue(av - bv), e2];
  } else if (op instanceof Cmp) {
    let $ = op.op;
    if ($ instanceof Eq2) {
      let a2 = op.a;
      let b = op.b;
      let $1 = interpret_exp(a2, env);
      let av;
      let e1;
      av = $1[0];
      e1 = $1[1];
      let $2 = interpret_exp(b, e1);
      let bv;
      let e2;
      bv = $2[0];
      e2 = $2[1];
      if (bv instanceof IntValue) {
        if (av instanceof IntValue) {
          let bi = bv.v;
          let ai = av.v;
          return [new BoolValue(ai === bi), e2];
        } else {
          throw makeError(
            "panic",
            FILEPATH,
            "eoc/langs/l_while",
            159,
            "interpret_op",
            "mismatched types in eq? expression",
            {}
          );
        }
      } else if (bv instanceof BoolValue) {
        if (av instanceof BoolValue) {
          let bb = bv.v;
          let ab = av.v;
          return [new BoolValue(ab === bb), e2];
        } else {
          throw makeError(
            "panic",
            FILEPATH,
            "eoc/langs/l_while",
            159,
            "interpret_op",
            "mismatched types in eq? expression",
            {}
          );
        }
      } else if (av instanceof VoidValue) {
        return [new BoolValue(true), e2];
      } else {
        throw makeError(
          "panic",
          FILEPATH,
          "eoc/langs/l_while",
          159,
          "interpret_op",
          "mismatched types in eq? expression",
          {}
        );
      }
    } else {
      let op$1 = $;
      let a2 = op.a;
      let b = op.b;
      let $1 = interpret_exp(a2, env);
      let av;
      let e1;
      let $2 = $1[0];
      if ($2 instanceof IntValue) {
        e1 = $1[1];
        av = $2.v;
      } else {
        throw makeError(
          "let_assert",
          FILEPATH,
          "eoc/langs/l_while",
          163,
          "interpret_op",
          "Pattern match failed, no pattern matched the value.",
          {
            value: $1,
            start: 4226,
            end: 4280,
            pattern_start: 4237,
            pattern_end: 4256
          }
        );
      }
      let $3 = interpret_exp(b, e1);
      let bv;
      let e2;
      let $4 = $3[0];
      if ($4 instanceof IntValue) {
        e2 = $3[1];
        bv = $4.v;
      } else {
        throw makeError(
          "let_assert",
          FILEPATH,
          "eoc/langs/l_while",
          164,
          "interpret_op",
          "Pattern match failed, no pattern matched the value.",
          {
            value: $3,
            start: 4287,
            end: 4340,
            pattern_start: 4298,
            pattern_end: 4317
          }
        );
      }
      return [
        (() => {
          if (op$1 instanceof Eq2) {
            throw makeError(
              "panic",
              FILEPATH,
              "eoc/langs/l_while",
              171,
              "interpret_op",
              "unreachable branch",
              {}
            );
          } else if (op$1 instanceof Lt2) {
            return new BoolValue(av < bv);
          } else if (op$1 instanceof Lte) {
            return new BoolValue(av <= bv);
          } else if (op$1 instanceof Gt2) {
            return new BoolValue(av > bv);
          } else {
            return new BoolValue(av >= bv);
          }
        })(),
        e2
      ];
    }
  } else if (op instanceof And) {
    let a2 = op.a;
    let b = op.b;
    let $ = interpret_exp(a2, env);
    let $1 = $[0];
    if ($1 instanceof BoolValue) {
      let $2 = $1.v;
      if ($2) {
        let e1 = $[1];
        let $3 = interpret_exp(b, e1);
        let bv;
        let e2;
        let $4 = $3[0];
        if ($4 instanceof BoolValue) {
          e2 = $3[1];
          bv = $4.v;
        } else {
          throw makeError(
            "let_assert",
            FILEPATH,
            "eoc/langs/l_while",
            129,
            "interpret_op",
            "Pattern match failed, no pattern matched the value.",
            {
              value: $3,
              start: 3105,
              end: 3159,
              pattern_start: 3116,
              pattern_end: 3136
            }
          );
        }
        return [new BoolValue(bv), e2];
      } else {
        return $;
      }
    } else {
      throw makeError(
        "panic",
        FILEPATH,
        "eoc/langs/l_while",
        135,
        "interpret_op",
        "non-boolean expression not valid in `and`",
        {}
      );
    }
  } else if (op instanceof Or) {
    let a2 = op.a;
    let b = op.b;
    let $ = interpret_exp(a2, env);
    let $1 = $[0];
    if ($1 instanceof BoolValue) {
      let $2 = $1.v;
      if ($2) {
        return $;
      } else {
        let e1 = $[1];
        let $3 = interpret_exp(b, e1);
        let bv;
        let e2;
        let $4 = $3[0];
        if ($4 instanceof BoolValue) {
          e2 = $3[1];
          bv = $4.v;
        } else {
          throw makeError(
            "let_assert",
            FILEPATH,
            "eoc/langs/l_while",
            142,
            "interpret_op",
            "Pattern match failed, no pattern matched the value.",
            {
              value: $3,
              start: 3519,
              end: 3573,
              pattern_start: 3530,
              pattern_end: 3550
            }
          );
        }
        return [new BoolValue(bv), e2];
      }
    } else {
      throw makeError(
        "panic",
        FILEPATH,
        "eoc/langs/l_while",
        145,
        "interpret_op",
        "non-boolean expression not valid in `or`",
        {}
      );
    }
  } else {
    let e = op.a;
    let $ = interpret_exp(e, env);
    let v;
    let e1;
    let $1 = $[0];
    if ($1 instanceof BoolValue) {
      e1 = $[1];
      v = $1.v;
    } else {
      throw makeError(
        "let_assert",
        FILEPATH,
        "eoc/langs/l_while",
        149,
        "interpret_op",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $,
          start: 3716,
          end: 3770,
          pattern_start: 3727,
          pattern_end: 3746
        }
      );
    }
    return [new BoolValue(!v), e1];
  }
}
function interpret_exp(loop$e, loop$env) {
  while (true) {
    let e = loop$e;
    let env = loop$env;
    if (e instanceof Int) {
      let value = e.value;
      return [new IntValue(value), env];
    } else if (e instanceof Bool) {
      let value = e.value;
      return [new BoolValue(value), env];
    } else if (e instanceof Prim) {
      let op = e.op;
      return interpret_op(op, env);
    } else if (e instanceof Var) {
      let name = e.name;
      return [get_var(env, name), env];
    } else if (e instanceof Let) {
      let var$2 = e.var;
      let binding = e.binding;
      let expr = e.expr;
      let $ = interpret_exp(binding, env);
      let result;
      let env1;
      result = $[0];
      env1 = $[1];
      let new_env = insert(env1, var$2, result);
      loop$e = expr;
      loop$env = new_env;
    } else if (e instanceof If) {
      let c = e.condition;
      let t = e.if_true;
      let e$1 = e.if_false;
      let $ = interpret_exp(c, env);
      let $1 = $[0];
      if ($1 instanceof BoolValue) {
        let $2 = $1.v;
        if ($2) {
          let new_env = $[1];
          loop$e = t;
          loop$env = new_env;
        } else {
          let new_env = $[1];
          loop$e = e$1;
          loop$env = new_env;
        }
      } else {
        throw makeError(
          "panic",
          FILEPATH,
          "eoc/langs/l_while",
          81,
          "interpret_exp",
          "invalid boolean expression",
          {}
        );
      }
    } else if (e instanceof SetBang) {
      let var$2 = e.var;
      let value = e.value;
      let $ = interpret_exp(value, env);
      let result;
      let env1;
      result = $[0];
      env1 = $[1];
      return [new VoidValue(), insert(env1, var$2, result)];
    } else if (e instanceof Begin) {
      let stmts = e.stmts;
      let result = e.result;
      let env1 = fold2(
        stmts,
        env,
        (acc, stmt) => {
          let $ = interpret_exp(stmt, acc);
          let env12;
          env12 = $[1];
          return env12;
        }
      );
      loop$e = result;
      loop$env = env1;
    } else {
      let condition = e.condition;
      let body = e.body;
      let $ = interpret_exp(condition, env);
      let $1 = $[0];
      if ($1 instanceof BoolValue) {
        let $2 = $1.v;
        if ($2) {
          let e$1 = $[1];
          let $3 = interpret_exp(body, e$1);
          let e2;
          e2 = $3[1];
          loop$e = new WhileLoop(condition, body);
          loop$env = e2;
        } else {
          let e$1 = $[1];
          return [new VoidValue(), e$1];
        }
      } else {
        throw makeError(
          "panic",
          FILEPATH,
          "eoc/langs/l_while",
          103,
          "interpret_exp",
          "invalid boolean expression",
          {}
        );
      }
    }
  }
}
function interpret(p) {
  return interpret_exp(p.body, new_map())[0];
}

// build/dev/javascript/eoc/eoc/graph.mjs
var Graph = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var Node = class extends CustomType {
  constructor(id, value) {
    super();
    this.id = id;
    this.value = value;
  }
};
var Context = class extends CustomType {
  constructor(edges, node) {
    super();
    this.edges = edges;
    this.node = node;
  }
};
function new$8() {
  return new Graph(new_map());
}
function nodes(graph) {
  let graph$1;
  graph$1 = graph[0];
  return fold(
    graph$1,
    toList([]),
    (acc, _, _use2) => {
      let node;
      node = _use2.node;
      return prepend(node, acc);
    }
  );
}
function has_node(graph, node_id) {
  let graph$1;
  graph$1 = graph[0];
  return has_key(graph$1, node_id);
}
function get_context(graph, node) {
  let graph$1;
  graph$1 = graph[0];
  return map_get(graph$1, node);
}
function insert_node(graph, node) {
  let graph$1;
  graph$1 = graph[0];
  let empty_context = new Context(new_map(), node);
  let new_graph = insert(graph$1, node.id, empty_context);
  return new Graph(new_graph);
}
function update_context(graph, node, fun) {
  let graph$1;
  graph$1 = graph[0];
  let $ = map_get(graph$1, node);
  if ($ instanceof Ok) {
    let context = $[0];
    return new Graph(insert(graph$1, node, fun(context)));
  } else {
    return new Graph(graph$1);
  }
}
function add_edge(context, node, label) {
  let edges;
  edges = context.edges;
  return new Context(insert(edges, node, label), context.node);
}
function insert_edge(graph, label, one, other) {
  let _pipe = graph;
  let _pipe$1 = update_context(
    _pipe,
    one,
    (_capture) => {
      return add_edge(_capture, other, label);
    }
  );
  return update_context(
    _pipe$1,
    other,
    (_capture) => {
      return add_edge(_capture, one, label);
    }
  );
}
function insert_context(graph, context) {
  let graph$1;
  graph$1 = graph[0];
  let new_graph = insert(graph$1, context.node.id, context);
  return new Graph(new_graph);
}
function modify_value(graph, node_id, fun) {
  let $ = get_context(graph, node_id);
  if ($ instanceof Ok) {
    let context = $[0];
    let new_value = fun(context.node.value);
    return insert_context(
      graph,
      new Context(
        context.edges,
        (() => {
          let _record = context.node;
          return new Node(_record.id, new_value);
        })()
      )
    );
  } else {
    return graph;
  }
}
function dict_map_shared_keys(one, other, fun) {
  return fold(
    other,
    one,
    (one2, key, other_value) => {
      let $ = map_get(one2, key);
      if ($ instanceof Ok) {
        let one_value = $[0];
        return insert(one2, key, fun(one_value, other_value));
      } else {
        return one2;
      }
    }
  );
}
function remove_occurrences(graph, node, nodes2) {
  return dict_map_shared_keys(
    graph,
    nodes2,
    (context, _) => {
      let edges;
      edges = context.edges;
      return new Context(delete$(edges, node), context.node);
    }
  );
}
function remove_node(graph, node_id) {
  let $ = get_context(graph, node_id);
  if ($ instanceof Ok) {
    let edges = $[0].edges;
    let graph$1 = graph[0];
    let _pipe = delete$(graph$1, node_id);
    let _pipe$1 = remove_occurrences(_pipe, node_id, edges);
    return new Graph(_pipe$1);
  } else {
    return graph;
  }
}
function match(graph, node_id) {
  return try$(
    get_context(graph, node_id),
    (_use0) => {
      let edges;
      let node;
      edges = _use0.edges;
      node = _use0.node;
      let rest = remove_node(graph, node_id);
      let new_edges = delete$(edges, node_id);
      return new Ok([new Context(new_edges, node), rest]);
    }
  );
}

// build/dev/javascript/eoc/eoc/langs/x86_base.mjs
var Rsp = class extends CustomType {
};
var Rbp = class extends CustomType {
};
var Rax = class extends CustomType {
};
var Rbx = class extends CustomType {
};
var Rcx = class extends CustomType {
};
var Rdx = class extends CustomType {
};
var Rsi = class extends CustomType {
};
var Rdi = class extends CustomType {
};
var R8 = class extends CustomType {
};
var R9 = class extends CustomType {
};
var R10 = class extends CustomType {
};
var R11 = class extends CustomType {
};
var R12 = class extends CustomType {
};
var R13 = class extends CustomType {
};
var R14 = class extends CustomType {
};
var R15 = class extends CustomType {
};
var Ah = class extends CustomType {
};
var Al = class extends CustomType {
};
var Bh = class extends CustomType {
};
var Bl = class extends CustomType {
};
var Ch = class extends CustomType {
};
var Cl = class extends CustomType {
};
var Dh = class extends CustomType {
};
var E = class extends CustomType {
};
var L = class extends CustomType {
};
var Le = class extends CustomType {
};
var G = class extends CustomType {
};
var Ge = class extends CustomType {
};
var LocReg = class extends CustomType {
  constructor(reg) {
    super();
    this.reg = reg;
  }
};
var LocVar = class extends CustomType {
  constructor(name) {
    super();
    this.name = name;
  }
};
function is_callee_saved(reg) {
  if (reg instanceof Rsp) {
    return true;
  } else if (reg instanceof Rbp) {
    return true;
  } else if (reg instanceof Rbx) {
    return true;
  } else if (reg instanceof R12) {
    return true;
  } else if (reg instanceof R13) {
    return true;
  } else if (reg instanceof R14) {
    return true;
  } else if (reg instanceof R15) {
    return true;
  } else {
    return false;
  }
}
function register_to_rank(r) {
  if (r instanceof Rsp) {
    return -2;
  } else if (r instanceof Rbp) {
    return -3;
  } else if (r instanceof Rax) {
    return -1;
  } else if (r instanceof Rbx) {
    return 7;
  } else if (r instanceof Rcx) {
    return 0;
  } else if (r instanceof Rdx) {
    return 1;
  } else if (r instanceof Rsi) {
    return 2;
  } else if (r instanceof Rdi) {
    return 3;
  } else if (r instanceof R8) {
    return 4;
  } else if (r instanceof R9) {
    return 5;
  } else if (r instanceof R10) {
    return 6;
  } else if (r instanceof R11) {
    return -4;
  } else if (r instanceof R12) {
    return 8;
  } else if (r instanceof R13) {
    return 9;
  } else if (r instanceof R14) {
    return 10;
  } else {
    return -5;
  }
}
function compare_location(a2, b) {
  if (b instanceof LocReg) {
    if (a2 instanceof LocReg) {
      let r2 = b.reg;
      let r1 = a2.reg;
      return compare(register_to_rank(r1), register_to_rank(r2));
    } else {
      return new Gt();
    }
  } else if (a2 instanceof LocReg) {
    return new Lt();
  } else {
    let v2 = b.name;
    let v1 = a2.name;
    return compare2(v1, v2);
  }
}
function bytereg_to_quad(br) {
  if (br instanceof Ah) {
    return new Rax();
  } else if (br instanceof Al) {
    return new Rax();
  } else if (br instanceof Bh) {
    return new Rbx();
  } else if (br instanceof Bl) {
    return new Rbx();
  } else if (br instanceof Ch) {
    return new Rcx();
  } else if (br instanceof Cl) {
    return new Rcx();
  } else if (br instanceof Dh) {
    return new Rdx();
  } else {
    return new Rdx();
  }
}

// build/dev/javascript/eoc/eoc/interference_graph.mjs
var FILEPATH2 = "src/eoc/interference_graph.gleam";
var Node2 = class extends CustomType {
  constructor(location, assignment, saturation) {
    super();
    this.location = location;
    this.assignment = assignment;
    this.saturation = saturation;
  }
};
var Graph2 = class extends CustomType {
  constructor(graph) {
    super();
    this.graph = graph;
  }
};
function insert_location(g, location) {
  let $ = has_node(g.graph, location);
  if ($) {
    return g;
  } else {
    let _pipe = g.graph;
    let _pipe$1 = insert_node(
      _pipe,
      new Node(location, new Node2(location, new None(), new$()))
    );
    return new Graph2(_pipe$1);
  }
}
function add_locations(g, locations) {
  return fold3(locations, g, insert_location);
}
function add_conflict(g, a2, b) {
  let $ = isEqual(a2, b);
  if ($) {
    return g;
  } else {
    let $1 = get_context(g.graph, a2);
    let a_context;
    if ($1 instanceof Ok) {
      a_context = $1[0];
    } else {
      throw makeError(
        "let_assert",
        FILEPATH2,
        "eoc/interference_graph",
        45,
        "add_conflict",
        "Pattern match failed, no pattern matched the value.",
        { value: $1, start: 931, end: 987, pattern_start: 942, pattern_end: 955 }
      );
    }
    let $2 = get_context(g.graph, b);
    let b_context;
    if ($2 instanceof Ok) {
      b_context = $2[0];
    } else {
      throw makeError(
        "let_assert",
        FILEPATH2,
        "eoc/interference_graph",
        46,
        "add_conflict",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $2,
          start: 994,
          end: 1050,
          pattern_start: 1005,
          pattern_end: 1018
        }
      );
    }
    let _pipe = g.graph;
    let _pipe$1 = insert_edge(_pipe, void 0, a2, b);
    let _pipe$2 = modify_value(
      _pipe$1,
      a2,
      (node) => {
        let $3 = b_context.node.value.assignment;
        if ($3 instanceof Some) {
          let i = $3[0];
          return new Node2(
            node.location,
            node.assignment,
            insert2(node.saturation, i)
          );
        } else {
          return node;
        }
      }
    );
    let _pipe$3 = modify_value(
      _pipe$2,
      b,
      (node) => {
        let $3 = a_context.node.value.assignment;
        if ($3 instanceof Some) {
          let i = $3[0];
          return new Node2(
            node.location,
            node.assignment,
            insert2(node.saturation, i)
          );
        } else {
          return node;
        }
      }
    );
    return new Graph2(_pipe$3);
  }
}
function add_registers(g) {
  let _pipe = toList([
    [new Rax(), -1],
    [new Rsp(), -2],
    [new Rbp(), -3],
    [new R11(), -4],
    [new R15(), -5],
    [new Rcx(), 0],
    [new Rdx(), 1],
    [new Rsi(), 2],
    [new Rdi(), 3],
    [new R8(), 4],
    [new R9(), 5],
    [new R10(), 6],
    [new Rbx(), 7],
    [new R12(), 8],
    [new R13(), 9],
    [new R14(), 10]
  ]);
  let _pipe$1 = map(
    _pipe,
    (pair2) => {
      let reg;
      let color;
      reg = pair2[0];
      color = pair2[1];
      let location = new LocReg(reg);
      return new Node(
        location,
        new Node2(location, new Some(color), new$())
      );
    }
  );
  let _pipe$2 = fold2(_pipe$1, g.graph, insert_node);
  return new Graph2(_pipe$2);
}
function new$9() {
  let _pipe = new Graph2(new$8());
  return add_registers(_pipe);
}

// build/dev/javascript/eoc/eoc/langs/x86_if.mjs
var Imm = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Reg = class extends CustomType {
  constructor(reg) {
    super();
    this.reg = reg;
  }
};
var Deref = class extends CustomType {
  constructor(reg, offset) {
    super();
    this.reg = reg;
    this.offset = offset;
  }
};
var Addq = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Subq = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Negq = class extends CustomType {
  constructor(a2) {
    super();
    this.a = a2;
  }
};
var Movq = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Pushq = class extends CustomType {
  constructor(a2) {
    super();
    this.a = a2;
  }
};
var Popq = class extends CustomType {
  constructor(a2) {
    super();
    this.a = a2;
  }
};
var Callq = class extends CustomType {
  constructor(label, arity) {
    super();
    this.label = label;
    this.arity = arity;
  }
};
var Retq = class extends CustomType {
};
var Jmp = class extends CustomType {
  constructor(label) {
    super();
    this.label = label;
  }
};
var Xorq = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Cmpq = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Set3 = class extends CustomType {
  constructor(cmp, arg) {
    super();
    this.cmp = cmp;
    this.arg = arg;
  }
};
var Movzbq = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var JmpIf = class extends CustomType {
  constructor(cmp, label) {
    super();
    this.cmp = cmp;
    this.label = label;
  }
};
var Block = class extends CustomType {
  constructor(body) {
    super();
    this.body = body;
  }
};
var X86Program = class extends CustomType {
  constructor(body, stack_vars, used_callee) {
    super();
    this.body = body;
    this.stack_vars = stack_vars;
    this.used_callee = used_callee;
  }
};

// build/dev/javascript/eoc/eoc/langs/x86_var_if.mjs
var Imm2 = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Reg2 = class extends CustomType {
  constructor(reg) {
    super();
    this.reg = reg;
  }
};
var Var2 = class extends CustomType {
  constructor(name) {
    super();
    this.name = name;
  }
};
var Addq2 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Subq2 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Negq2 = class extends CustomType {
  constructor(a2) {
    super();
    this.a = a2;
  }
};
var Movq2 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Pushq2 = class extends CustomType {
  constructor(a2) {
    super();
    this.a = a2;
  }
};
var Popq2 = class extends CustomType {
  constructor(a2) {
    super();
    this.a = a2;
  }
};
var Callq2 = class extends CustomType {
  constructor(label, arity) {
    super();
    this.label = label;
    this.arity = arity;
  }
};
var Retq2 = class extends CustomType {
};
var Jmp2 = class extends CustomType {
  constructor(label) {
    super();
    this.label = label;
  }
};
var Xorq2 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Cmpq2 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Set4 = class extends CustomType {
  constructor(cmp, arg) {
    super();
    this.cmp = cmp;
    this.arg = arg;
  }
};
var Movzbq2 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var JmpIf2 = class extends CustomType {
  constructor(cmp, label) {
    super();
    this.cmp = cmp;
    this.label = label;
  }
};
var Block2 = class extends CustomType {
  constructor(body, live_before, live_after) {
    super();
    this.body = body;
    this.live_before = live_before;
    this.live_after = live_after;
  }
};
var X86Program2 = class extends CustomType {
  constructor(body, conflicts) {
    super();
    this.body = body;
    this.conflicts = conflicts;
  }
};
function new_program() {
  return new X86Program2(new_map(), new$9());
}
function new_block() {
  return new Block2(toList([]), new$(), toList([]));
}

// build/dev/javascript/eoc/eoc/passes/allocate_registers.mjs
var FILEPATH3 = "src/eoc/passes/allocate_registers.gleam";
function translate_location(l, assignments) {
  if (l instanceof Imm2) {
    let i = l.value;
    return new Imm(i);
  } else if (l instanceof Reg2) {
    let r = l.reg;
    return new Reg(r);
  } else {
    let v = l.name;
    let $ = map_get(assignments, new LocVar(v));
    let arg;
    if ($ instanceof Ok) {
      arg = $[0];
    } else {
      throw makeError(
        "let_assert",
        FILEPATH3,
        "eoc/passes/allocate_registers",
        105,
        "translate_location",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $,
          start: 2747,
          end: 2804,
          pattern_start: 2758,
          pattern_end: 2765
        }
      );
    }
    return arg;
  }
}
function translate_instr(instr, assignments) {
  if (instr instanceof Addq2) {
    let a2 = instr.a;
    let b = instr.b;
    return new Addq(
      translate_location(a2, assignments),
      translate_location(b, assignments)
    );
  } else if (instr instanceof Subq2) {
    let a2 = instr.a;
    let b = instr.b;
    return new Subq(
      translate_location(a2, assignments),
      translate_location(b, assignments)
    );
  } else if (instr instanceof Negq2) {
    let a2 = instr.a;
    return new Negq(translate_location(a2, assignments));
  } else if (instr instanceof Movq2) {
    let a2 = instr.a;
    let b = instr.b;
    return new Movq(
      translate_location(a2, assignments),
      translate_location(b, assignments)
    );
  } else if (instr instanceof Pushq2) {
    let a2 = instr.a;
    return new Pushq(translate_location(a2, assignments));
  } else if (instr instanceof Popq2) {
    let a2 = instr.a;
    return new Popq(translate_location(a2, assignments));
  } else if (instr instanceof Callq2) {
    let label = instr.label;
    let arity = instr.arity;
    return new Callq(label, arity);
  } else if (instr instanceof Retq2) {
    return new Retq();
  } else if (instr instanceof Jmp2) {
    let label = instr.label;
    return new Jmp(label);
  } else if (instr instanceof Xorq2) {
    let a2 = instr.a;
    let b = instr.b;
    return new Xorq(
      translate_location(a2, assignments),
      translate_location(b, assignments)
    );
  } else if (instr instanceof Cmpq2) {
    let a2 = instr.a;
    let b = instr.b;
    return new Cmpq(
      translate_location(a2, assignments),
      translate_location(b, assignments)
    );
  } else if (instr instanceof Set4) {
    let cmp = instr.cmp;
    let arg = instr.arg;
    return new Set3(cmp, arg);
  } else if (instr instanceof Movzbq2) {
    let a2 = instr.a;
    let b = instr.b;
    return new Movzbq(a2, translate_location(b, assignments));
  } else {
    let cmp = instr.cmp;
    let label = instr.label;
    return new JmpIf(cmp, label);
  }
}
function unfold(loop$initial, loop$generator, loop$result) {
  while (true) {
    let initial = loop$initial;
    let generator = loop$generator;
    let result = loop$result;
    let $ = generator(initial);
    if ($ instanceof Ok) {
      let item = $[0][0];
      let next_acc = $[0][1];
      loop$initial = next_acc;
      loop$generator = generator;
      loop$result = prepend(item, result);
    } else {
      return result;
    }
  }
}
function pick_color_internal(loop$set, loop$candidate) {
  while (true) {
    let set = loop$set;
    let candidate = loop$candidate;
    let $ = contains(set, candidate);
    if ($) {
      loop$set = set;
      loop$candidate = candidate + 1;
    } else {
      return candidate;
    }
  }
}
function pick_color(set) {
  return pick_color_internal(set, 0);
}
function pick_vertex(g) {
  let _pipe = g.graph;
  let _pipe$1 = nodes(_pipe);
  let _pipe$2 = filter_map(
    _pipe$1,
    (node) => {
      let $ = node.value.assignment;
      if ($ instanceof Some) {
        return new Error2(void 0);
      } else {
        return new Ok([size(node.value.saturation), node.id]);
      }
    }
  );
  let _pipe$3 = sort(
    _pipe$2,
    (a2, b) => {
      let $ = compare(a2[0], b[0]);
      if ($ instanceof Eq) {
        return compare_location(a2[1], b[1]);
      } else {
        return $;
      }
    }
  );
  let _pipe$4 = max2(
    _pipe$3,
    (a2, b) => {
      return compare(a2[0], b[0]);
    }
  );
  return map3(_pipe$4, second);
}
function color_graph_step(g) {
  let $ = pick_vertex(g);
  if ($ instanceof Ok) {
    let location = $[0];
    let $1 = match(g.graph, location);
    let context;
    let graph;
    if ($1 instanceof Ok) {
      context = $1[0][0];
      graph = $1[0][1];
    } else {
      throw makeError(
        "let_assert",
        FILEPATH3,
        "eoc/passes/allocate_registers",
        131,
        "color_graph_step",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $1,
          start: 3415,
          end: 3480,
          pattern_start: 3426,
          pattern_end: 3447
        }
      );
    }
    let color = pick_color(context.node.value.saturation);
    let _block;
    let _record = context.node.value;
    _block = new Node2(_record.location, new Some(color), _record.saturation);
    let value = _block;
    let _block$1;
    let _pipe = context.edges;
    let _pipe$1 = keys(_pipe);
    _block$1 = fold2(
      _pipe$1,
      graph,
      (g2, node_id) => {
        return modify_value(
          g2,
          node_id,
          (node) => {
            return new Node2(
              node.location,
              node.assignment,
              insert2(node.saturation, color)
            );
          }
        );
      }
    );
    let new_graph = _block$1;
    return new Ok([value, new Graph2(new_graph)]);
  } else {
    return new Error2(void 0);
  }
}
function color_graph(g) {
  return unfold(g, color_graph_step, toList([]));
}
function assignment_to_arg(a2) {
  if (a2 === -1) {
    return new Reg(new Rax());
  } else if (a2 === -2) {
    return new Reg(new Rsp());
  } else if (a2 === -3) {
    return new Reg(new Rbp());
  } else if (a2 === -4) {
    return new Reg(new R11());
  } else if (a2 === -5) {
    return new Reg(new R15());
  } else if (a2 === 0) {
    return new Reg(new Rcx());
  } else if (a2 === 1) {
    return new Reg(new Rdx());
  } else if (a2 === 2) {
    return new Reg(new Rsi());
  } else if (a2 === 3) {
    return new Reg(new Rdi());
  } else if (a2 === 4) {
    return new Reg(new R8());
  } else if (a2 === 5) {
    return new Reg(new R9());
  } else if (a2 === 6) {
    return new Reg(new R10());
  } else if (a2 === 7) {
    return new Reg(new Rbx());
  } else if (a2 === 8) {
    return new Reg(new R12());
  } else if (a2 === 9) {
    return new Reg(new R13());
  } else if (a2 === 10) {
    return new Reg(new R14());
  } else {
    let stack = a2;
    return new Deref(new Rbp(), -(stack - 11) * 8);
  }
}
function extract_assignments(g) {
  return fold2(
    g,
    new_map(),
    (acc, node) => {
      let $ = node.assignment;
      let assignment;
      if ($ instanceof Some) {
        assignment = $[0];
      } else {
        throw makeError(
          "let_assert",
          FILEPATH3,
          "eoc/passes/allocate_registers",
          183,
          "extract_assignments",
          "Pattern match failed, no pattern matched the value.",
          {
            value: $,
            start: 5066,
            end: 5111,
            pattern_start: 5077,
            pattern_end: 5093
          }
        );
      }
      let arg = assignment_to_arg(assignment);
      return insert(acc, node.location, arg);
    }
  );
}
function allocate_registers(input) {
  let _block;
  let _pipe = input.conflicts;
  let _pipe$1 = color_graph(_pipe);
  _block = extract_assignments(_pipe$1);
  let assignments = _block;
  let _block$1;
  let _pipe$2 = assignments;
  let _pipe$3 = values(_pipe$2);
  let _pipe$4 = filter_map(
    _pipe$3,
    (arg) => {
      if (arg instanceof Reg) {
        let reg = arg.reg;
        let $ = is_callee_saved(reg);
        if ($) {
          return new Ok(reg);
        } else {
          return new Error2(void 0);
        }
      } else {
        return new Error2(void 0);
      }
    }
  );
  _block$1 = from_list2(_pipe$4);
  let used_callee = _block$1;
  let _block$2;
  let _pipe$5 = assignments;
  let _pipe$6 = values(_pipe$5);
  let _pipe$7 = filter_map(
    _pipe$6,
    (arg) => {
      if (arg instanceof Deref) {
        let offset = arg.offset;
        return new Ok(globalThis.Math.trunc(-offset / 8));
      } else {
        return new Error2(void 0);
      }
    }
  );
  let _pipe$8 = max2(_pipe$7, compare);
  _block$2 = unwrap(_pipe$8, 0);
  let stack_vars = _block$2;
  let _block$3;
  let _pipe$9 = input.body;
  _block$3 = map_values(
    _pipe$9,
    (_, block) => {
      let new_instrs = map(
        block.body,
        (_capture) => {
          return translate_instr(_capture, assignments);
        }
      );
      return new Block(new_instrs);
    }
  );
  let body = _block$3;
  return new X86Program(body, stack_vars, used_callee);
}

// build/dev/javascript/eoc/cfg_ffi.mjs
var import_graphlib = __toESM(require_graphlib(), 1);
function new_cfg() {
  return new import_graphlib.Graph();
}
function add_vertex(g, v) {
  g.setNode(v);
  return g;
}
function add_edge2(g, v1, v2) {
  g.setEdge(v1, v2);
  return g;
}
function in_neighbors(g, v) {
  const neighbors = g.predecessors(v);
  return List.fromArray(neighbors);
}
function out_neighbors(g, v) {
  const neighbors = g.successors(v);
  return List.fromArray(neighbors);
}

// build/dev/javascript/eoc/eoc/passes/uncover_live.mjs
var FILEPATH4 = "src/eoc/passes/uncover_live.gleam";
function build_cfg(blocks) {
  return fold(
    blocks,
    new_cfg(),
    (g, block_name, block) => {
      return fold2(
        block.body,
        add_vertex(g, block_name),
        (g2, instr) => {
          if (instr instanceof Jmp2) {
            let label = instr.label;
            let _pipe = g2;
            let _pipe$1 = add_vertex(_pipe, label);
            return add_edge2(_pipe$1, label, block_name);
          } else if (instr instanceof JmpIf2) {
            let label = instr.label;
            let _pipe = g2;
            let _pipe$1 = add_vertex(_pipe, label);
            return add_edge2(_pipe$1, label, block_name);
          } else {
            return g2;
          }
        }
      );
    }
  );
}
function locations_in_arg(arg) {
  if (arg instanceof Imm2) {
    return new$();
  } else if (arg instanceof Reg2) {
    let reg = arg.reg;
    return from_list2(toList([new LocReg(reg)]));
  } else {
    let name = arg.name;
    return from_list2(toList([new LocVar(name)]));
  }
}
function read_locations_in_inst(inst) {
  if (inst instanceof Addq2) {
    let a2 = inst.a;
    let b = inst.b;
    return union(locations_in_arg(a2), locations_in_arg(b));
  } else if (inst instanceof Subq2) {
    let a2 = inst.a;
    let b = inst.b;
    return union(locations_in_arg(a2), locations_in_arg(b));
  } else if (inst instanceof Negq2) {
    let a2 = inst.a;
    return locations_in_arg(a2);
  } else if (inst instanceof Movq2) {
    let a2 = inst.a;
    return locations_in_arg(a2);
  } else if (inst instanceof Pushq2) {
    let a2 = inst.a;
    return union(
      locations_in_arg(a2),
      from_list2(toList([new LocReg(new Rsp())]))
    );
  } else if (inst instanceof Popq2) {
    return from_list2(toList([new LocReg(new Rsp())]));
  } else if (inst instanceof Callq2) {
    let arity = inst.arity;
    let _pipe = toList([
      new LocReg(new Rdi()),
      new LocReg(new Rsi()),
      new LocReg(new Rdx()),
      new LocReg(new Rcx()),
      new LocReg(new R8()),
      new LocReg(new R9())
    ]);
    let _pipe$1 = take(_pipe, arity);
    return from_list2(_pipe$1);
  } else if (inst instanceof Retq2) {
    return from_list2(toList([new LocReg(new Rax())]));
  } else if (inst instanceof Jmp2) {
    return new$();
  } else if (inst instanceof Xorq2) {
    let a2 = inst.a;
    let b = inst.b;
    return union(locations_in_arg(a2), locations_in_arg(b));
  } else if (inst instanceof Cmpq2) {
    let a2 = inst.a;
    let b = inst.b;
    return union(locations_in_arg(a2), locations_in_arg(b));
  } else if (inst instanceof Set4) {
    return new$();
  } else if (inst instanceof Movzbq2) {
    let a2 = inst.a;
    return from_list2(toList([new LocReg(bytereg_to_quad(a2))]));
  } else {
    return new$();
  }
}
function write_location_in_inst(inst) {
  if (inst instanceof Addq2) {
    let b = inst.b;
    return locations_in_arg(b);
  } else if (inst instanceof Subq2) {
    let b = inst.b;
    return locations_in_arg(b);
  } else if (inst instanceof Negq2) {
    let a2 = inst.a;
    return locations_in_arg(a2);
  } else if (inst instanceof Movq2) {
    let b = inst.b;
    return locations_in_arg(b);
  } else if (inst instanceof Pushq2) {
    return from_list2(toList([new LocReg(new Rsp())]));
  } else if (inst instanceof Popq2) {
    let a2 = inst.a;
    return union(
      locations_in_arg(a2),
      from_list2(toList([new LocReg(new Rsp())]))
    );
  } else if (inst instanceof Callq2) {
    return from_list2(toList([new LocReg(new Rax())]));
  } else if (inst instanceof Retq2) {
    return new$();
  } else if (inst instanceof Jmp2) {
    return new$();
  } else if (inst instanceof Xorq2) {
    let b = inst.b;
    return locations_in_arg(b);
  } else if (inst instanceof Cmpq2) {
    return new$();
  } else if (inst instanceof Set4) {
    let arg = inst.arg;
    return from_list2(toList([new LocReg(bytereg_to_quad(arg))]));
  } else if (inst instanceof Movzbq2) {
    let b = inst.b;
    return locations_in_arg(b);
  } else {
    return new$();
  }
}
function before_set(after, instr) {
  let _pipe = after;
  let _pipe$1 = difference(_pipe, write_location_in_inst(instr));
  return union(_pipe$1, read_locations_in_inst(instr));
}
function transfer(instrs, live_after) {
  return fold_right(
    instrs,
    toList([live_after]),
    (live_after2, instr) => {
      let $ = first(live_after2);
      let next2;
      if ($ instanceof Ok) {
        next2 = $[0];
      } else {
        throw makeError(
          "let_assert",
          FILEPATH4,
          "eoc/passes/uncover_live",
          104,
          "transfer",
          "Pattern match failed, no pattern matched the value.",
          {
            value: $,
            start: 2596,
            end: 2640,
            pattern_start: 2607,
            pattern_end: 2615
          }
        );
      }
      return prepend(before_set(next2, instr), live_after2);
    }
  );
}
function analyze_dataflow_loop(loop$g, loop$blocks, loop$mapping, loop$worklist) {
  while (true) {
    let g = loop$g;
    let blocks = loop$blocks;
    let mapping = loop$mapping;
    let worklist = loop$worklist;
    if (worklist instanceof Empty) {
      return mapping;
    } else {
      let node = worklist.head;
      let worklist$1 = worklist.tail;
      let _block;
      let _pipe = g;
      let _pipe$1 = in_neighbors(_pipe, node);
      _block = fold2(
        _pipe$1,
        new$(),
        (state, pred) => {
          let $3 = map_get(mapping, pred);
          let live_sets;
          if ($3 instanceof Ok) {
            live_sets = $3[0];
          } else {
            throw makeError(
              "let_assert",
              FILEPATH4,
              "eoc/passes/uncover_live",
              72,
              "analyze_dataflow_loop",
              "Pattern match failed, no pattern matched the value.",
              {
                value: $3,
                start: 1741,
                end: 1791,
                pattern_start: 1752,
                pattern_end: 1765
              }
            );
          }
          let _block$1;
          let _pipe$2 = live_sets;
          let _pipe$3 = first(_pipe$2);
          _block$1 = unwrap(_pipe$3, new$());
          let before = _block$1;
          return union(state, before);
        }
      );
      let input = _block;
      let $ = map_get(blocks, node);
      let block;
      if ($ instanceof Ok) {
        block = $[0];
      } else {
        throw makeError(
          "let_assert",
          FILEPATH4,
          "eoc/passes/uncover_live",
          81,
          "analyze_dataflow_loop",
          "Pattern match failed, no pattern matched the value.",
          {
            value: $,
            start: 1959,
            end: 2004,
            pattern_start: 1970,
            pattern_end: 1979
          }
        );
      }
      let output = transfer(block.body, input);
      let $1 = map_get(mapping, node);
      let previous;
      if ($1 instanceof Ok) {
        previous = $1[0];
      } else {
        throw makeError(
          "let_assert",
          FILEPATH4,
          "eoc/passes/uncover_live",
          83,
          "analyze_dataflow_loop",
          "Pattern match failed, no pattern matched the value.",
          {
            value: $1,
            start: 2058,
            end: 2107,
            pattern_start: 2069,
            pattern_end: 2081
          }
        );
      }
      let $2 = isEqual(output, previous);
      if ($2) {
        loop$g = g;
        loop$blocks = blocks;
        loop$mapping = mapping;
        loop$worklist = worklist$1;
      } else {
        loop$g = g;
        loop$blocks = blocks;
        loop$mapping = insert(mapping, node, output);
        loop$worklist = append3(worklist$1, out_neighbors(g, node));
      }
    }
  }
}
function analyze_dataflow(g, blocks) {
  let worklist = keys(blocks);
  let _block;
  let _pipe = worklist;
  let _pipe$1 = map(_pipe, (k) => {
    return [k, toList([])];
  });
  let _pipe$2 = from_list(_pipe$1);
  _block = insert(
    _pipe$2,
    "conclusion",
    toList([
      from_list2(toList([new LocReg(new Rax()), new LocReg(new Rsp())]))
    ])
  );
  let mapping = _block;
  let _pipe$3 = analyze_dataflow_loop(g, blocks, mapping, worklist);
  return delete$(_pipe$3, "conclusion");
}
function uncover_live(input) {
  let _block;
  let _pipe = input.body;
  let _pipe$1 = build_cfg(_pipe);
  let _pipe$2 = analyze_dataflow(_pipe$1, input.body);
  _block = map_values(
    _pipe$2,
    (block_name, live_sets) => {
      let $ = map_get(input.body, block_name);
      let block;
      if ($ instanceof Ok) {
        block = $[0];
      } else {
        throw makeError(
          "let_assert",
          FILEPATH4,
          "eoc/passes/uncover_live",
          24,
          "uncover_live",
          "Pattern match failed, no pattern matched the value.",
          {
            value: $,
            start: 677,
            end: 732,
            pattern_start: 688,
            pattern_end: 697
          }
        );
      }
      let live_before;
      let live_after;
      if (live_sets instanceof Empty) {
        throw makeError(
          "let_assert",
          FILEPATH4,
          "eoc/passes/uncover_live",
          25,
          "uncover_live",
          "Pattern match failed, no pattern matched the value.",
          {
            value: live_sets,
            start: 739,
            end: 789,
            pattern_start: 750,
            pattern_end: 777
          }
        );
      } else {
        live_before = live_sets.head;
        live_after = live_sets.tail;
      }
      return new Block2(block.body, live_before, live_after);
    }
  );
  let new_blocks = _block;
  return new X86Program2(new_blocks, input.conflicts);
}

// build/dev/javascript/eoc/eoc/passes/build_interference.mjs
function rule_1(g, s, d, live) {
  let _block;
  let _pipe = s;
  let _pipe$1 = union(_pipe, d);
  let _pipe$2 = union(_pipe$1, live);
  _block = ((_capture) => {
    return add_locations(g, _capture);
  })(_pipe$2);
  let g$1 = _block;
  return fold3(
    live,
    g$1,
    (g2, loc) => {
      let $ = !contains(s, loc) && !contains(d, loc);
      if ($) {
        return fold3(
          d,
          g2,
          (g3, d2) => {
            return add_conflict(g3, d2, loc);
          }
        );
      } else {
        return g2;
      }
    }
  );
}
function rule_2(g, w, live) {
  let _block;
  let _pipe = w;
  let _pipe$1 = union(_pipe, live);
  _block = ((_capture) => {
    return add_locations(g, _capture);
  })(_pipe$1);
  let g$1 = _block;
  return fold3(
    w,
    g$1,
    (g2, d) => {
      return fold3(
        live,
        g2,
        (g3, v) => {
          let $ = !isEqual(v, d);
          if ($) {
            return add_conflict(g3, d, v);
          } else {
            return g3;
          }
        }
      );
    }
  );
}
function determine_conflicts(ig, body, live_after) {
  let _pipe = body;
  let _pipe$1 = zip(_pipe, live_after);
  return fold2(
    _pipe$1,
    ig,
    (g, pair2) => {
      let instr;
      let live;
      instr = pair2[0];
      live = pair2[1];
      if (instr instanceof Movq2) {
        let s = instr.a;
        let d = instr.b;
        return rule_1(
          g,
          locations_in_arg(s),
          locations_in_arg(d),
          live
        );
      } else if (instr instanceof Movzbq2) {
        let s = instr.a;
        let d = instr.b;
        return rule_1(
          g,
          from_list2(
            toList([new LocReg(bytereg_to_quad(s))])
          ),
          locations_in_arg(d),
          live
        );
      } else {
        let i = instr;
        return rule_2(g, write_location_in_inst(i), live);
      }
    }
  );
}
function build_interference(program2) {
  let conflicts = fold(
    program2.body,
    program2.conflicts,
    (ig, _, block) => {
      return determine_conflicts(ig, block.body, block.live_after);
    }
  );
  return new X86Program2(program2.body, conflicts);
}

// build/dev/javascript/eoc/eoc/langs/c_loop.mjs
var Int2 = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Bool2 = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Variable = class extends CustomType {
  constructor(v) {
    super();
    this.v = v;
  }
};
var Void2 = class extends CustomType {
};
var Read2 = class extends CustomType {
};
var Neg = class extends CustomType {
  constructor(a2) {
    super();
    this.a = a2;
  }
};
var Not2 = class extends CustomType {
  constructor(a2) {
    super();
    this.a = a2;
  }
};
var Cmp2 = class extends CustomType {
  constructor(op, a2, b) {
    super();
    this.op = op;
    this.a = a2;
    this.b = b;
  }
};
var Plus2 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Minus2 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Atom = class extends CustomType {
  constructor(atm) {
    super();
    this.atm = atm;
  }
};
var Prim2 = class extends CustomType {
  constructor(op) {
    super();
    this.op = op;
  }
};
var Assign = class extends CustomType {
  constructor(var$2, expr) {
    super();
    this.var = var$2;
    this.expr = expr;
  }
};
var ReadStmt = class extends CustomType {
};
var Return = class extends CustomType {
  constructor(a2) {
    super();
    this.a = a2;
  }
};
var Seq = class extends CustomType {
  constructor(s, t) {
    super();
    this.s = s;
    this.t = t;
  }
};
var Goto = class extends CustomType {
  constructor(label) {
    super();
    this.label = label;
  }
};
var If2 = class extends CustomType {
  constructor(cond, if_true, if_false) {
    super();
    this.cond = cond;
    this.if_true = if_true;
    this.if_false = if_false;
  }
};
var CProgram = class extends CustomType {
  constructor(info, body) {
    super();
    this.info = info;
    this.body = body;
  }
};

// build/dev/javascript/eoc/eoc/langs/l_mon_while.mjs
var Int3 = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Var3 = class extends CustomType {
  constructor(name) {
    super();
    this.name = name;
  }
};
var Bool3 = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Void3 = class extends CustomType {
};
var Read3 = class extends CustomType {
};
var Negate2 = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Plus3 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Minus3 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Not3 = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Cmp3 = class extends CustomType {
  constructor(op, a2, b) {
    super();
    this.op = op;
    this.a = a2;
    this.b = b;
  }
};
var Atomic = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Prim3 = class extends CustomType {
  constructor(op) {
    super();
    this.op = op;
  }
};
var Let2 = class extends CustomType {
  constructor(var$2, binding, expr) {
    super();
    this.var = var$2;
    this.binding = binding;
    this.expr = expr;
  }
};
var If3 = class extends CustomType {
  constructor(cond, if_true, if_false) {
    super();
    this.cond = cond;
    this.if_true = if_true;
    this.if_false = if_false;
  }
};
var GetBang = class extends CustomType {
  constructor(var$2) {
    super();
    this.var = var$2;
  }
};
var SetBang2 = class extends CustomType {
  constructor(var$2, value) {
    super();
    this.var = var$2;
    this.value = value;
  }
};
var Begin2 = class extends CustomType {
  constructor(stmts, result) {
    super();
    this.stmts = stmts;
    this.result = result;
  }
};
var WhileLoop2 = class extends CustomType {
  constructor(condition, body) {
    super();
    this.condition = condition;
    this.body = body;
  }
};
var Program2 = class extends CustomType {
  constructor(body) {
    super();
    this.body = body;
  }
};

// build/dev/javascript/eoc/eoc/passes/explicate_control.mjs
var FILEPATH5 = "src/eoc/passes/explicate_control.gleam";
function create_label(prefix, blocks) {
  let new_index = map_size(blocks) + 1;
  return prefix + "_" + to_string(new_index);
}
function create_block(tail, blocks) {
  if (tail instanceof Goto) {
    return [tail, blocks];
  } else {
    let new_label = create_label("block", blocks);
    return [new Goto(new_label), insert(blocks, new_label, tail)];
  }
}
function convert_atm(input) {
  if (input instanceof Int3) {
    let i = input.value;
    return new Int2(i);
  } else if (input instanceof Var3) {
    let v = input.name;
    return new Variable(v);
  } else if (input instanceof Bool3) {
    let b = input.value;
    return new Bool2(b);
  } else {
    return new Void2();
  }
}
function explicate_pred(loop$cond, loop$if_true, loop$if_false, loop$blocks) {
  while (true) {
    let cond = loop$cond;
    let if_true = loop$if_true;
    let if_false = loop$if_false;
    let blocks = loop$blocks;
    if (cond instanceof Atomic) {
      let $ = cond.value;
      if ($ instanceof Var3) {
        let v = $.name;
        let $1 = create_block(if_true, blocks);
        let thn_block;
        let b1;
        thn_block = $1[0];
        b1 = $1[1];
        let $2 = create_block(if_false, b1);
        let els_block;
        let b2;
        els_block = $2[0];
        b2 = $2[1];
        return [
          new If2(
            new Prim2(
              new Cmp2(new Eq2(), new Variable(v), new Bool2(true))
            ),
            thn_block,
            els_block
          ),
          b2
        ];
      } else if ($ instanceof Bool3) {
        let value = $.value;
        if (value) {
          return [if_true, blocks];
        } else {
          return [if_false, blocks];
        }
      } else {
        throw makeError(
          "panic",
          FILEPATH5,
          "eoc/passes/explicate_control",
          278,
          "explicate_pred",
          "explicate_pred unhandled case",
          {}
        );
      }
    } else if (cond instanceof Prim3) {
      let $ = cond.op;
      if ($ instanceof Not3) {
        let arg = $.value;
        loop$cond = new Atomic(arg);
        loop$if_true = if_false;
        loop$if_false = if_true;
        loop$blocks = blocks;
      } else if ($ instanceof Cmp3) {
        let op = $.op;
        let a2 = $.a;
        let b = $.b;
        let $1 = create_block(if_true, blocks);
        let thn_block;
        let b1;
        thn_block = $1[0];
        b1 = $1[1];
        let $2 = create_block(if_false, b1);
        let els_block;
        let b2;
        els_block = $2[0];
        b2 = $2[1];
        return [
          new If2(
            new Prim2(new Cmp2(op, convert_atm(a2), convert_atm(b))),
            thn_block,
            els_block
          ),
          b2
        ];
      } else {
        throw makeError(
          "panic",
          FILEPATH5,
          "eoc/passes/explicate_control",
          278,
          "explicate_pred",
          "explicate_pred unhandled case",
          {}
        );
      }
    } else if (cond instanceof Let2) {
      let var$2 = cond.var;
      let binding = cond.binding;
      let expr = cond.expr;
      let $ = explicate_pred(expr, if_true, if_false, blocks);
      let new_expr;
      let b1;
      new_expr = $[0];
      b1 = $[1];
      return explicate_assign(binding, var$2, new_expr, b1);
    } else if (cond instanceof If3) {
      let c_inner = cond.cond;
      let t_inner = cond.if_true;
      let f_inner = cond.if_false;
      let $ = create_block(if_true, blocks);
      let thn_block;
      let b1;
      thn_block = $[0];
      b1 = $[1];
      let $1 = create_block(if_false, b1);
      let els_block;
      let b2;
      els_block = $1[0];
      b2 = $1[1];
      let $2 = explicate_pred(t_inner, thn_block, els_block, b2);
      let t1;
      let b3;
      t1 = $2[0];
      b3 = $2[1];
      let $3 = explicate_pred(f_inner, thn_block, els_block, b3);
      let f1;
      let b4;
      f1 = $3[0];
      b4 = $3[1];
      loop$cond = c_inner;
      loop$if_true = t1;
      loop$if_false = f1;
      loop$blocks = b4;
    } else if (cond instanceof GetBang) {
      let v = cond.var;
      let $ = create_block(if_true, blocks);
      let thn_block;
      let b1;
      thn_block = $[0];
      b1 = $[1];
      let $1 = create_block(if_false, b1);
      let els_block;
      let b2;
      els_block = $1[0];
      b2 = $1[1];
      return [
        new If2(
          new Prim2(
            new Cmp2(new Eq2(), new Variable(v), new Bool2(true))
          ),
          thn_block,
          els_block
        ),
        b2
      ];
    } else if (cond instanceof Begin2) {
      let stmts = cond.stmts;
      let result = cond.result;
      let $ = explicate_pred(result, if_true, if_false, blocks);
      let tail;
      let blocks1;
      tail = $[0];
      blocks1 = $[1];
      return fold_right(
        stmts,
        [tail, blocks1],
        (acc, stmt) => {
          return explicate_effect(stmt, acc[0], acc[1]);
        }
      );
    } else {
      throw makeError(
        "panic",
        FILEPATH5,
        "eoc/passes/explicate_control",
        278,
        "explicate_pred",
        "explicate_pred unhandled case",
        {}
      );
    }
  }
}
function explicate_assign(loop$expr, loop$v, loop$cont, loop$blocks) {
  while (true) {
    let expr = loop$expr;
    let v = loop$v;
    let cont = loop$cont;
    let blocks = loop$blocks;
    if (expr instanceof Atomic) {
      let a2 = expr.value;
      return [
        new Seq(new Assign(v, new Atom(convert_atm(a2))), cont),
        blocks
      ];
    } else if (expr instanceof Prim3) {
      let $ = expr.op;
      if ($ instanceof Read3) {
        return [
          new Seq(new Assign(v, new Prim2(new Read2())), cont),
          blocks
        ];
      } else if ($ instanceof Negate2) {
        let a2 = $.value;
        return [
          new Seq(
            new Assign(v, new Prim2(new Neg(convert_atm(a2)))),
            cont
          ),
          blocks
        ];
      } else if ($ instanceof Plus3) {
        let a2 = $.a;
        let b = $.b;
        return [
          new Seq(
            new Assign(
              v,
              new Prim2(new Plus2(convert_atm(a2), convert_atm(b)))
            ),
            cont
          ),
          blocks
        ];
      } else if ($ instanceof Minus3) {
        let a2 = $.a;
        let b = $.b;
        return [
          new Seq(
            new Assign(
              v,
              new Prim2(new Minus2(convert_atm(a2), convert_atm(b)))
            ),
            cont
          ),
          blocks
        ];
      } else if ($ instanceof Not3) {
        let value = $.value;
        return [
          new Seq(
            new Assign(v, new Prim2(new Not2(convert_atm(value)))),
            cont
          ),
          blocks
        ];
      } else {
        let op = $.op;
        let a2 = $.a;
        let b = $.b;
        return [
          new Seq(
            new Assign(
              v,
              new Prim2(new Cmp2(op, convert_atm(a2), convert_atm(b)))
            ),
            cont
          ),
          blocks
        ];
      }
    } else if (expr instanceof Let2) {
      let v1 = expr.var;
      let b = expr.binding;
      let e = expr.expr;
      let $ = explicate_assign(e, v, cont, blocks);
      let cont1;
      let b1;
      cont1 = $[0];
      b1 = $[1];
      loop$expr = b;
      loop$v = v1;
      loop$cont = cont1;
      loop$blocks = b1;
    } else if (expr instanceof If3) {
      let cond = expr.cond;
      let if_true = expr.if_true;
      let if_false = expr.if_false;
      let $ = create_block(cont, blocks);
      let new_cont;
      let new_blocks;
      new_cont = $[0];
      new_blocks = $[1];
      let $1 = explicate_assign(if_true, v, new_cont, new_blocks);
      let t1;
      let b1;
      t1 = $1[0];
      b1 = $1[1];
      let $2 = explicate_assign(if_false, v, new_cont, b1);
      let f1;
      let b2;
      f1 = $2[0];
      b2 = $2[1];
      return explicate_pred(cond, t1, f1, b2);
    } else if (expr instanceof GetBang) {
      let var$2 = expr.var;
      return [
        new Seq(new Assign(v, new Atom(new Variable(var$2))), cont),
        blocks
      ];
    } else if (expr instanceof SetBang2) {
      let var$2 = expr.var;
      let value = expr.value;
      let new_cont = new Seq(
        new Assign(v, new Atom(new Void2())),
        cont
      );
      loop$expr = value;
      loop$v = var$2;
      loop$cont = new_cont;
      loop$blocks = blocks;
    } else if (expr instanceof Begin2) {
      let stmts = expr.stmts;
      let result = expr.result;
      let cont$1 = explicate_assign(result, v, cont, blocks);
      return fold_right(
        stmts,
        cont$1,
        (acc, stmt) => {
          return explicate_effect(stmt, acc[0], acc[1]);
        }
      );
    } else {
      let condition = expr.condition;
      let body = expr.body;
      let loop_label = create_label("loop", blocks);
      let loop_start = new Goto(loop_label);
      let $ = explicate_assign(
        new Atomic(new Void3()),
        v,
        cont,
        blocks
      );
      let if_false;
      let blocks1;
      if_false = $[0];
      blocks1 = $[1];
      let $1 = explicate_effect(body, loop_start, blocks1);
      let if_true;
      let blocks2;
      if_true = $1[0];
      blocks2 = $1[1];
      let $2 = explicate_pred(condition, if_true, if_false, blocks2);
      let loop_condition;
      let blocks3;
      loop_condition = $2[0];
      blocks3 = $2[1];
      let blocks4 = insert(blocks3, loop_label, loop_condition);
      return [loop_start, blocks4];
    }
  }
}
function explicate_effect(expr, cont, blocks) {
  if (expr instanceof Atomic) {
    return [cont, blocks];
  } else if (expr instanceof Prim3) {
    let $ = expr.op;
    if ($ instanceof Read3) {
      return [new Seq(new ReadStmt(), cont), blocks];
    } else {
      return [cont, blocks];
    }
  } else if (expr instanceof Let2) {
    let var$2 = expr.var;
    let binding = expr.binding;
    let expr$1 = expr.expr;
    let $ = explicate_effect(expr$1, cont, blocks);
    let tail;
    let new_blocks;
    tail = $[0];
    new_blocks = $[1];
    return explicate_assign(binding, var$2, tail, new_blocks);
  } else if (expr instanceof If3) {
    let cond = expr.cond;
    let if_true = expr.if_true;
    let if_false = expr.if_false;
    let $ = create_block(cont, blocks);
    let new_cont;
    let b1;
    new_cont = $[0];
    b1 = $[1];
    let $1 = explicate_effect(if_true, new_cont, b1);
    let thn_block;
    let b2;
    thn_block = $1[0];
    b2 = $1[1];
    let $2 = explicate_effect(if_false, new_cont, b2);
    let els_block;
    let b3;
    els_block = $2[0];
    b3 = $2[1];
    return explicate_pred(cond, thn_block, els_block, b3);
  } else if (expr instanceof GetBang) {
    return [cont, blocks];
  } else if (expr instanceof SetBang2) {
    let var$2 = expr.var;
    let value = expr.value;
    return explicate_assign(value, var$2, cont, blocks);
  } else if (expr instanceof Begin2) {
    let stmts = expr.stmts;
    let result = expr.result;
    let tail = explicate_effect(result, cont, blocks);
    return fold2(
      stmts,
      tail,
      (acc, stmt) => {
        return explicate_effect(stmt, acc[0], acc[1]);
      }
    );
  } else {
    let condition = expr.condition;
    let body = expr.body;
    let loop_label = create_label("loop", blocks);
    let loop_start = new Goto(loop_label);
    let $ = create_block(cont, blocks);
    let if_false;
    let blocks1;
    if_false = $[0];
    blocks1 = $[1];
    let $1 = explicate_effect(body, loop_start, blocks1);
    let if_true;
    let blocks2;
    if_true = $1[0];
    blocks2 = $1[1];
    let $2 = explicate_pred(condition, if_true, if_false, blocks2);
    let loop_condition;
    let blocks3;
    loop_condition = $2[0];
    blocks3 = $2[1];
    let blocks4 = insert(blocks3, loop_label, loop_condition);
    return [loop_start, blocks4];
  }
}
function explicate_tail(input, blocks) {
  if (input instanceof Atomic) {
    let $ = input.value;
    if ($ instanceof Int3) {
      let i = $.value;
      return [new Return(new Atom(new Int2(i))), blocks];
    } else if ($ instanceof Var3) {
      let v = $.name;
      return [new Return(new Atom(new Variable(v))), blocks];
    } else if ($ instanceof Bool3) {
      let b = $.value;
      return [new Return(new Atom(new Bool2(b))), blocks];
    } else {
      return [new Return(new Atom(new Void2())), blocks];
    }
  } else if (input instanceof Prim3) {
    let $ = input.op;
    if ($ instanceof Read3) {
      return [new Return(new Prim2(new Read2())), blocks];
    } else if ($ instanceof Negate2) {
      let a2 = $.value;
      return [new Return(new Prim2(new Neg(convert_atm(a2)))), blocks];
    } else if ($ instanceof Plus3) {
      let a2 = $.a;
      let b = $.b;
      return [
        new Return(new Prim2(new Plus2(convert_atm(a2), convert_atm(b)))),
        blocks
      ];
    } else if ($ instanceof Minus3) {
      let a2 = $.a;
      let b = $.b;
      return [
        new Return(new Prim2(new Minus2(convert_atm(a2), convert_atm(b)))),
        blocks
      ];
    } else if ($ instanceof Not3) {
      let value = $.value;
      return [
        new Return(new Prim2(new Not2(convert_atm(value)))),
        blocks
      ];
    } else {
      let op = $.op;
      let a2 = $.a;
      let b = $.b;
      return [
        new Return(
          new Prim2(new Cmp2(op, convert_atm(a2), convert_atm(b)))
        ),
        blocks
      ];
    }
  } else if (input instanceof Let2) {
    let v = input.var;
    let b = input.binding;
    let e = input.expr;
    let $ = explicate_tail(e, blocks);
    let tail;
    let new_blocks;
    tail = $[0];
    new_blocks = $[1];
    return explicate_assign(b, v, tail, new_blocks);
  } else if (input instanceof If3) {
    let cond = input.cond;
    let if_true = input.if_true;
    let if_false = input.if_false;
    let $ = explicate_tail(if_true, blocks);
    let t1;
    let b1;
    t1 = $[0];
    b1 = $[1];
    let $1 = explicate_tail(if_false, b1);
    let f1;
    let b2;
    f1 = $1[0];
    b2 = $1[1];
    return explicate_pred(cond, t1, f1, b2);
  } else if (input instanceof GetBang) {
    let var$2 = input.var;
    return [new Return(new Atom(new Variable(var$2))), blocks];
  } else if (input instanceof SetBang2) {
    let var$2 = input.var;
    let value = input.value;
    let tail = new Return(new Atom(new Void2()));
    return explicate_assign(value, var$2, tail, blocks);
  } else if (input instanceof Begin2) {
    let stmts = input.stmts;
    let result = input.result;
    let $ = explicate_tail(result, blocks);
    let tail;
    let blocks1;
    tail = $[0];
    blocks1 = $[1];
    return fold_right(
      stmts,
      [tail, blocks1],
      (acc, stmt) => {
        return explicate_effect(stmt, acc[0], acc[1]);
      }
    );
  } else {
    let condition = input.condition;
    let body = input.body;
    let loop_label = create_label("loop", blocks);
    let loop_start = new Goto(loop_label);
    let if_false = new Return(new Atom(new Void2()));
    let $ = explicate_effect(body, loop_start, blocks);
    let if_true;
    let blocks1;
    if_true = $[0];
    blocks1 = $[1];
    let $1 = explicate_pred(condition, if_true, if_false, blocks1);
    let loop_condition;
    let blocks2;
    loop_condition = $1[0];
    blocks2 = $1[1];
    let blocks3 = insert(blocks2, loop_label, loop_condition);
    return [loop_start, blocks3];
  }
}
function explicate_control(input) {
  let $ = explicate_tail(input.body, new_map());
  let tail;
  let blocks;
  tail = $[0];
  blocks = $[1];
  return new CProgram(new_map(), insert(blocks, "start", tail));
}

// build/dev/javascript/eoc/eoc/passes/generate_prelude_and_conclusion.mjs
function align(bytes) {
  let $ = bytes % 16;
  if ($ === 0) {
    return bytes;
  } else {
    return (globalThis.Math.trunc(bytes / 16) + 1) * 16;
  }
}
function compute_frame_alignment(input) {
  let saved_regs = size(input.used_callee) + 1;
  return align(8 * input.stack_vars + 8 * saved_regs) - 8 * saved_regs;
}
function get_saved_registers(input) {
  return to_list(input.used_callee);
}
function generate_main(alignment, registers) {
  let pushes = map(
    prepend(new Rbp(), registers),
    (r) => {
      return new Pushq(new Reg(r));
    }
  );
  let _block;
  if (alignment === 0) {
    _block = toList([]);
  } else {
    _block = toList([
      new Subq(new Imm(alignment), new Reg(new Rsp()))
    ]);
  }
  let aligner = _block;
  let _block$1;
  let _pipe = pushes;
  let _pipe$1 = append3(
    _pipe,
    toList([new Movq(new Reg(new Rsp()), new Reg(new Rbp()))])
  );
  let _pipe$2 = append3(_pipe$1, aligner);
  _block$1 = append3(_pipe$2, toList([new Jmp("start")]));
  let instrs = _block$1;
  return new Block(instrs);
}
function generate_conclusion(alignment, registers) {
  let _block;
  let _pipe = prepend(new Rbp(), registers);
  let _pipe$1 = map(
    _pipe,
    (r) => {
      return new Popq(new Reg(r));
    }
  );
  _block = reverse(_pipe$1);
  let pops = _block;
  let _block$1;
  if (alignment === 0) {
    _block$1 = toList([]);
  } else {
    _block$1 = toList([
      new Addq(new Imm(alignment), new Reg(new Rsp()))
    ]);
  }
  let aligner = _block$1;
  let _block$2;
  let _pipe$2 = aligner;
  let _pipe$3 = append3(_pipe$2, pops);
  _block$2 = append3(_pipe$3, toList([new Retq()]));
  let instrs = _block$2;
  return new Block(instrs);
}
function generate_prelude_and_conclusion(input) {
  let alignment = compute_frame_alignment(input);
  let saved_regs = get_saved_registers(input);
  let main3 = generate_main(alignment, saved_regs);
  let conclusion = generate_conclusion(alignment, saved_regs);
  let _block;
  let _pipe = input.body;
  let _pipe$1 = insert(_pipe, "main", main3);
  _block = insert(_pipe$1, "conclusion", conclusion);
  let body = _block;
  return new X86Program(body, input.stack_vars, input.used_callee);
}
function bytereg_to_text(arg) {
  let _block;
  if (arg instanceof Ah) {
    _block = "ah";
  } else if (arg instanceof Al) {
    _block = "al";
  } else if (arg instanceof Bh) {
    _block = "bh";
  } else if (arg instanceof Bl) {
    _block = "bl";
  } else if (arg instanceof Ch) {
    _block = "ch";
  } else if (arg instanceof Cl) {
    _block = "cl";
  } else if (arg instanceof Dh) {
    _block = "dh";
  } else {
    _block = "dl";
  }
  let r = _block;
  return concat(toList(["%", r]));
}
function reg_to_text(arg) {
  let _block;
  if (arg instanceof Rsp) {
    _block = "rsp";
  } else if (arg instanceof Rbp) {
    _block = "rbp";
  } else if (arg instanceof Rax) {
    _block = "rax";
  } else if (arg instanceof Rbx) {
    _block = "rbx";
  } else if (arg instanceof Rcx) {
    _block = "rcx";
  } else if (arg instanceof Rdx) {
    _block = "rdx";
  } else if (arg instanceof Rsi) {
    _block = "rsi";
  } else if (arg instanceof Rdi) {
    _block = "rdi";
  } else if (arg instanceof R8) {
    _block = "r8";
  } else if (arg instanceof R9) {
    _block = "r9";
  } else if (arg instanceof R10) {
    _block = "r10";
  } else if (arg instanceof R11) {
    _block = "r11";
  } else if (arg instanceof R12) {
    _block = "r12";
  } else if (arg instanceof R13) {
    _block = "r13";
  } else if (arg instanceof R14) {
    _block = "r14";
  } else {
    _block = "r15";
  }
  let r = _block;
  return concat(toList(["%", r]));
}
function arg_to_text(arg) {
  if (arg instanceof Imm) {
    let i = arg.value;
    let _pipe = identity("$");
    return append(_pipe, to_string(i));
  } else if (arg instanceof Reg) {
    let r = arg.reg;
    return reg_to_text(r);
  } else {
    let r = arg.reg;
    let offset = arg.offset;
    let _pipe = offset;
    let _pipe$1 = to_string(_pipe);
    let _pipe$2 = identity(_pipe$1);
    let _pipe$3 = append(_pipe$2, "(");
    let _pipe$4 = add(_pipe$3, reg_to_text(r));
    return append(_pipe$4, ")");
  }
}
function indent() {
  return identity("    ");
}
function instr_to_text(instr) {
  let _block;
  if (instr instanceof Addq) {
    let a2 = instr.a;
    let b = instr.b;
    let _pipe2 = toList([
      identity("addq "),
      arg_to_text(a2),
      identity(", "),
      arg_to_text(b)
    ]);
    _block = concat(_pipe2);
  } else if (instr instanceof Subq) {
    let a2 = instr.a;
    let b = instr.b;
    let _pipe2 = toList([
      identity("subq "),
      arg_to_text(a2),
      identity(", "),
      arg_to_text(b)
    ]);
    _block = concat(_pipe2);
  } else if (instr instanceof Negq) {
    let a2 = instr.a;
    _block = join(
      toList([identity("negq"), arg_to_text(a2)]),
      " "
    );
  } else if (instr instanceof Movq) {
    let a2 = instr.a;
    let b = instr.b;
    let _pipe2 = toList([
      identity("movq "),
      arg_to_text(a2),
      identity(", "),
      arg_to_text(b)
    ]);
    _block = concat(_pipe2);
  } else if (instr instanceof Pushq) {
    let a2 = instr.a;
    _block = join(
      toList([identity("pushq"), arg_to_text(a2)]),
      " "
    );
  } else if (instr instanceof Popq) {
    let a2 = instr.a;
    _block = join(
      toList([identity("popq"), arg_to_text(a2)]),
      " "
    );
  } else if (instr instanceof Callq) {
    let l = instr.label;
    let _pipe2 = identity("callq ");
    _block = append(_pipe2, l);
  } else if (instr instanceof Retq) {
    _block = identity("retq");
  } else if (instr instanceof Jmp) {
    let s = instr.label;
    let _pipe2 = identity("jmp ");
    _block = append(_pipe2, s);
  } else if (instr instanceof Xorq) {
    let a2 = instr.a;
    let b = instr.b;
    let _pipe2 = toList([
      identity("xorq "),
      arg_to_text(a2),
      identity(", "),
      arg_to_text(b)
    ]);
    _block = concat(_pipe2);
  } else if (instr instanceof Cmpq) {
    let a2 = instr.a;
    let b = instr.b;
    let _pipe2 = toList([
      identity("cmpq "),
      arg_to_text(a2),
      identity(", "),
      arg_to_text(b)
    ]);
    _block = concat(_pipe2);
  } else if (instr instanceof Set3) {
    let cmp = instr.cmp;
    let arg = instr.arg;
    let _block$1;
    if (cmp instanceof E) {
      _block$1 = identity("sete ");
    } else if (cmp instanceof L) {
      _block$1 = identity("setl ");
    } else if (cmp instanceof Le) {
      _block$1 = identity("setle ");
    } else if (cmp instanceof G) {
      _block$1 = identity("setg ");
    } else {
      _block$1 = identity("setge ");
    }
    let _pipe2 = _block$1;
    _block = add(_pipe2, bytereg_to_text(arg));
  } else if (instr instanceof Movzbq) {
    let a2 = instr.a;
    let b = instr.b;
    let _pipe2 = toList([
      identity("movzbq "),
      bytereg_to_text(a2),
      identity(", "),
      arg_to_text(b)
    ]);
    _block = concat(_pipe2);
  } else {
    let cmp = instr.cmp;
    let label = instr.label;
    let _block$1;
    if (cmp instanceof E) {
      _block$1 = identity("je ");
    } else if (cmp instanceof L) {
      _block$1 = identity("jl ");
    } else if (cmp instanceof Le) {
      _block$1 = identity("jle ");
    } else if (cmp instanceof G) {
      _block$1 = identity("jg ");
    } else {
      _block$1 = identity("jge ");
    }
    let _pipe2 = _block$1;
    _block = append(_pipe2, label);
  }
  let text4 = _block;
  let _pipe = toList([indent(), text4]);
  return concat(_pipe);
}
function block_to_text(kv, entry) {
  let label;
  let block;
  label = kv[0];
  block = kv[1];
  let _block;
  let $ = label === entry;
  if ($) {
    _block = toList([
      (() => {
        let _pipe2 = "    .globl ";
        let _pipe$12 = identity(_pipe2);
        return append(_pipe$12, label);
      })(),
      (() => {
        let _pipe2 = label;
        let _pipe$12 = identity(_pipe2);
        return append(_pipe$12, ":");
      })()
    ]);
  } else {
    _block = toList([
      (() => {
        let _pipe2 = label;
        let _pipe$12 = identity(_pipe2);
        return append(_pipe$12, ":");
      })()
    ]);
  }
  let prelude = _block;
  let instrs = map(block.body, instr_to_text);
  let _pipe = prelude;
  let _pipe$1 = append3(_pipe, instrs);
  return join(_pipe$1, "\n");
}
function program_to_text(input, entry) {
  let _pipe = input.body;
  let _pipe$1 = map_to_list(_pipe);
  let _pipe$2 = sort(
    _pipe$1,
    (a2, b) => {
      return compare2(first2(a2), first2(b));
    }
  );
  let _pipe$3 = map(
    _pipe$2,
    (_capture) => {
      return block_to_text(_capture, entry);
    }
  );
  let _pipe$4 = join(_pipe$3, "\n\n");
  return identity(_pipe$4);
}

// build/dev/javascript/iv/iv_ffi.mjs
var empty3 = () => [];
var singleton = (x) => [x];
var append4 = (xs, x) => [...xs, x];
var get1 = (idx, xs) => xs[idx - 1];
var length2 = (xs) => xs.length;
var bsl = (a2, b) => a2 << b;
var bsr = (a2, b) => a2 >> b;

// build/dev/javascript/iv/iv/internal/vector.mjs
function fold_loop2(loop$xs, loop$state, loop$idx, loop$len, loop$fun) {
  while (true) {
    let xs = loop$xs;
    let state = loop$state;
    let idx = loop$idx;
    let len = loop$len;
    let fun = loop$fun;
    let $ = idx <= len;
    if ($) {
      loop$xs = xs;
      loop$state = fun(state, get1(idx, xs));
      loop$idx = idx + 1;
      loop$len = len;
      loop$fun = fun;
    } else {
      return state;
    }
  }
}
function fold_skip_first(xs, state, fun) {
  let len = length2(xs);
  return fold_loop2(xs, state, 2, len, fun);
}

// build/dev/javascript/iv/iv/internal/node.mjs
var Balanced = class extends CustomType {
  constructor(size4, children) {
    super();
    this.size = size4;
    this.children = children;
  }
};
var Unbalanced = class extends CustomType {
  constructor(sizes, children) {
    super();
    this.sizes = sizes;
    this.children = children;
  }
};
var Leaf = class extends CustomType {
  constructor(children) {
    super();
    this.children = children;
  }
};
function leaf(items) {
  return new Leaf(items);
}
function size3(node) {
  if (node instanceof Balanced) {
    let size$1 = node.size;
    return size$1;
  } else if (node instanceof Unbalanced) {
    let sizes = node.sizes;
    return get1(length2(sizes), sizes);
  } else {
    let children = node.children;
    return length2(children);
  }
}
function compute_sizes(nodes2) {
  let first_size = size3(get1(1, nodes2));
  return fold_skip_first(
    nodes2,
    singleton(first_size),
    (sizes, node) => {
      let size$1 = get1(length2(sizes), sizes) + size3(node);
      return append4(sizes, size$1);
    }
  );
}
function find_size(loop$sizes, loop$size_idx_plus_one, loop$index) {
  while (true) {
    let sizes = loop$sizes;
    let size_idx_plus_one = loop$size_idx_plus_one;
    let index4 = loop$index;
    let $ = get1(size_idx_plus_one, sizes) > index4;
    if ($) {
      return size_idx_plus_one - 1;
    } else {
      loop$sizes = sizes;
      loop$size_idx_plus_one = size_idx_plus_one + 1;
      loop$index = index4;
    }
  }
}
function balanced(shift, nodes2) {
  let len = length2(nodes2);
  let last_child = get1(len, nodes2);
  let max_size = bsl(1, shift);
  let size$1 = max_size * (len - 1) + size3(last_child);
  return new Balanced(size$1, nodes2);
}
function branch(shift, nodes2) {
  let len = length2(nodes2);
  let max_size = bsl(1, shift);
  let sizes = compute_sizes(nodes2);
  let _block;
  if (len === 1) {
    _block = 0;
  } else {
    _block = get1(len - 1, sizes);
  }
  let prefix_size = _block;
  let is_balanced = prefix_size === max_size * (len - 1);
  if (is_balanced) {
    let size$1 = get1(len, sizes);
    return new Balanced(size$1, nodes2);
  } else {
    return new Unbalanced(sizes, nodes2);
  }
}
var branch_bits = 5;
function get2(loop$node, loop$shift, loop$index) {
  while (true) {
    let node = loop$node;
    let shift = loop$shift;
    let index4 = loop$index;
    if (node instanceof Balanced) {
      let children = node.children;
      let node_index = bsr(index4, shift);
      let index$1 = index4 - bsl(node_index, shift);
      let child = get1(node_index + 1, children);
      loop$node = child;
      loop$shift = shift - branch_bits;
      loop$index = index$1;
    } else if (node instanceof Unbalanced) {
      let sizes = node.sizes;
      let children = node.children;
      let start_search_index = bsr(index4, shift);
      let node_index = find_size(sizes, start_search_index + 1, index4);
      let _block;
      if (node_index === 0) {
        _block = index4;
      } else {
        _block = index4 - get1(node_index, sizes);
      }
      let index$1 = _block;
      let child = get1(node_index + 1, children);
      loop$node = child;
      loop$shift = shift - branch_bits;
      loop$index = index$1;
    } else {
      let children = node.children;
      return get1(index4 + 1, children);
    }
  }
}
var branch_factor = 32;

// build/dev/javascript/iv/iv/internal/builder.mjs
var Builder = class extends CustomType {
  constructor(nodes2, items, push_node, push_item) {
    super();
    this.nodes = nodes2;
    this.items = items;
    this.push_node = push_node;
    this.push_item = push_item;
  }
};
function append_node(nodes2, node, shift) {
  if (nodes2 instanceof Empty) {
    return toList([singleton(node)]);
  } else {
    let nodes$1 = nodes2.head;
    let rest = nodes2.tail;
    let $ = length2(nodes$1) < branch_factor;
    if ($) {
      return prepend(append4(nodes$1, node), rest);
    } else {
      let shift$1 = shift + branch_bits;
      let new_node = balanced(shift$1, nodes$1);
      return prepend(
        singleton(node),
        append_node(rest, new_node, shift$1)
      );
    }
  }
}
function new$10() {
  return new Builder(toList([]), empty3(), append_node, append4);
}
function push(builder, item) {
  let nodes2;
  let items;
  let push_node;
  let push_item;
  nodes2 = builder.nodes;
  items = builder.items;
  push_node = builder.push_node;
  push_item = builder.push_item;
  let $ = length2(items) === branch_factor;
  if ($) {
    let leaf2 = leaf(items);
    return new Builder(
      push_node(nodes2, leaf2, 0),
      singleton(item),
      push_node,
      push_item
    );
  } else {
    return new Builder(nodes2, push_item(items, item), push_node, push_item);
  }
}
function compress_nodes(loop$nodes, loop$push_node, loop$shift) {
  while (true) {
    let nodes2 = loop$nodes;
    let push_node = loop$push_node;
    let shift = loop$shift;
    if (nodes2 instanceof Empty) {
      return new Error2(void 0);
    } else {
      let $ = nodes2.tail;
      if ($ instanceof Empty) {
        let root3 = nodes2.head;
        return new Ok([shift, root3]);
      } else {
        let nodes$1 = nodes2.head;
        let rest = $;
        let shift$1 = shift + branch_bits;
        let compressed = push_node(
          rest,
          branch(shift$1, nodes$1),
          shift$1
        );
        loop$nodes = compressed;
        loop$push_node = push_node;
        loop$shift = shift$1;
      }
    }
  }
}
function build2(builder) {
  let nodes2;
  let items;
  let push_node;
  nodes2 = builder.nodes;
  items = builder.items;
  push_node = builder.push_node;
  let items_len = length2(items);
  let _block;
  let $ = items_len > 0;
  if ($) {
    _block = push_node(nodes2, leaf(items), 0);
  } else {
    _block = nodes2;
  }
  let nodes$1 = _block;
  return compress_nodes(nodes$1, push_node, 0);
}

// build/dev/javascript/iv/iv.mjs
var Empty2 = class extends CustomType {
};
var Array2 = class extends CustomType {
  constructor(shift, root3) {
    super();
    this.shift = shift;
    this.root = root3;
  }
};
function array3(shift, nodes2) {
  let $ = length2(nodes2);
  if ($ === 0) {
    return new Empty2();
  } else if ($ === 1) {
    return new Array2(shift, get1(1, nodes2));
  } else {
    let shift$1 = shift + branch_bits;
    return new Array2(shift$1, branch(shift$1, nodes2));
  }
}
function from_list3(list4) {
  let $ = (() => {
    let _pipe = list4;
    let _pipe$1 = fold2(_pipe, new$10(), push);
    return build2(_pipe$1);
  })();
  if ($ instanceof Ok) {
    let shift = $[0][0];
    let nodes2 = $[0][1];
    return array3(shift, nodes2);
  } else {
    return new Empty2();
  }
}
function get3(array4, index4) {
  if (array4 instanceof Empty2) {
    return new Error2(void 0);
  } else {
    let shift = array4.shift;
    let root3 = array4.root;
    let $ = 0 <= index4 && index4 < size3(root3);
    if ($) {
      return new Ok(get2(root3, shift, index4));
    } else {
      return new Error2(void 0);
    }
  }
}

// build/dev/javascript/gleam_regexp/gleam_regexp_ffi.mjs
function check(regex, string5) {
  regex.lastIndex = 0;
  return regex.test(string5);
}
function compile(pattern, options) {
  try {
    let flags = "gu";
    if (options.case_insensitive) flags += "i";
    if (options.multi_line) flags += "m";
    return new Ok(new RegExp(pattern, flags));
  } catch (error) {
    const number = (error.columnNumber || 0) | 0;
    return new Error2(new CompileError(error.message, number));
  }
}

// build/dev/javascript/gleam_regexp/gleam/regexp.mjs
var CompileError = class extends CustomType {
  constructor(error, byte_index) {
    super();
    this.error = error;
    this.byte_index = byte_index;
  }
};
var Options = class extends CustomType {
  constructor(case_insensitive, multi_line) {
    super();
    this.case_insensitive = case_insensitive;
    this.multi_line = multi_line;
  }
};
function compile2(pattern, options) {
  return compile(pattern, options);
}
function from_string(pattern) {
  return compile2(pattern, new Options(false, false));
}
function check2(regexp, string5) {
  return check(regexp, string5);
}

// build/dev/javascript/nibble/nibble/lexer.mjs
var FILEPATH6 = "src/nibble/lexer.gleam";
var Matcher = class extends CustomType {
  constructor(run4) {
    super();
    this.run = run4;
  }
};
var Keep = class extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
};
var Skip = class extends CustomType {
};
var Drop = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var NoMatch = class extends CustomType {
};
var Token = class extends CustomType {
  constructor(span2, lexeme, value) {
    super();
    this.span = span2;
    this.lexeme = lexeme;
    this.value = value;
  }
};
var Span = class extends CustomType {
  constructor(row_start, col_start, row_end, col_end) {
    super();
    this.row_start = row_start;
    this.col_start = col_start;
    this.row_end = row_end;
    this.col_end = col_end;
  }
};
var NoMatchFound = class extends CustomType {
  constructor(row, col, lexeme) {
    super();
    this.row = row;
    this.col = col;
    this.lexeme = lexeme;
  }
};
var Lexer = class extends CustomType {
  constructor(matchers) {
    super();
    this.matchers = matchers;
  }
};
var State = class extends CustomType {
  constructor(source, tokens2, current, row, col) {
    super();
    this.source = source;
    this.tokens = tokens2;
    this.current = current;
    this.row = row;
    this.col = col;
  }
};
function simple2(matchers) {
  return new Lexer((_) => {
    return matchers;
  });
}
function ignore(matcher) {
  return new Matcher(
    (mode, lexeme, lookahead) => {
      let $ = matcher.run(mode, lexeme, lookahead);
      if ($ instanceof Keep) {
        let mode$1 = $[1];
        return new Drop(mode$1);
      } else if ($ instanceof Skip) {
        return $;
      } else if ($ instanceof Drop) {
        return $;
      } else {
        return $;
      }
    }
  );
}
function token2(str, value) {
  return new Matcher(
    (mode, lexeme, _) => {
      let $ = lexeme === str;
      if ($) {
        return new Keep(value, mode);
      } else {
        return new NoMatch();
      }
    }
  );
}
function identifier(start4, inner, reserved, to_value) {
  let $ = from_string("^" + start4 + inner + "*$");
  let ident;
  if ($ instanceof Ok) {
    ident = $[0];
  } else {
    throw makeError(
      "let_assert",
      FILEPATH6,
      "nibble/lexer",
      486,
      "identifier",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 14767,
        end: 14839,
        pattern_start: 14778,
        pattern_end: 14787
      }
    );
  }
  let $1 = from_string(inner);
  let inner$1;
  if ($1 instanceof Ok) {
    inner$1 = $1[0];
  } else {
    throw makeError(
      "let_assert",
      FILEPATH6,
      "nibble/lexer",
      487,
      "identifier",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $1,
        start: 14842,
        end: 14890,
        pattern_start: 14853,
        pattern_end: 14862
      }
    );
  }
  return new Matcher(
    (mode, lexeme, lookahead) => {
      let $2 = check2(inner$1, lookahead);
      let $3 = check2(ident, lexeme);
      if ($3) {
        if ($2) {
          return new Skip();
        } else {
          let $4 = contains(reserved, lexeme);
          if ($4) {
            return new NoMatch();
          } else {
            return new Keep(to_value(lexeme), mode);
          }
        }
      } else {
        return new NoMatch();
      }
    }
  );
}
function whitespace(token4) {
  let $ = from_string("^\\s+$");
  let whitespace$1;
  if ($ instanceof Ok) {
    whitespace$1 = $[0];
  } else {
    throw makeError(
      "let_assert",
      FILEPATH6,
      "nibble/lexer",
      557,
      "whitespace",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 16378,
        end: 16434,
        pattern_start: 16389,
        pattern_end: 16403
      }
    );
  }
  return new Matcher(
    (mode, lexeme, _) => {
      let $1 = check2(whitespace$1, lexeme);
      if ($1) {
        return new Keep(token4, mode);
      } else {
        return new NoMatch();
      }
    }
  );
}
function do_match(mode, str, lookahead, matchers) {
  return fold_until(
    matchers,
    new NoMatch(),
    (_, matcher) => {
      let $ = matcher.run(mode, str, lookahead);
      if ($ instanceof Keep) {
        let match2 = $;
        return new Stop(match2);
      } else if ($ instanceof Skip) {
        return new Stop(new Skip());
      } else if ($ instanceof Drop) {
        let match2 = $;
        return new Stop(match2);
      } else {
        return new Continue(new NoMatch());
      }
    }
  );
}
function next_col(col, str) {
  if (str === "\n") {
    return 1;
  } else {
    return col + 1;
  }
}
function next_row(row, str) {
  if (str === "\n") {
    return row + 1;
  } else {
    return row;
  }
}
function do_run(loop$lexer, loop$mode, loop$state) {
  while (true) {
    let lexer = loop$lexer;
    let mode = loop$mode;
    let state = loop$state;
    let matchers = lexer.matchers(mode);
    let $ = state.source;
    let $1 = state.current;
    if ($ instanceof Empty) {
      let $2 = $1[2];
      if ($2 === "") {
        return new Ok(reverse(state.tokens));
      } else {
        let start_row = $1[0];
        let start_col = $1[1];
        let lexeme = $2;
        let $3 = do_match(mode, lexeme, "", matchers);
        if ($3 instanceof Keep) {
          let value = $3[0];
          let span2 = new Span(start_row, start_col, state.row, state.col);
          let token$1 = new Token(span2, lexeme, value);
          return new Ok(reverse(prepend(token$1, state.tokens)));
        } else if ($3 instanceof Skip) {
          return new Error2(new NoMatchFound(start_row, start_col, lexeme));
        } else if ($3 instanceof Drop) {
          return new Ok(reverse(state.tokens));
        } else {
          return new Error2(new NoMatchFound(start_row, start_col, lexeme));
        }
      }
    } else {
      let start_row = $1[0];
      let start_col = $1[1];
      let lexeme = $1[2];
      let lookahead = $.head;
      let rest = $.tail;
      let row = next_row(state.row, lookahead);
      let col = next_col(state.col, lookahead);
      let $2 = do_match(mode, lexeme, lookahead, matchers);
      if ($2 instanceof Keep) {
        let value = $2[0];
        let mode$1 = $2[1];
        let span2 = new Span(start_row, start_col, state.row, state.col);
        let token$1 = new Token(span2, lexeme, value);
        loop$lexer = lexer;
        loop$mode = mode$1;
        loop$state = new State(
          rest,
          prepend(token$1, state.tokens),
          [state.row, state.col, lookahead],
          row,
          col
        );
      } else if ($2 instanceof Skip) {
        loop$lexer = lexer;
        loop$mode = mode;
        loop$state = new State(
          rest,
          state.tokens,
          [start_row, start_col, lexeme + lookahead],
          row,
          col
        );
      } else if ($2 instanceof Drop) {
        let mode$1 = $2[0];
        loop$lexer = lexer;
        loop$mode = mode$1;
        loop$state = new State(
          rest,
          state.tokens,
          [state.row, state.col, lookahead],
          row,
          col
        );
      } else {
        loop$lexer = lexer;
        loop$mode = mode;
        loop$state = new State(
          rest,
          state.tokens,
          [start_row, start_col, lexeme + lookahead],
          row,
          col
        );
      }
    }
  }
}
function run2(source, lexer) {
  let _pipe = graphemes(source);
  let _pipe$1 = new State(_pipe, toList([]), [1, 1, ""], 1, 1);
  return ((_capture) => {
    return do_run(lexer, void 0, _capture);
  })(_pipe$1);
}
function int_with_separator(separator, to_value) {
  let $ = from_string("[0-9" + separator + "]");
  let digit;
  if ($ instanceof Ok) {
    digit = $[0];
  } else {
    throw makeError(
      "let_assert",
      FILEPATH6,
      "nibble/lexer",
      356,
      "int_with_separator",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 11580,
        end: 11649,
        pattern_start: 11591,
        pattern_end: 11600
      }
    );
  }
  let $1 = from_string("^-*[0-9" + separator + "]+$");
  let integer2;
  if ($1 instanceof Ok) {
    integer2 = $1[0];
  } else {
    throw makeError(
      "let_assert",
      FILEPATH6,
      "nibble/lexer",
      357,
      "int_with_separator",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $1,
        start: 11652,
        end: 11728,
        pattern_start: 11663,
        pattern_end: 11674
      }
    );
  }
  return new Matcher(
    (mode, lexeme, lookahead) => {
      let $2 = !check2(digit, lookahead) && check2(
        integer2,
        lexeme
      );
      if ($2) {
        let _block;
        let _pipe = lexeme;
        let _pipe$1 = replace(_pipe, separator, "");
        _block = parse_int(_pipe$1);
        let $3 = _block;
        let num;
        if ($3 instanceof Ok) {
          num = $3[0];
        } else {
          throw makeError(
            "let_assert",
            FILEPATH6,
            "nibble/lexer",
            364,
            "int_with_separator",
            "Pattern match failed, no pattern matched the value.",
            {
              value: $3,
              start: 11887,
              end: 11984,
              pattern_start: 11898,
              pattern_end: 11905
            }
          );
        }
        return new Keep(to_value(num), mode);
      } else {
        return new NoMatch();
      }
    }
  );
}
function int5(to_value) {
  return int_with_separator("", to_value);
}

// build/dev/javascript/nibble/nibble.mjs
var Parser = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var Cont = class extends CustomType {
  constructor($0, $1, $2) {
    super();
    this[0] = $0;
    this[1] = $1;
    this[2] = $2;
  }
};
var Fail = class extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
};
var State2 = class extends CustomType {
  constructor(src, idx, pos, ctx) {
    super();
    this.src = src;
    this.idx = idx;
    this.pos = pos;
    this.ctx = ctx;
  }
};
var CanBacktrack = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var Continue2 = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var Break = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var EndOfInput = class extends CustomType {
};
var Expected = class extends CustomType {
  constructor($0, got) {
    super();
    this[0] = $0;
    this.got = got;
  }
};
var DeadEnd = class extends CustomType {
  constructor(pos, problem, context) {
    super();
    this.pos = pos;
    this.problem = problem;
    this.context = context;
  }
};
var Empty3 = class extends CustomType {
};
var Cons = class extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
};
var Append = class extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
};
function runwrap(state, parser) {
  let parse2;
  parse2 = parser[0];
  return parse2(state);
}
function next(state) {
  let $ = get3(state.src, state.idx);
  if ($ instanceof Ok) {
    let span$1 = $[0].span;
    let tok = $[0].value;
    return [
      new Some(tok),
      new State2(state.src, state.idx + 1, span$1, state.ctx)
    ];
  } else {
    return [new None(), state];
  }
}
function return$(value) {
  return new Parser(
    (state) => {
      return new Cont(new CanBacktrack(false), value, state);
    }
  );
}
function lazy(parser) {
  return new Parser((state) => {
    return runwrap(state, parser());
  });
}
function should_commit(a2, b) {
  let a$1;
  a$1 = a2[0];
  let b$1;
  b$1 = b[0];
  return new CanBacktrack(a$1 || b$1);
}
function do$(parser, f) {
  return new Parser(
    (state) => {
      let $ = runwrap(state, parser);
      if ($ instanceof Cont) {
        let to_a = $[0];
        let a2 = $[1];
        let state$1 = $[2];
        let $1 = runwrap(state$1, f(a2));
        if ($1 instanceof Cont) {
          let to_b = $1[0];
          let b = $1[1];
          let state$2 = $1[2];
          return new Cont(should_commit(to_a, to_b), b, state$2);
        } else {
          let to_b = $1[0];
          let bag = $1[1];
          return new Fail(should_commit(to_a, to_b), bag);
        }
      } else {
        return $;
      }
    }
  );
}
function then$2(parser, f) {
  return do$(parser, f);
}
function loop_help(loop$f, loop$commit, loop$loop_state, loop$state) {
  while (true) {
    let f = loop$f;
    let commit = loop$commit;
    let loop_state = loop$loop_state;
    let state = loop$state;
    let $ = runwrap(state, f(loop_state));
    if ($ instanceof Cont) {
      let $1 = $[1];
      if ($1 instanceof Continue2) {
        let can_backtrack = $[0];
        let next_state = $[2];
        let next_loop_state = $1[0];
        loop$f = f;
        loop$commit = should_commit(commit, can_backtrack);
        loop$loop_state = next_loop_state;
        loop$state = next_state;
      } else {
        let can_backtrack = $[0];
        let next_state = $[2];
        let result = $1[0];
        return new Cont(
          should_commit(commit, can_backtrack),
          result,
          next_state
        );
      }
    } else {
      let can_backtrack = $[0];
      let bag = $[1];
      return new Fail(should_commit(commit, can_backtrack), bag);
    }
  }
}
function loop(init2, step) {
  return new Parser(
    (state) => {
      return loop_help(step, new CanBacktrack(false), init2, state);
    }
  );
}
function bag_from_state(state, problem) {
  return new Cons(new Empty3(), new DeadEnd(state.pos, problem, state.ctx));
}
function token3(tok) {
  return new Parser(
    (state) => {
      let $ = next(state);
      let $1 = $[0];
      if ($1 instanceof Some) {
        let t = $1[0];
        if (isEqual(tok, t)) {
          let state$1 = $[1];
          return new Cont(new CanBacktrack(true), void 0, state$1);
        } else {
          let state$1 = $[1];
          let t$1 = $1[0];
          return new Fail(
            new CanBacktrack(false),
            bag_from_state(state$1, new Expected(inspect2(tok), t$1))
          );
        }
      } else {
        let state$1 = $[1];
        return new Fail(
          new CanBacktrack(false),
          bag_from_state(state$1, new EndOfInput())
        );
      }
    }
  );
}
function take_map(expecting, f) {
  return new Parser(
    (state) => {
      let $ = next(state);
      let tok;
      let next_state;
      tok = $[0];
      next_state = $[1];
      let $1 = then$(tok, f);
      if (tok instanceof Some) {
        if ($1 instanceof Some) {
          let a2 = $1[0];
          return new Cont(new CanBacktrack(false), a2, next_state);
        } else {
          let tok$1 = tok[0];
          return new Fail(
            new CanBacktrack(false),
            bag_from_state(next_state, new Expected(expecting, tok$1))
          );
        }
      } else {
        return new Fail(
          new CanBacktrack(false),
          bag_from_state(next_state, new EndOfInput())
        );
      }
    }
  );
}
function to_deadends(loop$bag, loop$acc) {
  while (true) {
    let bag = loop$bag;
    let acc = loop$acc;
    if (bag instanceof Empty3) {
      return acc;
    } else if (bag instanceof Cons) {
      let $ = bag[0];
      if ($ instanceof Empty3) {
        let deadend = bag[1];
        return prepend(deadend, acc);
      } else {
        let bag$1 = $;
        let deadend = bag[1];
        loop$bag = bag$1;
        loop$acc = prepend(deadend, acc);
      }
    } else {
      let left = bag[0];
      let right = bag[1];
      loop$bag = left;
      loop$acc = to_deadends(right, acc);
    }
  }
}
function run3(src, parser) {
  let init2 = new State2(from_list3(src), 0, new Span(1, 1, 1, 1), toList([]));
  let $ = runwrap(init2, parser);
  if ($ instanceof Cont) {
    let a2 = $[1];
    return new Ok(a2);
  } else {
    let bag = $[1];
    return new Error2(to_deadends(bag, toList([])));
  }
}
function add_bag_to_step(step, left) {
  if (step instanceof Cont) {
    return step;
  } else {
    let can_backtrack = step[0];
    let right = step[1];
    return new Fail(can_backtrack, new Append(left, right));
  }
}
function one_of2(parsers) {
  return new Parser(
    (state) => {
      let init2 = new Fail(new CanBacktrack(false), new Empty3());
      return fold_until(
        parsers,
        init2,
        (result, next2) => {
          if (result instanceof Cont) {
            return new Stop(result);
          } else {
            let $ = result[0][0];
            if ($) {
              return new Stop(result);
            } else {
              let bag = result[1];
              let _pipe = runwrap(state, next2);
              let _pipe$1 = add_bag_to_step(_pipe, bag);
              return new Continue(_pipe$1);
            }
          }
        }
      );
    }
  );
}
function more(x, parser, separator) {
  return loop(
    toList([x]),
    (xs) => {
      let break$ = () => {
        return return$(new Break(reverse(xs)));
      };
      let continue$ = do$(
        separator,
        (_) => {
          return do$(
            parser,
            (x2) => {
              return return$(new Continue2(prepend(x2, xs)));
            }
          );
        }
      );
      return one_of2(toList([continue$, lazy(break$)]));
    }
  );
}
function sequence(parser, sep) {
  return one_of2(
    toList([
      (() => {
        let _pipe = parser;
        return then$2(
          _pipe,
          (_capture) => {
            return more(_capture, parser, sep);
          }
        );
      })(),
      return$(toList([]))
    ])
  );
}
function many(parser) {
  return sequence(parser, return$(void 0));
}
function many1(parser) {
  return do$(
    parser,
    (x) => {
      return do$(many(parser), (xs) => {
        return return$(prepend(x, xs));
      });
    }
  );
}

// build/dev/javascript/eoc/eoc/passes/parse.mjs
var FILEPATH7 = "src/eoc/passes/parse.gleam";
var LParen = class extends CustomType {
};
var RParen = class extends CustomType {
};
var LBracket = class extends CustomType {
};
var RBracket = class extends CustomType {
};
var Integer = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var Boolean = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var Keyword = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var Cmp4 = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var Identifier = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var Read4 = class extends CustomType {
};
var Let3 = class extends CustomType {
};
var Plus4 = class extends CustomType {
};
var Minus4 = class extends CustomType {
};
var And2 = class extends CustomType {
};
var Or2 = class extends CustomType {
};
var Not4 = class extends CustomType {
};
var If4 = class extends CustomType {
};
var SetBang3 = class extends CustomType {
};
var Begin3 = class extends CustomType {
};
var While = class extends CustomType {
};
var Void4 = class extends CustomType {
};
function tokens(input) {
  let l = simple2(
    toList([
      int5((var0) => {
        return new Integer(var0);
      }),
      token2("(", new LParen()),
      token2(")", new RParen()),
      token2("[", new LBracket()),
      token2("]", new RBracket()),
      token2("#t", new Boolean(true)),
      token2("#f", new Boolean(false)),
      ignore(whitespace(void 0)),
      identifier(
        "[^0-9()\\[\\]{}\",'`;#|\\\\\\s]",
        "[^()\\[\\]{}\",'`;#|\\\\\\s]",
        new$(),
        (text4) => {
          if (text4 === "+") {
            return new Keyword(new Plus4());
          } else if (text4 === "-") {
            return new Keyword(new Minus4());
          } else if (text4 === ">=") {
            return new Cmp4(new Gte());
          } else if (text4 === "<=") {
            return new Cmp4(new Lte());
          } else if (text4 === ">") {
            return new Cmp4(new Gt2());
          } else if (text4 === "<") {
            return new Cmp4(new Lt2());
          } else if (text4 === "if") {
            return new Keyword(new If4());
          } else if (text4 === "eq?") {
            return new Cmp4(new Eq2());
          } else if (text4 === "set!") {
            return new Keyword(new SetBang3());
          } else if (text4 === "read") {
            return new Keyword(new Read4());
          } else if (text4 === "let") {
            return new Keyword(new Let3());
          } else if (text4 === "and") {
            return new Keyword(new And2());
          } else if (text4 === "or") {
            return new Keyword(new Or2());
          } else if (text4 === "not") {
            return new Keyword(new Not4());
          } else if (text4 === "begin") {
            return new Keyword(new Begin3());
          } else if (text4 === "while") {
            return new Keyword(new While());
          } else if (text4 === "void") {
            return new Keyword(new Void4());
          } else {
            let id = text4;
            return new Identifier(id);
          }
        }
      )
    ])
  );
  return run2(input, l);
}
function read_op() {
  return do$(
    token3(new Keyword(new Read4())),
    (_) => {
      return return$(new Read());
    }
  );
}
function void_op() {
  return do$(
    token3(new Keyword(new Void4())),
    (_) => {
      return return$(new Void());
    }
  );
}
function cmp_inner() {
  return take_map(
    "expected comparison op",
    (tok) => {
      if (tok instanceof Cmp4) {
        let op = tok[0];
        return new Some(op);
      } else {
        return new None();
      }
    }
  );
}
function boolean() {
  return take_map(
    "expected boolean",
    (tok) => {
      if (tok instanceof Boolean) {
        let b = tok[0];
        return new Some(new Bool(b));
      } else {
        return new None();
      }
    }
  );
}
function integer() {
  return take_map(
    "expected integer",
    (tok) => {
      if (tok instanceof Integer) {
        let i = tok[0];
        return new Some(new Int(i));
      } else {
        return new None();
      }
    }
  );
}
function identifier2() {
  return take_map(
    "expected identifier",
    (tok) => {
      if (tok instanceof Identifier) {
        let v = tok[0];
        return new Some(v);
      } else {
        return new None();
      }
    }
  );
}
function variable() {
  return do$(identifier2(), (id) => {
    return return$(new Var(id));
  });
}
function begin_expr() {
  return do$(
    token3(new Keyword(new Begin3())),
    (_) => {
      return do$(
        many1(expression()),
        (exprs) => {
          let $ = reverse(exprs);
          let result;
          let stmts;
          if ($ instanceof Empty) {
            throw makeError(
              "let_assert",
              FILEPATH7,
              "eoc/passes/parse",
              112,
              "begin_expr",
              "Pattern match failed, no pattern matched the value.",
              {
                value: $,
                start: 2483,
                end: 2533,
                pattern_start: 2494,
                pattern_end: 2511
              }
            );
          } else {
            result = $.head;
            stmts = $.tail;
          }
          return return$(new Begin(reverse(stmts), result));
        }
      );
    }
  );
}
function expression() {
  return one_of2(toList([integer(), boolean(), variable(), nested()]));
}
function nested() {
  return do$(
    token3(new LParen()),
    (_) => {
      return do$(
        one_of2(
          toList([
            if_expr(),
            let_expr(),
            primitive(),
            begin_expr(),
            while_expr(),
            set_expr()
          ])
        ),
        (expr) => {
          return do$(
            token3(new RParen()),
            (_2) => {
              return return$(expr);
            }
          );
        }
      );
    }
  );
}
function program() {
  return do$(
    expression(),
    (body) => {
      return return$(new Program(body));
    }
  );
}
function parse(tokens2) {
  return run3(tokens2, program());
}
function while_expr() {
  return do$(
    token3(new Keyword(new While())),
    (_) => {
      return do$(
        expression(),
        (condition) => {
          return do$(
            expression(),
            (body) => {
              return return$(new WhileLoop(condition, body));
            }
          );
        }
      );
    }
  );
}
function set_expr() {
  return do$(
    token3(new Keyword(new SetBang3())),
    (_) => {
      return do$(
        identifier2(),
        (var$2) => {
          return do$(
            expression(),
            (value) => {
              return return$(new SetBang(var$2, value));
            }
          );
        }
      );
    }
  );
}
function if_expr() {
  return do$(
    token3(new Keyword(new If4())),
    (_) => {
      return do$(
        expression(),
        (condition) => {
          return do$(
            expression(),
            (if_true) => {
              return do$(
                expression(),
                (if_false) => {
                  return return$(new If(condition, if_true, if_false));
                }
              );
            }
          );
        }
      );
    }
  );
}
function let_expr() {
  return do$(
    token3(new Keyword(new Let3())),
    (_) => {
      return do$(
        token3(new LParen()),
        (_2) => {
          return do$(
            token3(new LBracket()),
            (_3) => {
              return do$(
                identifier2(),
                (var$2) => {
                  return do$(
                    expression(),
                    (binding) => {
                      return do$(
                        token3(new RBracket()),
                        (_4) => {
                          return do$(
                            token3(new RParen()),
                            (_5) => {
                              return do$(
                                expression(),
                                (expr) => {
                                  return return$(
                                    new Let(var$2, binding, expr)
                                  );
                                }
                              );
                            }
                          );
                        }
                      );
                    }
                  );
                }
              );
            }
          );
        }
      );
    }
  );
}
function minus_op() {
  return do$(
    token3(new Keyword(new Minus4())),
    (_) => {
      return do$(
        expression(),
        (arg1) => {
          return do$(
            expression(),
            (arg2) => {
              return return$(new Minus(arg1, arg2));
            }
          );
        }
      );
    }
  );
}
function negate_op() {
  return do$(
    token3(new Keyword(new Minus4())),
    (_) => {
      return do$(
        expression(),
        (expr) => {
          return return$(new Negate(expr));
        }
      );
    }
  );
}
function plus_op() {
  return do$(
    token3(new Keyword(new Plus4())),
    (_) => {
      return do$(
        expression(),
        (arg1) => {
          return do$(
            expression(),
            (arg2) => {
              return return$(new Plus(arg1, arg2));
            }
          );
        }
      );
    }
  );
}
function cmp_op() {
  return do$(
    cmp_inner(),
    (op) => {
      return do$(
        expression(),
        (arg1) => {
          return do$(
            expression(),
            (arg2) => {
              return return$(new Cmp(op, arg1, arg2));
            }
          );
        }
      );
    }
  );
}
function and_op() {
  return do$(
    token3(new Keyword(new And2())),
    (_) => {
      return do$(
        expression(),
        (arg1) => {
          return do$(
            expression(),
            (arg2) => {
              return return$(new And(arg1, arg2));
            }
          );
        }
      );
    }
  );
}
function or_op() {
  return do$(
    token3(new Keyword(new Or2())),
    (_) => {
      return do$(
        expression(),
        (arg1) => {
          return do$(
            expression(),
            (arg2) => {
              return return$(new Or(arg1, arg2));
            }
          );
        }
      );
    }
  );
}
function not_op() {
  return do$(
    token3(new Keyword(new Not4())),
    (_) => {
      return do$(
        expression(),
        (expr) => {
          return return$(new Not(expr));
        }
      );
    }
  );
}
function primitive() {
  return do$(
    one_of2(
      toList([
        void_op(),
        read_op(),
        minus_op(),
        negate_op(),
        plus_op(),
        cmp_op(),
        and_op(),
        or_op(),
        not_op()
      ])
    ),
    (prim_op) => {
      return return$(new Prim(prim_op));
    }
  );
}

// build/dev/javascript/eoc/eoc/passes/patch_instructions.mjs
var FILEPATH8 = "src/eoc/passes/patch_instructions.gleam";
function patch_instruction(instr) {
  if (instr instanceof Addq) {
    let $ = instr.b;
    if ($ instanceof Deref) {
      let $1 = instr.a;
      if ($1 instanceof Deref) {
        let a2 = $1;
        let b = $;
        return toList([
          new Movq(a2, new Reg(new Rax())),
          new Addq(new Reg(new Rax()), b)
        ]);
      } else {
        let other = instr;
        return toList([other]);
      }
    } else {
      let other = instr;
      return toList([other]);
    }
  } else if (instr instanceof Subq) {
    let $ = instr.b;
    if ($ instanceof Deref) {
      let $1 = instr.a;
      if ($1 instanceof Deref) {
        let a2 = $1;
        let b = $;
        return toList([
          new Movq(a2, new Reg(new Rax())),
          new Subq(new Reg(new Rax()), b)
        ]);
      } else {
        let other = instr;
        return toList([other]);
      }
    } else {
      let other = instr;
      return toList([other]);
    }
  } else if (instr instanceof Movq) {
    let a2 = instr.a;
    let b = instr.b;
    if (isEqual(a2, b)) {
      return toList([]);
    } else {
      let $ = instr.b;
      if ($ instanceof Deref) {
        let $1 = instr.a;
        if ($1 instanceof Deref) {
          let a$1 = $1;
          let b$1 = $;
          return toList([
            new Movq(a$1, new Reg(new Rax())),
            new Movq(new Reg(new Rax()), b$1)
          ]);
        } else {
          let other = instr;
          return toList([other]);
        }
      } else {
        let other = instr;
        return toList([other]);
      }
    }
  } else if (instr instanceof Cmpq) {
    let $ = instr.b;
    if ($ instanceof Imm) {
      let a2 = instr.a;
      let b = $;
      return toList([
        new Movq(b, new Reg(new Rax())),
        new Cmpq(a2, new Reg(new Rax()))
      ]);
    } else {
      let other = instr;
      return toList([other]);
    }
  } else if (instr instanceof Movzbq) {
    let $ = instr.b;
    if ($ instanceof Imm) {
      throw makeError(
        "panic",
        FILEPATH8,
        "eoc/passes/patch_instructions",
        61,
        "patch_instruction",
        "invalid movzbq instruction",
        {}
      );
    } else if ($ instanceof Deref) {
      let a2 = instr.a;
      let b = $;
      return toList([
        new Movzbq(a2, new Reg(new Rax())),
        new Movq(new Reg(new Rax()), b)
      ]);
    } else {
      let other = instr;
      return toList([other]);
    }
  } else {
    let other = instr;
    return toList([other]);
  }
}
function patch_instructions_block(instrs) {
  return flat_map(instrs, patch_instruction);
}
function patch_instructions(input) {
  let _block;
  let _pipe = input.body;
  _block = map_values(
    _pipe,
    (_, block) => {
      return new Block(patch_instructions_block(block.body));
    }
  );
  let body = _block;
  return new X86Program(body, input.stack_vars, input.used_callee);
}

// build/dev/javascript/eoc/eoc/langs/l_while_get.mjs
var Read5 = class extends CustomType {
};
var Void5 = class extends CustomType {
};
var Negate3 = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Plus5 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Minus5 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Cmp5 = class extends CustomType {
  constructor(op, a2, b) {
    super();
    this.op = op;
    this.a = a2;
    this.b = b;
  }
};
var And3 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Or3 = class extends CustomType {
  constructor(a2, b) {
    super();
    this.a = a2;
    this.b = b;
  }
};
var Not5 = class extends CustomType {
  constructor(a2) {
    super();
    this.a = a2;
  }
};
var Int4 = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Bool4 = class extends CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
};
var Prim4 = class extends CustomType {
  constructor(op) {
    super();
    this.op = op;
  }
};
var Var4 = class extends CustomType {
  constructor(name) {
    super();
    this.name = name;
  }
};
var Let4 = class extends CustomType {
  constructor(var$2, binding, expr) {
    super();
    this.var = var$2;
    this.binding = binding;
    this.expr = expr;
  }
};
var If5 = class extends CustomType {
  constructor(condition, if_true, if_false) {
    super();
    this.condition = condition;
    this.if_true = if_true;
    this.if_false = if_false;
  }
};
var SetBang4 = class extends CustomType {
  constructor(var$2, value) {
    super();
    this.var = var$2;
    this.value = value;
  }
};
var GetBang2 = class extends CustomType {
  constructor(var$2) {
    super();
    this.var = var$2;
  }
};
var Begin4 = class extends CustomType {
  constructor(stmts, result) {
    super();
    this.stmts = stmts;
    this.result = result;
  }
};
var WhileLoop3 = class extends CustomType {
  constructor(condition, body) {
    super();
    this.condition = condition;
    this.body = body;
  }
};
var Program3 = class extends CustomType {
  constructor(body) {
    super();
    this.body = body;
  }
};

// build/dev/javascript/eoc/eoc/passes/remove_complex_operands.mjs
var FILEPATH9 = "src/eoc/passes/remove_complex_operands.gleam";
function new_var(counter) {
  let new_count = counter + 1;
  let name = "tmp." + to_string(new_count);
  return [name, new_count];
}
function rco_atom(input, counter) {
  if (input instanceof Int4) {
    let i = input.value;
    return [new Int3(i), toList([]), counter];
  } else if (input instanceof Bool4) {
    let b = input.value;
    return [new Bool3(b), toList([]), counter];
  } else if (input instanceof Prim4) {
    let $ = input.op;
    if ($ instanceof Void5) {
      return [new Void3(), toList([]), counter];
    } else if ($ instanceof And3) {
      throw makeError(
        "panic",
        FILEPATH9,
        "eoc/passes/remove_complex_operands",
        55,
        "rco_atom",
        "shrink pass was not run before remove_complex_operands",
        {}
      );
    } else if ($ instanceof Or3) {
      throw makeError(
        "panic",
        FILEPATH9,
        "eoc/passes/remove_complex_operands",
        55,
        "rco_atom",
        "shrink pass was not run before remove_complex_operands",
        {}
      );
    } else {
      let $1 = rco_exp(input, counter);
      let expr;
      let counter_e;
      expr = $1[0];
      counter_e = $1[1];
      let $2 = new_var(counter_e);
      let var$2;
      let new_counter;
      var$2 = $2[0];
      new_counter = $2[1];
      return [new Var3(var$2), toList([[var$2, expr]]), new_counter];
    }
  } else if (input instanceof Var4) {
    let v = input.name;
    return [new Var3(v), toList([]), counter];
  } else if (input instanceof Let4) {
    let v = input.var;
    let b = input.binding;
    let e = input.expr;
    let $ = rco_exp(b, counter);
    let binding;
    let counter_b;
    binding = $[0];
    counter_b = $[1];
    let $1 = rco_exp(e, counter_b);
    let expr;
    let counter_e;
    expr = $1[0];
    counter_e = $1[1];
    let $2 = new_var(counter_e);
    let var$2;
    let new_counter;
    var$2 = $2[0];
    new_counter = $2[1];
    return [
      new Var3(var$2),
      toList([[var$2, new Let2(v, binding, expr)]]),
      new_counter
    ];
  } else if (input instanceof If5) {
    let c = input.condition;
    let t = input.if_true;
    let e = input.if_false;
    let $ = rco_exp(c, counter);
    let c1;
    let counter1;
    c1 = $[0];
    counter1 = $[1];
    let $1 = rco_exp(t, counter1);
    let t1;
    let counter2;
    t1 = $1[0];
    counter2 = $1[1];
    let $2 = rco_exp(e, counter2);
    let e1;
    let counter3;
    e1 = $2[0];
    counter3 = $2[1];
    let $3 = new_var(counter3);
    let var$2;
    let new_counter;
    var$2 = $3[0];
    new_counter = $3[1];
    return [
      new Var3(var$2),
      toList([[var$2, new If3(c1, t1, e1)]]),
      new_counter
    ];
  } else if (input instanceof SetBang4) {
    let var$2 = input.var;
    let value = input.value;
    let $ = rco_exp(value, counter);
    let value1;
    let counter1;
    value1 = $[0];
    counter1 = $[1];
    let $1 = new_var(counter1);
    let new_var$1;
    let new_counter;
    new_var$1 = $1[0];
    new_counter = $1[1];
    return [
      new Void3(),
      toList([[new_var$1, new SetBang2(var$2, value1)]]),
      new_counter
    ];
  } else if (input instanceof GetBang2) {
    let var$2 = input.var;
    let $ = new_var(counter);
    let new_var$1;
    let new_counter;
    new_var$1 = $[0];
    new_counter = $[1];
    return [
      new Var3(new_var$1),
      toList([[new_var$1, new GetBang(var$2)]]),
      new_counter
    ];
  } else if (input instanceof Begin4) {
    let stmts = input.stmts;
    let result = input.result;
    let $ = map_fold(
      stmts,
      counter,
      (c, s) => {
        return swap(rco_exp(s, c));
      }
    );
    let counter1;
    let stmts1;
    counter1 = $[0];
    stmts1 = $[1];
    let $1 = rco_exp(result, counter1);
    let result1;
    let counter2;
    result1 = $1[0];
    counter2 = $1[1];
    let $2 = new_var(counter2);
    let var$2;
    let new_counter;
    var$2 = $2[0];
    new_counter = $2[1];
    return [
      new Var3(var$2),
      toList([[var$2, new Begin2(stmts1, result1)]]),
      new_counter
    ];
  } else {
    let condition = input.condition;
    let body = input.body;
    let $ = rco_exp(condition, counter);
    let condition1;
    let counter1;
    condition1 = $[0];
    counter1 = $[1];
    let $1 = rco_exp(body, counter1);
    let body1;
    let counter2;
    body1 = $1[0];
    counter2 = $1[1];
    let $2 = new_var(counter2);
    let new_var$1;
    let new_counter;
    new_var$1 = $2[0];
    new_counter = $2[1];
    return [
      new Void3(),
      toList([[new_var$1, new WhileLoop2(condition1, body1)]]),
      new_counter
    ];
  }
}
function rco_exp(input, counter) {
  if (input instanceof Int4) {
    let i = input.value;
    return [new Atomic(new Int3(i)), counter];
  } else if (input instanceof Bool4) {
    let value = input.value;
    return [new Atomic(new Bool3(value)), counter];
  } else if (input instanceof Prim4) {
    let $ = input.op;
    if ($ instanceof Read5) {
      return [new Prim3(new Read3()), counter];
    } else if ($ instanceof Void5) {
      return [new Atomic(new Void3()), counter];
    } else if ($ instanceof Negate3) {
      let e = $.value;
      let $1 = rco_atom(e, counter);
      let atm;
      let bindings;
      let new_counter;
      atm = $1[0];
      bindings = $1[1];
      new_counter = $1[2];
      let new_expr = fold2(
        bindings,
        new Prim3(new Negate2(atm)),
        (exp2, pair2) => {
          return new Let2(pair2[0], pair2[1], exp2);
        }
      );
      return [new_expr, new_counter];
    } else if ($ instanceof Plus5) {
      let a2 = $.a;
      let b = $.b;
      let $1 = rco_atom(a2, counter);
      let atm_a;
      let bindings_a;
      let counter_a;
      atm_a = $1[0];
      bindings_a = $1[1];
      counter_a = $1[2];
      let $2 = rco_atom(b, counter_a);
      let atm_b;
      let bindings_b;
      let counter_b;
      atm_b = $2[0];
      bindings_b = $2[1];
      counter_b = $2[2];
      let _block;
      let _pipe = bindings_a;
      let _pipe$1 = append3(_pipe, bindings_b);
      _block = fold_right(
        _pipe$1,
        new Prim3(new Plus3(atm_a, atm_b)),
        (exp2, pair2) => {
          return new Let2(pair2[0], pair2[1], exp2);
        }
      );
      let new_expr = _block;
      return [new_expr, counter_b];
    } else if ($ instanceof Minus5) {
      let a2 = $.a;
      let b = $.b;
      let $1 = rco_atom(a2, counter);
      let atm_a;
      let bindings_a;
      let counter_a;
      atm_a = $1[0];
      bindings_a = $1[1];
      counter_a = $1[2];
      let $2 = rco_atom(b, counter_a);
      let atm_b;
      let bindings_b;
      let counter_b;
      atm_b = $2[0];
      bindings_b = $2[1];
      counter_b = $2[2];
      let _block;
      let _pipe = bindings_a;
      let _pipe$1 = append3(_pipe, bindings_b);
      _block = fold_right(
        _pipe$1,
        new Prim3(new Minus3(atm_a, atm_b)),
        (exp2, pair2) => {
          return new Let2(pair2[0], pair2[1], exp2);
        }
      );
      let new_expr = _block;
      return [new_expr, counter_b];
    } else if ($ instanceof Cmp5) {
      let op = $.op;
      let a2 = $.a;
      let b = $.b;
      let $1 = rco_atom(a2, counter);
      let atm_a;
      let bindings_a;
      let counter_a;
      atm_a = $1[0];
      bindings_a = $1[1];
      counter_a = $1[2];
      let $2 = rco_atom(b, counter_a);
      let atm_b;
      let bindings_b;
      let counter_b;
      atm_b = $2[0];
      bindings_b = $2[1];
      counter_b = $2[2];
      let _block;
      let _pipe = bindings_a;
      let _pipe$1 = append3(_pipe, bindings_b);
      _block = fold_right(
        _pipe$1,
        new Prim3(new Cmp3(op, atm_a, atm_b)),
        (exp2, pair2) => {
          return new Let2(pair2[0], pair2[1], exp2);
        }
      );
      let new_expr = _block;
      return [new_expr, counter_b];
    } else if ($ instanceof And3) {
      throw makeError(
        "panic",
        FILEPATH9,
        "eoc/passes/remove_complex_operands",
        173,
        "rco_exp",
        "shrink pass was not run before remove_complex_operands",
        {}
      );
    } else if ($ instanceof Or3) {
      throw makeError(
        "panic",
        FILEPATH9,
        "eoc/passes/remove_complex_operands",
        173,
        "rco_exp",
        "shrink pass was not run before remove_complex_operands",
        {}
      );
    } else {
      let a2 = $.a;
      let $1 = rco_atom(a2, counter);
      let atm;
      let bindings;
      let new_counter;
      atm = $1[0];
      bindings = $1[1];
      new_counter = $1[2];
      let new_expr = fold2(
        bindings,
        new Prim3(new Not3(atm)),
        (exp2, pair2) => {
          return new Let2(pair2[0], pair2[1], exp2);
        }
      );
      return [new_expr, new_counter];
    }
  } else if (input instanceof Var4) {
    let v = input.name;
    return [new Atomic(new Var3(v)), counter];
  } else if (input instanceof Let4) {
    let v = input.var;
    let b = input.binding;
    let e = input.expr;
    let $ = rco_exp(b, counter);
    let binding;
    let new_counter;
    binding = $[0];
    new_counter = $[1];
    let $1 = rco_exp(e, new_counter);
    let expr;
    let new_counter1;
    expr = $1[0];
    new_counter1 = $1[1];
    return [new Let2(v, binding, expr), new_counter1];
  } else if (input instanceof If5) {
    let condition = input.condition;
    let if_true = input.if_true;
    let if_false = input.if_false;
    let $ = rco_exp(condition, counter);
    let c1;
    let counter1;
    c1 = $[0];
    counter1 = $[1];
    let $1 = rco_exp(if_true, counter1);
    let t1;
    let counter2;
    t1 = $1[0];
    counter2 = $1[1];
    let $2 = rco_exp(if_false, counter2);
    let f1;
    let counter3;
    f1 = $2[0];
    counter3 = $2[1];
    return [new If3(c1, t1, f1), counter3];
  } else if (input instanceof SetBang4) {
    let var$2 = input.var;
    let value = input.value;
    let $ = rco_exp(value, counter);
    let value1;
    let counter1;
    value1 = $[0];
    counter1 = $[1];
    return [new SetBang2(var$2, value1), counter1];
  } else if (input instanceof GetBang2) {
    let var$2 = input.var;
    return [new GetBang(var$2), counter];
  } else if (input instanceof Begin4) {
    let stmts = input.stmts;
    let result = input.result;
    let $ = map_fold(
      stmts,
      counter,
      (c, s) => {
        return swap(rco_exp(s, c));
      }
    );
    let counter1;
    let stmts1;
    counter1 = $[0];
    stmts1 = $[1];
    let $1 = rco_exp(result, counter1);
    let result1;
    let counter2;
    result1 = $1[0];
    counter2 = $1[1];
    return [new Begin2(stmts1, result1), counter2];
  } else {
    let condition = input.condition;
    let body = input.body;
    let $ = rco_exp(condition, counter);
    let condition1;
    let counter1;
    condition1 = $[0];
    counter1 = $[1];
    let $1 = rco_exp(body, counter1);
    let body1;
    let counter2;
    body1 = $1[0];
    counter2 = $1[1];
    return [new WhileLoop2(condition1, body1), counter2];
  }
}
function remove_complex_operands(input) {
  let $ = rco_exp(input.body, 0);
  let rco;
  rco = $[0];
  return new Program2(rco);
}

// build/dev/javascript/eoc/eoc/passes/select_instructions.mjs
var FILEPATH10 = "src/eoc/passes/select_instructions.gleam";
function select_atm(input) {
  if (input instanceof Int2) {
    let i = input.value;
    return new Imm2(i);
  } else if (input instanceof Bool2) {
    let bool4 = input.value;
    if (bool4) {
      return new Imm2(1);
    } else {
      return new Imm2(0);
    }
  } else if (input instanceof Variable) {
    let v = input.v;
    return new Var2(v);
  } else {
    return new Imm2(0);
  }
}
function convert_op_to_cc(op) {
  if (op instanceof Eq2) {
    return new E();
  } else if (op instanceof Lt2) {
    return new L();
  } else if (op instanceof Lte) {
    return new Le();
  } else if (op instanceof Gt2) {
    return new G();
  } else {
    return new Ge();
  }
}
function select_stmt(input) {
  if (input instanceof Assign) {
    let $ = input.expr;
    if ($ instanceof Atom) {
      let v = input.var;
      let atm = $.atm;
      return toList([new Movq2(select_atm(atm), new Var2(v))]);
    } else {
      let $1 = $.op;
      if ($1 instanceof Read2) {
        let v = input.var;
        return toList([
          new Callq2("read_int", 0),
          new Movq2(new Reg2(new Rax()), new Var2(v))
        ]);
      } else if ($1 instanceof Neg) {
        let $2 = $1.a;
        if ($2 instanceof Variable) {
          let v = input.var;
          let v1 = $2.v;
          if (v === v1) {
            return toList([new Negq2(new Var2(v))]);
          } else {
            let v$1 = input.var;
            let atm = $2;
            return toList([
              new Movq2(select_atm(atm), new Var2(v$1)),
              new Negq2(new Var2(v$1))
            ]);
          }
        } else {
          let v = input.var;
          let atm = $2;
          return toList([
            new Movq2(select_atm(atm), new Var2(v)),
            new Negq2(new Var2(v))
          ]);
        }
      } else if ($1 instanceof Not2) {
        let var$2 = input.var;
        let a2 = $1.a;
        return toList([
          new Movq2(select_atm(a2), new Var2(var$2)),
          new Xorq2(new Imm2(1), new Var2(var$2))
        ]);
      } else if ($1 instanceof Cmp2) {
        let var$2 = input.var;
        let op = $1.op;
        let a2 = $1.a;
        let b = $1.b;
        return toList([
          new Cmpq2(select_atm(b), select_atm(a2)),
          new Set4(convert_op_to_cc(op), new Al()),
          new Movzbq2(new Al(), new Var2(var$2))
        ]);
      } else if ($1 instanceof Plus2) {
        let $2 = $1.a;
        if ($2 instanceof Variable) {
          let v = input.var;
          let v1 = $2.v;
          if (v === v1) {
            let b = $1.b;
            return toList([new Addq2(select_atm(b), new Var2(v))]);
          } else {
            let $3 = $1.b;
            if ($3 instanceof Variable) {
              let v$1 = input.var;
              let v1$1 = $3.v;
              if (v$1 === v1$1) {
                let a2 = $2;
                return toList([new Addq2(select_atm(a2), new Var2(v$1))]);
              } else {
                let v$2 = input.var;
                let a2 = $2;
                let b = $3;
                return toList([
                  new Movq2(select_atm(a2), new Var2(v$2)),
                  new Addq2(select_atm(b), new Var2(v$2))
                ]);
              }
            } else {
              let v$1 = input.var;
              let a2 = $2;
              let b = $3;
              return toList([
                new Movq2(select_atm(a2), new Var2(v$1)),
                new Addq2(select_atm(b), new Var2(v$1))
              ]);
            }
          }
        } else {
          let $3 = $1.b;
          if ($3 instanceof Variable) {
            let v = input.var;
            let v1 = $3.v;
            if (v === v1) {
              let a2 = $2;
              return toList([new Addq2(select_atm(a2), new Var2(v))]);
            } else {
              let v$1 = input.var;
              let a2 = $2;
              let b = $3;
              return toList([
                new Movq2(select_atm(a2), new Var2(v$1)),
                new Addq2(select_atm(b), new Var2(v$1))
              ]);
            }
          } else {
            let v = input.var;
            let a2 = $2;
            let b = $3;
            return toList([
              new Movq2(select_atm(a2), new Var2(v)),
              new Addq2(select_atm(b), new Var2(v))
            ]);
          }
        }
      } else {
        let $2 = $1.a;
        if ($2 instanceof Variable) {
          let v = input.var;
          let v1 = $2.v;
          if (v === v1) {
            let b = $1.b;
            return toList([new Subq2(select_atm(b), new Var2(v))]);
          } else {
            let $3 = $1.b;
            if ($3 instanceof Variable) {
              let v$1 = input.var;
              let v1$1 = $3.v;
              if (v$1 === v1$1) {
                let a2 = $2;
                return toList([
                  new Negq2(new Var2(v$1)),
                  new Addq2(select_atm(a2), new Var2(v$1))
                ]);
              } else {
                let v$2 = input.var;
                let a2 = $2;
                let b = $3;
                return toList([
                  new Movq2(select_atm(a2), new Var2(v$2)),
                  new Subq2(select_atm(b), new Var2(v$2))
                ]);
              }
            } else {
              let v$1 = input.var;
              let a2 = $2;
              let b = $3;
              return toList([
                new Movq2(select_atm(a2), new Var2(v$1)),
                new Subq2(select_atm(b), new Var2(v$1))
              ]);
            }
          }
        } else {
          let $3 = $1.b;
          if ($3 instanceof Variable) {
            let v = input.var;
            let v1 = $3.v;
            if (v === v1) {
              let a2 = $2;
              return toList([
                new Negq2(new Var2(v)),
                new Addq2(select_atm(a2), new Var2(v))
              ]);
            } else {
              let v$1 = input.var;
              let a2 = $2;
              let b = $3;
              return toList([
                new Movq2(select_atm(a2), new Var2(v$1)),
                new Subq2(select_atm(b), new Var2(v$1))
              ]);
            }
          } else {
            let v = input.var;
            let a2 = $2;
            let b = $3;
            return toList([
              new Movq2(select_atm(a2), new Var2(v)),
              new Subq2(select_atm(b), new Var2(v))
            ]);
          }
        }
      }
    }
  } else {
    return toList([new Callq2("read_int", 0)]);
  }
}
function select_tail(input) {
  if (input instanceof Return) {
    let $ = input.a;
    if ($ instanceof Atom) {
      let atm = $.atm;
      return toList([
        new Movq2(select_atm(atm), new Reg2(new Rax())),
        new Jmp2("conclusion")
      ]);
    } else {
      let $1 = $.op;
      if ($1 instanceof Read2) {
        return toList([
          new Callq2("read_int", 0),
          new Jmp2("conclusion")
        ]);
      } else if ($1 instanceof Neg) {
        let a2 = $1.a;
        return toList([
          new Movq2(select_atm(a2), new Reg2(new Rax())),
          new Negq2(new Reg2(new Rax())),
          new Jmp2("conclusion")
        ]);
      } else if ($1 instanceof Not2) {
        throw makeError(
          "panic",
          FILEPATH10,
          "eoc/passes/select_instructions",
          121,
          "select_tail",
          "program returns boolean",
          {}
        );
      } else if ($1 instanceof Cmp2) {
        throw makeError(
          "panic",
          FILEPATH10,
          "eoc/passes/select_instructions",
          121,
          "select_tail",
          "program returns boolean",
          {}
        );
      } else if ($1 instanceof Plus2) {
        let a2 = $1.a;
        let b = $1.b;
        return toList([
          new Movq2(select_atm(a2), new Reg2(new Rax())),
          new Addq2(select_atm(b), new Reg2(new Rax())),
          new Jmp2("conclusion")
        ]);
      } else {
        let a2 = $1.a;
        let b = $1.b;
        return toList([
          new Movq2(select_atm(a2), new Reg2(new Rax())),
          new Subq2(select_atm(b), new Reg2(new Rax())),
          new Jmp2("conclusion")
        ]);
      }
    }
  } else if (input instanceof Seq) {
    let s = input.s;
    let t = input.t;
    return append3(select_stmt(s), select_tail(t));
  } else if (input instanceof Goto) {
    let label = input.label;
    return toList([new Jmp2(label)]);
  } else {
    let $ = input.if_false;
    if ($ instanceof Goto) {
      let $1 = input.if_true;
      if ($1 instanceof Goto) {
        let $2 = input.cond;
        if ($2 instanceof Prim2) {
          let $3 = $2.op;
          if ($3 instanceof Cmp2) {
            let l2 = $.label;
            let l1 = $1.label;
            let op = $3.op;
            let a2 = $3.a;
            let b = $3.b;
            return toList([
              new Cmpq2(select_atm(b), select_atm(a2)),
              new JmpIf2(convert_op_to_cc(op), l1),
              new Jmp2(l2)
            ]);
          } else {
            throw makeError(
              "panic",
              FILEPATH10,
              "eoc/passes/select_instructions",
              132,
              "select_tail",
              "invalid if statement",
              {}
            );
          }
        } else {
          throw makeError(
            "panic",
            FILEPATH10,
            "eoc/passes/select_instructions",
            132,
            "select_tail",
            "invalid if statement",
            {}
          );
        }
      } else {
        throw makeError(
          "panic",
          FILEPATH10,
          "eoc/passes/select_instructions",
          132,
          "select_tail",
          "invalid if statement",
          {}
        );
      }
    } else {
      throw makeError(
        "panic",
        FILEPATH10,
        "eoc/passes/select_instructions",
        132,
        "select_tail",
        "invalid if statement",
        {}
      );
    }
  }
}
function select_instructions(input) {
  let blocks = map_values(
    input.body,
    (_, tail) => {
      let block = new_block();
      return new Block2(
        select_tail(tail),
        block.live_before,
        block.live_after
      );
    }
  );
  let _record = new_program();
  return new X86Program2(blocks, _record.conflicts);
}

// build/dev/javascript/eoc/eoc/passes/shrink.mjs
function shrink_op(op) {
  if (op instanceof Read) {
    return new Prim(new Read());
  } else if (op instanceof Void) {
    return new Prim(new Void());
  } else if (op instanceof Negate) {
    let v = op.value;
    return new Prim(new Negate(shrink_expr(v)));
  } else if (op instanceof Plus) {
    let a2 = op.a;
    let b = op.b;
    return new Prim(new Plus(shrink_expr(a2), shrink_expr(b)));
  } else if (op instanceof Minus) {
    let a2 = op.a;
    let b = op.b;
    return new Prim(new Minus(shrink_expr(a2), shrink_expr(b)));
  } else if (op instanceof Cmp) {
    let c = op.op;
    let a2 = op.a;
    let b = op.b;
    return new Prim(new Cmp(c, shrink_expr(a2), shrink_expr(b)));
  } else if (op instanceof And) {
    let a2 = op.a;
    let b = op.b;
    return new If(shrink_expr(a2), shrink_expr(b), new Bool(false));
  } else if (op instanceof Or) {
    let a2 = op.a;
    let b = op.b;
    return new If(shrink_expr(a2), new Bool(true), shrink_expr(b));
  } else {
    let v = op.a;
    return new Prim(new Not(shrink_expr(v)));
  }
}
function shrink_expr(expr) {
  if (expr instanceof Int) {
    return expr;
  } else if (expr instanceof Bool) {
    return expr;
  } else if (expr instanceof Prim) {
    let op = expr.op;
    return shrink_op(op);
  } else if (expr instanceof Var) {
    return expr;
  } else if (expr instanceof Let) {
    let var$2 = expr.var;
    let binding = expr.binding;
    let body = expr.expr;
    return new Let(var$2, shrink_expr(binding), shrink_expr(body));
  } else if (expr instanceof If) {
    let cond = expr.condition;
    let t = expr.if_true;
    let e = expr.if_false;
    return new If(shrink_expr(cond), shrink_expr(t), shrink_expr(e));
  } else if (expr instanceof SetBang) {
    let var$2 = expr.var;
    let value = expr.value;
    return new SetBang(var$2, shrink_expr(value));
  } else if (expr instanceof Begin) {
    let stmts = expr.stmts;
    let result = expr.result;
    return new Begin(map(stmts, shrink_expr), shrink_expr(result));
  } else {
    let condition = expr.condition;
    let body = expr.body;
    return new WhileLoop(shrink_expr(condition), shrink_expr(body));
  }
}
function shrink(input) {
  let _pipe = input.body;
  let _pipe$1 = shrink_expr(_pipe);
  return new Program(_pipe$1);
}

// build/dev/javascript/eoc/eoc/passes/uncover_get.mjs
function uncover_get_expr(e, vars) {
  if (e instanceof Int) {
    let value = e.value;
    return new Int4(value);
  } else if (e instanceof Bool) {
    let value = e.value;
    return new Bool4(value);
  } else if (e instanceof Prim) {
    let $ = e.op;
    if ($ instanceof Read) {
      return new Prim4(new Read5());
    } else if ($ instanceof Void) {
      return new Prim4(new Void5());
    } else if ($ instanceof Negate) {
      let value = $.value;
      return new Prim4(new Negate3(uncover_get_expr(value, vars)));
    } else if ($ instanceof Plus) {
      let a2 = $.a;
      let b = $.b;
      return new Prim4(
        new Plus5(uncover_get_expr(a2, vars), uncover_get_expr(b, vars))
      );
    } else if ($ instanceof Minus) {
      let a2 = $.a;
      let b = $.b;
      return new Prim4(
        new Minus5(uncover_get_expr(a2, vars), uncover_get_expr(b, vars))
      );
    } else if ($ instanceof Cmp) {
      let op = $.op;
      let a2 = $.a;
      let b = $.b;
      return new Prim4(
        new Cmp5(op, uncover_get_expr(a2, vars), uncover_get_expr(b, vars))
      );
    } else if ($ instanceof And) {
      let a2 = $.a;
      let b = $.b;
      return new Prim4(
        new And3(uncover_get_expr(a2, vars), uncover_get_expr(b, vars))
      );
    } else if ($ instanceof Or) {
      let a2 = $.a;
      let b = $.b;
      return new Prim4(
        new Or3(uncover_get_expr(a2, vars), uncover_get_expr(b, vars))
      );
    } else {
      let a2 = $.a;
      return new Prim4(new Not5(uncover_get_expr(a2, vars)));
    }
  } else if (e instanceof Var) {
    let name = e.name;
    let $ = contains(vars, name);
    if ($) {
      return new GetBang2(name);
    } else {
      return new Var4(name);
    }
  } else if (e instanceof Let) {
    let var$2 = e.var;
    let binding = e.binding;
    let expr = e.expr;
    return new Let4(
      var$2,
      uncover_get_expr(binding, vars),
      uncover_get_expr(expr, vars)
    );
  } else if (e instanceof If) {
    let condition = e.condition;
    let if_true = e.if_true;
    let if_false = e.if_false;
    return new If5(
      uncover_get_expr(condition, vars),
      uncover_get_expr(if_true, vars),
      uncover_get_expr(if_false, vars)
    );
  } else if (e instanceof SetBang) {
    let var$2 = e.var;
    let value = e.value;
    return new SetBang4(var$2, uncover_get_expr(value, vars));
  } else if (e instanceof Begin) {
    let stmts = e.stmts;
    let result = e.result;
    let s2 = map(
      stmts,
      (_capture) => {
        return uncover_get_expr(_capture, vars);
      }
    );
    return new Begin4(s2, uncover_get_expr(result, vars));
  } else {
    let condition = e.condition;
    let body = e.body;
    return new WhileLoop3(
      uncover_get_expr(condition, vars),
      uncover_get_expr(body, vars)
    );
  }
}
function collect_set_bang(loop$e) {
  while (true) {
    let e = loop$e;
    if (e instanceof Int) {
      return new$();
    } else if (e instanceof Bool) {
      return new$();
    } else if (e instanceof Prim) {
      let $ = e.op;
      if ($ instanceof Read) {
        return new$();
      } else if ($ instanceof Void) {
        return new$();
      } else if ($ instanceof Negate) {
        let value = $.value;
        loop$e = value;
      } else if ($ instanceof Plus) {
        let a2 = $.a;
        let b = $.b;
        return union(collect_set_bang(a2), collect_set_bang(b));
      } else if ($ instanceof Minus) {
        let a2 = $.a;
        let b = $.b;
        return union(collect_set_bang(a2), collect_set_bang(b));
      } else if ($ instanceof Cmp) {
        let a2 = $.a;
        let b = $.b;
        return union(collect_set_bang(a2), collect_set_bang(b));
      } else if ($ instanceof And) {
        let a2 = $.a;
        let b = $.b;
        return union(collect_set_bang(a2), collect_set_bang(b));
      } else if ($ instanceof Or) {
        let a2 = $.a;
        let b = $.b;
        return union(collect_set_bang(a2), collect_set_bang(b));
      } else {
        let a2 = $.a;
        loop$e = a2;
      }
    } else if (e instanceof Var) {
      return new$();
    } else if (e instanceof Let) {
      let binding = e.binding;
      let expr = e.expr;
      return union(collect_set_bang(binding), collect_set_bang(expr));
    } else if (e instanceof If) {
      let condition = e.condition;
      let if_true = e.if_true;
      let if_false = e.if_false;
      return fold2(
        toList([condition, if_true, if_false]),
        new$(),
        (acc, expr) => {
          return union(acc, collect_set_bang(expr));
        }
      );
    } else if (e instanceof SetBang) {
      let var$2 = e.var;
      let value = e.value;
      return union(from_list2(toList([var$2])), collect_set_bang(value));
    } else if (e instanceof Begin) {
      let stmts = e.stmts;
      let result = e.result;
      return union(
        fold2(
          stmts,
          new$(),
          (acc, stmt) => {
            return union(acc, collect_set_bang(stmt));
          }
        ),
        collect_set_bang(result)
      );
    } else {
      let condition = e.condition;
      let body = e.body;
      return union(collect_set_bang(condition), collect_set_bang(body));
    }
  }
}
function uncover_get(input) {
  let muts = collect_set_bang(input.body);
  let body = uncover_get_expr(input.body, muts);
  return new Program3(body);
}

// build/dev/javascript/eoc/eoc/passes/uniquify.mjs
var FILEPATH11 = "src/eoc/passes/uniquify.gleam";
function get_var2(env, name) {
  let $ = map_get(env, name);
  if ($ instanceof Ok) {
    let i = $[0];
    return i;
  } else {
    throw makeError(
      "panic",
      FILEPATH11,
      "eoc/passes/uniquify",
      114,
      "get_var",
      "referenced unknown variable",
      {}
    );
  }
}
function uniquify_exp(e, env, counter) {
  if (e instanceof Int) {
    let i = e.value;
    return [new Int(i), counter];
  } else if (e instanceof Bool) {
    let b = e.value;
    return [new Bool(b), counter];
  } else if (e instanceof Prim) {
    let $ = e.op;
    if ($ instanceof Read) {
      return [new Prim(new Read()), counter];
    } else if ($ instanceof Void) {
      return [new Prim(new Void()), counter];
    } else if ($ instanceof Negate) {
      let v = $.value;
      let $1 = uniquify_exp(v, env, counter);
      let a1;
      let counter1;
      a1 = $1[0];
      counter1 = $1[1];
      return [new Prim(new Negate(a1)), counter1];
    } else if ($ instanceof Plus) {
      let a2 = $.a;
      let b = $.b;
      let $1 = uniquify_exp(a2, env, counter);
      let a1;
      let counter1;
      a1 = $1[0];
      counter1 = $1[1];
      let $2 = uniquify_exp(b, env, counter1);
      let b1;
      let counter2;
      b1 = $2[0];
      counter2 = $2[1];
      return [new Prim(new Plus(a1, b1)), counter2];
    } else if ($ instanceof Minus) {
      let a2 = $.a;
      let b = $.b;
      let $1 = uniquify_exp(a2, env, counter);
      let a1;
      let counter1;
      a1 = $1[0];
      counter1 = $1[1];
      let $2 = uniquify_exp(b, env, counter1);
      let b1;
      let counter2;
      b1 = $2[0];
      counter2 = $2[1];
      return [new Prim(new Minus(a1, b1)), counter2];
    } else if ($ instanceof Cmp) {
      let op = $.op;
      let a2 = $.a;
      let b = $.b;
      let $1 = uniquify_exp(a2, env, counter);
      let a1;
      let counter1;
      a1 = $1[0];
      counter1 = $1[1];
      let $2 = uniquify_exp(b, env, counter1);
      let b1;
      let counter2;
      b1 = $2[0];
      counter2 = $2[1];
      return [new Prim(new Cmp(op, a1, b1)), counter2];
    } else if ($ instanceof And) {
      let a2 = $.a;
      let b = $.b;
      let $1 = uniquify_exp(a2, env, counter);
      let a1;
      let counter1;
      a1 = $1[0];
      counter1 = $1[1];
      let $2 = uniquify_exp(b, env, counter1);
      let b1;
      let counter2;
      b1 = $2[0];
      counter2 = $2[1];
      return [new Prim(new And(a1, b1)), counter2];
    } else if ($ instanceof Or) {
      let a2 = $.a;
      let b = $.b;
      let $1 = uniquify_exp(a2, env, counter);
      let a1;
      let counter1;
      a1 = $1[0];
      counter1 = $1[1];
      let $2 = uniquify_exp(b, env, counter1);
      let b1;
      let counter2;
      b1 = $2[0];
      counter2 = $2[1];
      return [new Prim(new Or(a1, b1)), counter2];
    } else {
      let a2 = $.a;
      let $1 = uniquify_exp(a2, env, counter);
      let a1;
      let counter1;
      a1 = $1[0];
      counter1 = $1[1];
      return [new Prim(new Not(a1)), counter1];
    }
  } else if (e instanceof Var) {
    let v = e.name;
    return [new Var(get_var2(env, v)), counter];
  } else if (e instanceof Let) {
    let v = e.var;
    let e$1 = e.binding;
    let body = e.expr;
    let $ = uniquify_exp(e$1, env, counter);
    let e1;
    let counter1;
    e1 = $[0];
    counter1 = $[1];
    let counter_v = counter1 + 1;
    let v1 = v + "." + to_string(counter_v);
    let $1 = uniquify_exp(body, insert(env, v, v1), counter_v);
    let body1;
    let counter2;
    body1 = $1[0];
    counter2 = $1[1];
    return [new Let(v1, e1, body1), counter2];
  } else if (e instanceof If) {
    let cond = e.condition;
    let if_true = e.if_true;
    let if_false = e.if_false;
    let $ = uniquify_exp(cond, env, counter);
    let c1;
    let counter1;
    c1 = $[0];
    counter1 = $[1];
    let $1 = uniquify_exp(if_true, env, counter1);
    let t1;
    let counter2;
    t1 = $1[0];
    counter2 = $1[1];
    let $2 = uniquify_exp(if_false, env, counter2);
    let f1;
    let counter3;
    f1 = $2[0];
    counter3 = $2[1];
    return [new If(c1, t1, f1), counter3];
  } else if (e instanceof SetBang) {
    let var$2 = e.var;
    let value = e.value;
    let $ = uniquify_exp(value, env, counter);
    let value1;
    let counter1;
    value1 = $[0];
    counter1 = $[1];
    return [new SetBang(get_var2(env, var$2), value1), counter1];
  } else if (e instanceof Begin) {
    let stmts = e.stmts;
    let result = e.result;
    let $ = map_fold(
      stmts,
      counter,
      (c, stmt) => {
        return swap(uniquify_exp(stmt, env, c));
      }
    );
    let counter1;
    let stmts1;
    counter1 = $[0];
    stmts1 = $[1];
    let $1 = uniquify_exp(result, env, counter1);
    let result1;
    let counter2;
    result1 = $1[0];
    counter2 = $1[1];
    return [new Begin(stmts1, result1), counter2];
  } else {
    let condition = e.condition;
    let body = e.body;
    let $ = uniquify_exp(condition, env, counter);
    let condition1;
    let counter1;
    condition1 = $[0];
    counter1 = $[1];
    let $1 = uniquify_exp(body, env, counter1);
    let body1;
    let counter2;
    body1 = $1[0];
    counter2 = $1[1];
    return [new WhileLoop(condition1, body1), counter2];
  }
}
function uniquify(p) {
  let $ = uniquify_exp(p.body, new_map(), 0);
  let expr;
  expr = $[0];
  return new Program(expr);
}

// build/dev/javascript/eoc/eoc/compile.mjs
function interpret2(input) {
  return try$(
    map_error(tokens(input), inspect2),
    (tokens2) => {
      return map3(
        map_error(parse(tokens2), inspect2),
        (program2) => {
          let $ = interpret(program2);
          if ($ instanceof IntValue) {
            let v = $.v;
            return inspect2(v);
          } else if ($ instanceof BoolValue) {
            let v = $.v;
            return inspect2(v);
          } else {
            return "void";
          }
        }
      );
    }
  );
}
function compile3(input) {
  return try$(
    map_error(tokens(input), inspect2),
    (tokens2) => {
      return try$(
        map_error(parse(tokens2), inspect2),
        (program2) => {
          return map3(
            map_error(type_check_program(program2), inspect2),
            (pt) => {
              let _pipe = pt;
              let _pipe$1 = shrink(_pipe);
              let _pipe$2 = uniquify(_pipe$1);
              let _pipe$3 = uncover_get(_pipe$2);
              let _pipe$4 = remove_complex_operands(
                _pipe$3
              );
              let _pipe$5 = explicate_control(_pipe$4);
              let _pipe$6 = select_instructions(_pipe$5);
              let _pipe$7 = uncover_live(_pipe$6);
              let _pipe$8 = build_interference(_pipe$7);
              let _pipe$9 = allocate_registers(_pipe$8);
              let _pipe$10 = patch_instructions(_pipe$9);
              let _pipe$11 = generate_prelude_and_conclusion(
                _pipe$10
              );
              return program_to_text(
                _pipe$11,
                "main"
              );
            }
          );
        }
      );
    }
  );
}

// build/dev/javascript/gleam_community_colour/gleam_community/colour.mjs
var Rgba = class extends CustomType {
  constructor(r, g, b, a2) {
    super();
    this.r = r;
    this.g = g;
    this.b = b;
    this.a = a2;
  }
};
function valid_colour_value(c) {
  let $ = c > 1 || c < 0;
  if ($) {
    return new Error2(void 0);
  } else {
    return new Ok(c);
  }
}
function hue_to_rgb(hue, m1, m2) {
  let _block;
  if (hue < 0) {
    _block = hue + 1;
  } else if (hue > 1) {
    _block = hue - 1;
  } else {
    _block = hue;
  }
  let h = _block;
  let h_t_6 = h * 6;
  let h_t_2 = h * 2;
  let h_t_3 = h * 3;
  if (h_t_6 < 1) {
    return m1 + (m2 - m1) * h * 6;
  } else if (h_t_2 < 1) {
    return m2;
  } else if (h_t_3 < 2) {
    return m1 + (m2 - m1) * (2 / 3 - h) * 6;
  } else {
    return m1;
  }
}
function hsla_to_rgba(h, s, l, a2) {
  let _block;
  let $ = l <= 0.5;
  if ($) {
    _block = l * (s + 1);
  } else {
    _block = l + s - l * s;
  }
  let m2 = _block;
  let m1 = l * 2 - m2;
  let r = hue_to_rgb(h + 1 / 3, m1, m2);
  let g = hue_to_rgb(h, m1, m2);
  let b = hue_to_rgb(h - 1 / 3, m1, m2);
  return [r, g, b, a2];
}
function from_rgb255(red2, green2, blue2) {
  return try$(
    (() => {
      let _pipe = red2;
      let _pipe$1 = identity(_pipe);
      let _pipe$2 = divide(_pipe$1, 255);
      return try$(_pipe$2, valid_colour_value);
    })(),
    (r) => {
      return try$(
        (() => {
          let _pipe = green2;
          let _pipe$1 = identity(_pipe);
          let _pipe$2 = divide(_pipe$1, 255);
          return try$(_pipe$2, valid_colour_value);
        })(),
        (g) => {
          return try$(
            (() => {
              let _pipe = blue2;
              let _pipe$1 = identity(_pipe);
              let _pipe$2 = divide(_pipe$1, 255);
              return try$(_pipe$2, valid_colour_value);
            })(),
            (b) => {
              return new Ok(new Rgba(r, g, b, 1));
            }
          );
        }
      );
    }
  );
}
function to_rgba(colour2) {
  if (colour2 instanceof Rgba) {
    let r = colour2.r;
    let g = colour2.g;
    let b = colour2.b;
    let a2 = colour2.a;
    return [r, g, b, a2];
  } else {
    let h = colour2.h;
    let s = colour2.s;
    let l = colour2.l;
    let a2 = colour2.a;
    return hsla_to_rgba(h, s, l, a2);
  }
}

// build/dev/javascript/eoc/eoc/ui/colour.mjs
var FILEPATH12 = "src/eoc/ui/colour.gleam";
var ColourPalette = class extends CustomType {
  constructor(base, primary, secondary, success2, warning, danger) {
    super();
    this.base = base;
    this.primary = primary;
    this.secondary = secondary;
    this.success = success2;
    this.warning = warning;
    this.danger = danger;
  }
};
var ColourScale = class extends CustomType {
  constructor(bg, bg_subtle, tint, tint_subtle, tint_strong, accent, accent_subtle, accent_strong, solid, solid_subtle, solid_strong, solid_text, text4, text_subtle) {
    super();
    this.bg = bg;
    this.bg_subtle = bg_subtle;
    this.tint = tint;
    this.tint_subtle = tint_subtle;
    this.tint_strong = tint_strong;
    this.accent = accent;
    this.accent_subtle = accent_subtle;
    this.accent_strong = accent_strong;
    this.solid = solid;
    this.solid_subtle = solid_subtle;
    this.solid_strong = solid_strong;
    this.solid_text = solid_text;
    this.text = text4;
    this.text_subtle = text_subtle;
  }
};
function rgb(r, g, b) {
  let r$1 = min(255, max(0, r));
  let g$1 = min(255, max(0, g));
  let b$1 = min(255, max(0, b));
  let $ = from_rgb255(r$1, g$1, b$1);
  let colour2;
  if ($ instanceof Ok) {
    colour2 = $[0];
  } else {
    throw makeError(
      "let_assert",
      FILEPATH12,
      "eoc/ui/colour",
      63,
      "rgb",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 1294,
        end: 1345,
        pattern_start: 1305,
        pattern_end: 1315
      }
    );
  }
  return colour2;
}
function slate() {
  return new ColourScale(
    rgb(252, 252, 253),
    rgb(249, 249, 251),
    rgb(232, 232, 236),
    rgb(240, 240, 243),
    rgb(224, 225, 230),
    rgb(205, 206, 214),
    rgb(217, 217, 224),
    rgb(185, 187, 198),
    rgb(139, 141, 152),
    rgb(150, 152, 162),
    rgb(128, 131, 141),
    rgb(255, 255, 255),
    rgb(28, 32, 36),
    rgb(96, 100, 108)
  );
}
function red() {
  return new ColourScale(
    rgb(255, 252, 252),
    rgb(255, 247, 247),
    rgb(255, 219, 220),
    rgb(254, 235, 236),
    rgb(255, 205, 206),
    rgb(244, 169, 170),
    rgb(253, 189, 190),
    rgb(235, 142, 144),
    rgb(229, 72, 77),
    rgb(236, 83, 88),
    rgb(220, 62, 66),
    rgb(255, 255, 255),
    rgb(100, 23, 35),
    rgb(206, 44, 49)
  );
}
function plum() {
  return new ColourScale(
    rgb(254, 252, 255),
    rgb(253, 247, 253),
    rgb(247, 222, 248),
    rgb(251, 235, 251),
    rgb(242, 209, 243),
    rgb(222, 173, 227),
    rgb(233, 194, 236),
    rgb(207, 145, 216),
    rgb(171, 74, 186),
    rgb(177, 85, 191),
    rgb(161, 68, 175),
    rgb(255, 255, 255),
    rgb(83, 25, 93),
    rgb(149, 62, 163)
  );
}
function blue() {
  return new ColourScale(
    rgb(251, 253, 255),
    rgb(244, 250, 255),
    rgb(213, 239, 255),
    rgb(230, 244, 254),
    rgb(194, 229, 255),
    rgb(142, 200, 246),
    rgb(172, 216, 252),
    rgb(94, 177, 239),
    rgb(0, 144, 255),
    rgb(5, 148, 260),
    rgb(5, 136, 240),
    rgb(255, 255, 255),
    rgb(17, 50, 100),
    rgb(13, 116, 206)
  );
}
function green() {
  return new ColourScale(
    rgb(251, 254, 252),
    rgb(244, 251, 246),
    rgb(214, 241, 223),
    rgb(230, 246, 235),
    rgb(196, 232, 209),
    rgb(142, 206, 170),
    rgb(173, 221, 192),
    rgb(91, 185, 139),
    rgb(48, 164, 108),
    rgb(53, 173, 115),
    rgb(43, 154, 102),
    rgb(255, 255, 255),
    rgb(25, 59, 45),
    rgb(33, 131, 88)
  );
}
function yellow() {
  return new ColourScale(
    rgb(253, 253, 249),
    rgb(254, 252, 233),
    rgb(255, 243, 148),
    rgb(255, 250, 184),
    rgb(255, 231, 112),
    rgb(228, 199, 103),
    rgb(243, 215, 104),
    rgb(213, 174, 57),
    rgb(255, 230, 41),
    rgb(255, 234, 82),
    rgb(255, 220, 0),
    rgb(71, 59, 31),
    rgb(71, 59, 31),
    rgb(158, 108, 0)
  );
}
function default_light_palette() {
  return new ColourPalette(slate(), blue(), plum(), green(), yellow(), red());
}
function slate_dark() {
  return new ColourScale(
    rgb(24, 25, 27),
    rgb(17, 17, 19),
    rgb(39, 42, 45),
    rgb(33, 34, 37),
    rgb(46, 49, 53),
    rgb(67, 72, 78),
    rgb(54, 58, 63),
    rgb(90, 97, 105),
    rgb(105, 110, 119),
    rgb(91, 96, 105),
    rgb(119, 123, 132),
    rgb(255, 255, 255),
    rgb(237, 238, 240),
    rgb(176, 180, 186)
  );
}
function red_dark() {
  return new ColourScale(
    rgb(32, 19, 20),
    rgb(25, 17, 17),
    rgb(80, 15, 28),
    rgb(59, 18, 25),
    rgb(97, 22, 35),
    rgb(140, 51, 58),
    rgb(114, 35, 45),
    rgb(181, 69, 72),
    rgb(229, 72, 77),
    rgb(220, 52, 57),
    rgb(236, 93, 94),
    rgb(255, 255, 255),
    rgb(255, 209, 217),
    rgb(255, 149, 146)
  );
}
function plum_dark() {
  return new ColourScale(
    rgb(32, 19, 32),
    rgb(24, 17, 24),
    rgb(69, 29, 71),
    rgb(53, 26, 53),
    rgb(81, 36, 84),
    rgb(115, 64, 121),
    rgb(94, 48, 97),
    rgb(146, 84, 156),
    rgb(171, 74, 186),
    rgb(154, 68, 167),
    rgb(182, 88, 196),
    rgb(255, 255, 255),
    rgb(244, 212, 244),
    rgb(231, 150, 243)
  );
}
function blue_dark() {
  return new ColourScale(
    rgb(17, 25, 39),
    rgb(13, 21, 32),
    rgb(0, 51, 98),
    rgb(13, 40, 71),
    rgb(0, 64, 116),
    rgb(32, 93, 158),
    rgb(16, 77, 135),
    rgb(40, 112, 189),
    rgb(0, 144, 255),
    rgb(0, 110, 195),
    rgb(59, 158, 255),
    rgb(255, 255, 255),
    rgb(194, 230, 255),
    rgb(112, 184, 255)
  );
}
function green_dark() {
  return new ColourScale(
    rgb(18, 27, 23),
    rgb(14, 21, 18),
    rgb(17, 59, 41),
    rgb(19, 45, 33),
    rgb(23, 73, 51),
    rgb(40, 104, 74),
    rgb(32, 87, 62),
    rgb(47, 124, 87),
    rgb(48, 164, 108),
    rgb(44, 152, 100),
    rgb(51, 176, 116),
    rgb(255, 255, 255),
    rgb(177, 241, 203),
    rgb(61, 214, 140)
  );
}
function yellow_dark() {
  return new ColourScale(
    rgb(27, 24, 15),
    rgb(20, 18, 11),
    rgb(54, 43, 0),
    rgb(45, 35, 5),
    rgb(67, 53, 0),
    rgb(102, 84, 23),
    rgb(82, 66, 2),
    rgb(131, 106, 33),
    rgb(255, 230, 41),
    rgb(250, 220, 0),
    rgb(255, 255, 87),
    rgb(27, 24, 15),
    rgb(246, 238, 180),
    rgb(245, 225, 71)
  );
}
function default_dark_palette() {
  return new ColourPalette(
    slate_dark(),
    blue_dark(),
    plum_dark(),
    green_dark(),
    yellow_dark(),
    red_dark()
  );
}

// build/dev/javascript/eoc/eoc/ui/theme.mjs
var Theme = class extends CustomType {
  constructor(id, selector, font2, radius2, space, light, dark) {
    super();
    this.id = id;
    this.selector = selector;
    this.font = font2;
    this.radius = radius2;
    this.space = space;
    this.light = light;
    this.dark = dark;
  }
};
var Fonts = class extends CustomType {
  constructor(heading, body, code2) {
    super();
    this.heading = heading;
    this.body = body;
    this.code = code2;
  }
};
var SizeScale = class extends CustomType {
  constructor(xs, sm, md, lg, xl, xl_2, xl_3) {
    super();
    this.xs = xs;
    this.sm = sm;
    this.md = md;
    this.lg = lg;
    this.xl = xl;
    this.xl_2 = xl_2;
    this.xl_3 = xl_3;
  }
};
var Global = class extends CustomType {
};
var Class = class extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
};
var FontVariables = class extends CustomType {
  constructor(heading, body, code2) {
    super();
    this.heading = heading;
    this.body = body;
    this.code = code2;
  }
};
var SizeVariables = class extends CustomType {
  constructor(xs, sm, md, lg, xl, xl_2, xl_3) {
    super();
    this.xs = xs;
    this.sm = sm;
    this.md = md;
    this.lg = lg;
    this.xl = xl;
    this.xl_2 = xl_2;
    this.xl_3 = xl_3;
  }
};
var ColourScaleVariables = class extends CustomType {
  constructor(bg, bg_subtle, tint, tint_subtle, tint_strong, accent, accent_subtle, accent_strong, solid, solid_subtle, solid_strong, solid_text, text4, text_subtle) {
    super();
    this.bg = bg;
    this.bg_subtle = bg_subtle;
    this.tint = tint;
    this.tint_subtle = tint_subtle;
    this.tint_strong = tint_strong;
    this.accent = accent;
    this.accent_subtle = accent_subtle;
    this.accent_strong = accent_strong;
    this.solid = solid;
    this.solid_subtle = solid_subtle;
    this.solid_strong = solid_strong;
    this.solid_text = solid_text;
    this.text = text4;
    this.text_subtle = text_subtle;
  }
};
function perfect_fifth(base) {
  return new SizeScale(
    base / 1.5 / 1.5 / 1.5,
    base / 1.5 / 1.5,
    base,
    base * 1.5,
    base * 1.5 * 1.5,
    base * 1.5 * 1.5 * 1.5,
    base * 1.5 * 1.5 * 1.5 * 1.5
  );
}
function golden_ratio(base) {
  return new SizeScale(
    base / 1.618 / 1.618 / 1.618,
    base / 1.618 / 1.618,
    base,
    base * 1.618,
    base * 1.618 * 1.618,
    base * 1.618 * 1.618 * 1.618,
    base * 1.618 * 1.618 * 1.618 * 1.618
  );
}
function use_base() {
  return class$("base");
}
function use_primary() {
  return class$("primary");
}
function use_secondary() {
  return class$("secondary");
}
function to_css_selector(selector) {
  if (selector instanceof Global) {
    return "";
  } else if (selector instanceof Class) {
    let class$2 = selector[0];
    return "." + class$2;
  } else {
    let $ = selector[1];
    if ($ === "") {
      let name = selector[0];
      return "[data-" + name + "]";
    } else {
      let name = selector[0];
      let value = $;
      return "[data-" + name + "=" + value + "]";
    }
  }
}
function to_css_rgb(colour2) {
  let $ = to_rgba(colour2);
  let r;
  let g;
  let b;
  r = $[0];
  g = $[1];
  b = $[2];
  let _block;
  let _pipe = round2(r * 255);
  _block = to_string(_pipe);
  let r$1 = _block;
  let _block$1;
  let _pipe$1 = round2(g * 255);
  _block$1 = to_string(_pipe$1);
  let g$1 = _block$1;
  let _block$2;
  let _pipe$2 = round2(b * 255);
  _block$2 = to_string(_pipe$2);
  let b$1 = _block$2;
  return r$1 + " " + g$1 + " " + b$1;
}
function var$(name) {
  return "--lustre-ui-" + name;
}
function to_css_variable(name, value) {
  return var$(name) + ":" + value + ";";
}
function to_colour_scale_variables(scale, name) {
  return concat2(
    toList([
      to_css_variable(name + "-bg", to_css_rgb(scale.bg)),
      to_css_variable(name + "-bg-subtle", to_css_rgb(scale.bg_subtle)),
      to_css_variable(name + "-tint", to_css_rgb(scale.tint)),
      to_css_variable(name + "-tint-subtle", to_css_rgb(scale.tint_subtle)),
      to_css_variable(name + "-tint-strong", to_css_rgb(scale.tint_strong)),
      to_css_variable(name + "-accent", to_css_rgb(scale.accent)),
      to_css_variable(name + "-accent-subtle", to_css_rgb(scale.accent_subtle)),
      to_css_variable(name + "-accent-strong", to_css_rgb(scale.accent_strong)),
      to_css_variable(name + "-solid", to_css_rgb(scale.solid)),
      to_css_variable(name + "-solid-subtle", to_css_rgb(scale.solid_subtle)),
      to_css_variable(name + "-solid-strong", to_css_rgb(scale.solid_strong)),
      to_css_variable(name + "-solid-text", to_css_rgb(scale.solid_text)),
      to_css_variable(name + "-text", to_css_rgb(scale.text)),
      to_css_variable(name + "-text-subtle", to_css_rgb(scale.text_subtle)),
      "& ." + name + ', [data-scale="' + name + '"] {',
      "--lustre-ui-bg: var(--lustre-ui-" + name + "-bg);",
      "--lustre-ui-bg-subtle: var(--lustre-ui-" + name + "-bg-subtle);",
      "--lustre-ui-tint: var(--lustre-ui-" + name + "-tint);",
      "--lustre-ui-tint-subtle: var(--lustre-ui-" + name + "-tint-subtle);",
      "--lustre-ui-tint-strong: var(--lustre-ui-" + name + "-tint-strong);",
      "--lustre-ui-accent: var(--lustre-ui-" + name + "-accent);",
      "--lustre-ui-accent-subtle: var(--lustre-ui-" + name + "-accent-subtle);",
      "--lustre-ui-accent-strong: var(--lustre-ui-" + name + "-accent-strong);",
      "--lustre-ui-solid: var(--lustre-ui-" + name + "-solid);",
      "--lustre-ui-solid-subtle: var(--lustre-ui-" + name + "-solid-subtle);",
      "--lustre-ui-solid-strong: var(--lustre-ui-" + name + "-solid-strong);",
      "--lustre-ui-solid-text: var(--lustre-ui-" + name + "-solid-text);",
      "--lustre-ui-text: var(--lustre-ui-" + name + "-text);",
      "--lustre-ui-text-subtle: var(--lustre-ui-" + name + "-text-subtle);",
      "}"
    ])
  );
}
function to_color_palette_variables(palette, scheme) {
  return concat2(
    toList([
      to_css_variable("color-scheme", scheme),
      to_colour_scale_variables(palette.base, "base"),
      to_colour_scale_variables(palette.primary, "primary"),
      to_colour_scale_variables(palette.secondary, "secondary"),
      to_colour_scale_variables(palette.success, "success"),
      to_colour_scale_variables(palette.warning, "warning"),
      to_colour_scale_variables(palette.danger, "danger"),
      "--lustre-ui-bg: var(--lustre-ui-base-bg);",
      "--lustre-ui-bg-subtle: var(--lustre-ui-base-bg-subtle);",
      "--lustre-ui-tint: var(--lustre-ui-base-tint);",
      "--lustre-ui-tint-subtle: var(--lustre-ui-base-tint-subtle);",
      "--lustre-ui-tint-strong: var(--lustre-ui-base-tint-strong);",
      "--lustre-ui-accent: var(--lustre-ui-base-accent);",
      "--lustre-ui-accent-subtle: var(--lustre-ui-base-accent-subtle);",
      "--lustre-ui-accent-strong: var(--lustre-ui-base-accent-strong);",
      "--lustre-ui-solid: var(--lustre-ui-base-solid);",
      "--lustre-ui-solid-subtle: var(--lustre-ui-base-solid-subtle);",
      "--lustre-ui-solid-strong: var(--lustre-ui-base-solid-strong);",
      "--lustre-ui-solid-text: var(--lustre-ui-base-solid-text);",
      "--lustre-ui-text: var(--lustre-ui-base-text);",
      "--lustre-ui-text-subtle: var(--lustre-ui-base-text-subtle);"
    ])
  );
}
function to_css_variables(theme) {
  return concat2(
    toList([
      to_css_variable("id", theme.id),
      to_css_variable("font-heading", theme.font.heading),
      to_css_variable("font-body", theme.font.body),
      to_css_variable("font-code", theme.font.code),
      to_css_variable("radius-xs", float_to_string(theme.radius.xs) + "rem"),
      to_css_variable("radius-sm", float_to_string(theme.radius.sm) + "rem"),
      to_css_variable("radius-md", float_to_string(theme.radius.md) + "rem"),
      to_css_variable("radius-lg", float_to_string(theme.radius.lg) + "rem"),
      to_css_variable("radius-xl", float_to_string(theme.radius.xl) + "rem"),
      to_css_variable(
        "radius-xl-2",
        float_to_string(theme.radius.xl_2) + "rem"
      ),
      to_css_variable(
        "radius-xl-3",
        float_to_string(theme.radius.xl_3) + "rem"
      ),
      to_css_variable("spacing-xs", float_to_string(theme.space.xs) + "rem"),
      to_css_variable("spacing-sm", float_to_string(theme.space.sm) + "rem"),
      to_css_variable("spacing-md", float_to_string(theme.space.md) + "rem"),
      to_css_variable("spacing-lg", float_to_string(theme.space.lg) + "rem"),
      to_css_variable("spacing-xl", float_to_string(theme.space.xl) + "rem"),
      to_css_variable(
        "spacing-xl-2",
        float_to_string(theme.space.xl_2) + "rem"
      ),
      to_css_variable(
        "spacing-xl-3",
        float_to_string(theme.space.xl_3) + "rem"
      ),
      to_color_palette_variables(theme.light, "light")
    ])
  );
}
var sans = 'ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"';
var code = 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace';
var stylesheet_global_light_no_dark = "\nbody {\n  ${rules}\n\n  background-color: rgb(var(--lustre-ui-bg));\n  color: rgb(var(--lustre-ui-text));\n  font-family: ${fonts.body}\n}\n\nh1, h2, h3, h4, h5, h6 {\n  font-family: ${fonts.heading}\n}\n\npre, code, kbd, samp {\n  font-family: ${fonts.code}\n}\n";
var stylesheet_global_light_global_dark = "\nbody {\n  ${rules}\n\n  background-color: rgb(var(--lustre-ui-bg));\n  color: rgb(var(--lustre-ui-text));\n  font-family: ${fonts.body}\n}\n\nh1, h2, h3, h4, h5, h6 {\n  font-family: ${fonts.heading}\n}\n\npre, code, kbd, samp {\n  font-family: ${fonts.code}\n}\n\n@media (prefers-color-scheme: dark) {\n  body {\n    ${dark_rules}\n  }\n}\n";
var stylesheet_global_light_scoped_dark = "\nbody {\n  ${rules}\n\n  background-color: rgb(var(--lustre-ui-bg));\n  color: rgb(var(--lustre-ui-text));\n  font-family: ${fonts.body}\n}\n\nh1, h2, h3, h4, h5, h6 {\n  font-family: ${fonts.heading}\n}\n\npre, code, kbd, samp {\n  font-family: ${fonts.code}\n}\n\nbody${dark_selector}, body ${dark_selector} {\n  ${dark_rules}\n}\n\n@media (prefers-color-scheme: dark) {\n  body {\n    ${dark_rules}\n  }\n}\n";
var stylesheet_scoped_light_no_dark = "\n${selector} {\n  ${rules}\n\n  background-color: rgb(var(--lustre-ui-bg));\n  color: rgb(var(--lustre-ui-text));\n  font-family: ${fonts.body}\n}\n\n${selector} :is(h1, h2, h3, h4, h5, h6) {\n  font-family: ${fonts.heading}\n}\n\n${selector} :is(pre, code, kbd, samp) {\n  font-family: ${fonts.code}\n}\n";
var stylesheet_scoped_light_global_dark = "\n${selector} {\n  ${rules}\n\n  background-color: rgb(var(--lustre-ui-bg));\n  color: rgb(var(--lustre-ui-text));\n  font-family: ${fonts.body}\n}\n\n${selector} :is(h1, h2, h3, h4, h5, h6) {\n  font-family: ${fonts.heading}\n}\n\n${selector} :is(pre, code, kbd, samp) {\n  font-family: ${fonts.code}\n}\n\n@media (prefers-color-scheme: dark) {\n  ${selector} {\n    ${dark_rules}\n  }\n}\n";
var stylesheet_scoped_light_scoped_dark = "\n${selector} {\n  ${rules}\n\n  background-color: rgb(var(--lustre-ui-bg));\n  color: rgb(var(--lustre-ui-text));\n  font-family: ${fonts.body}\n}\n\n${selector} :is(h1, h2, h3, h4, h5, h6) {\n  font-family: ${fonts.heading}\n}\n\n${selector} :is(pre, code, kbd, samp) {\n  font-family: ${fonts.code}\n}\n\n${selector}${dark_selector}, ${selector} ${dark_selector} {\n  ${dark_rules}\n}\n\n@media (prefers-color-scheme: dark) {\n  ${selector} {\n    ${dark_rules}\n  }\n}\n";
function to_style(theme) {
  let data_attr = attribute2("data-lustre-ui-theme", theme.id);
  let $ = theme.selector;
  let $1 = theme.dark;
  if ($1 instanceof Some) {
    let $2 = $1[0][0];
    if ($2 instanceof Global) {
      if ($ instanceof Global) {
        let dark_palette = $1[0][1];
        let _pipe = stylesheet_global_light_global_dark;
        let _pipe$1 = replace(
          _pipe,
          "${rules}",
          to_css_variables(theme)
        );
        let _pipe$2 = replace(
          _pipe$1,
          "${dark_rules}",
          to_color_palette_variables(dark_palette, "dark")
        );
        let _pipe$3 = replace(
          _pipe$2,
          "${fonts.heading}",
          theme.font.heading
        );
        let _pipe$4 = replace(_pipe$3, "${fonts.body}", theme.font.body);
        let _pipe$5 = replace(_pipe$4, "${fonts.code}", theme.font.code);
        return ((_capture) => {
          return style2(toList([data_attr]), _capture);
        })(_pipe$5);
      } else {
        let selector = $;
        let dark_palette = $1[0][1];
        let _pipe = stylesheet_scoped_light_global_dark;
        let _pipe$1 = replace(
          _pipe,
          "${selector}",
          to_css_selector(selector)
        );
        let _pipe$2 = replace(
          _pipe$1,
          "${rules}",
          to_css_variables(theme)
        );
        let _pipe$3 = replace(
          _pipe$2,
          "${dark_rules}",
          to_color_palette_variables(dark_palette, "dark")
        );
        let _pipe$4 = replace(
          _pipe$3,
          "${fonts.heading}",
          theme.font.heading
        );
        let _pipe$5 = replace(_pipe$4, "${fonts.body}", theme.font.body);
        let _pipe$6 = replace(_pipe$5, "${fonts.code}", theme.font.code);
        return ((_capture) => {
          return style2(toList([data_attr]), _capture);
        })(_pipe$6);
      }
    } else if ($ instanceof Global) {
      let dark_selector = $2;
      let dark_palette = $1[0][1];
      let _pipe = stylesheet_global_light_scoped_dark;
      let _pipe$1 = replace(_pipe, "${rules}", to_css_variables(theme));
      let _pipe$2 = replace(
        _pipe$1,
        "${dark_selector}",
        to_css_selector(dark_selector)
      );
      let _pipe$3 = replace(
        _pipe$2,
        "${dark_rules}",
        to_color_palette_variables(dark_palette, "dark")
      );
      let _pipe$4 = replace(
        _pipe$3,
        "${fonts.heading}",
        theme.font.heading
      );
      let _pipe$5 = replace(_pipe$4, "${fonts.body}", theme.font.body);
      let _pipe$6 = replace(_pipe$5, "${fonts.code}", theme.font.code);
      return ((_capture) => {
        return style2(toList([data_attr]), _capture);
      })(_pipe$6);
    } else {
      let selector = $;
      let dark_selector = $2;
      let dark_palette = $1[0][1];
      let _pipe = stylesheet_scoped_light_scoped_dark;
      let _pipe$1 = replace(
        _pipe,
        "${selector}",
        to_css_selector(selector)
      );
      let _pipe$2 = replace(
        _pipe$1,
        "${rules}",
        to_css_variables(theme)
      );
      let _pipe$3 = replace(
        _pipe$2,
        "${dark_selector}",
        to_css_selector(dark_selector)
      );
      let _pipe$4 = replace(
        _pipe$3,
        "${dark_rules}",
        to_color_palette_variables(dark_palette, "dark")
      );
      let _pipe$5 = replace(
        _pipe$4,
        "${fonts.heading}",
        theme.font.heading
      );
      let _pipe$6 = replace(_pipe$5, "${fonts.body}", theme.font.body);
      let _pipe$7 = replace(_pipe$6, "${fonts.code}", theme.font.code);
      return ((_capture) => {
        return style2(toList([data_attr]), _capture);
      })(_pipe$7);
    }
  } else if ($ instanceof Global) {
    let _pipe = stylesheet_global_light_no_dark;
    let _pipe$1 = replace(_pipe, "${rules}", to_css_variables(theme));
    let _pipe$2 = replace(
      _pipe$1,
      "${fonts.heading}",
      theme.font.heading
    );
    let _pipe$3 = replace(_pipe$2, "${fonts.body}", theme.font.body);
    let _pipe$4 = replace(_pipe$3, "${fonts.code}", theme.font.code);
    return ((_capture) => {
      return style2(toList([data_attr]), _capture);
    })(
      _pipe$4
    );
  } else {
    let selector = $;
    let _pipe = stylesheet_scoped_light_no_dark;
    let _pipe$1 = replace(
      _pipe,
      "${selector}",
      to_css_selector(selector)
    );
    let _pipe$2 = replace(_pipe$1, "${rules}", to_css_variables(theme));
    let _pipe$3 = replace(
      _pipe$2,
      "${fonts.heading}",
      theme.font.heading
    );
    let _pipe$4 = replace(_pipe$3, "${fonts.body}", theme.font.body);
    let _pipe$5 = replace(_pipe$4, "${fonts.code}", theme.font.code);
    return ((_capture) => {
      return style2(toList([data_attr]), _capture);
    })(
      _pipe$5
    );
  }
}
function inject(theme, view2) {
  return fragment2(toList([to_style(theme), view2()]));
}
var font = /* @__PURE__ */ new FontVariables(
  "var(--lustre-ui-font-heading)",
  "var(--lustre-ui-font-body)",
  "var(--lustre-ui-font-code)"
);
var spacing = /* @__PURE__ */ new SizeVariables(
  "var(--lustre-ui-spacing-xs)",
  "var(--lustre-ui-spacing-sm)",
  "var(--lustre-ui-spacing-md)",
  "var(--lustre-ui-spacing-lg)",
  "var(--lustre-ui-spacing-xl)",
  "var(--lustre-ui-spacing-xl-2)",
  "var(--lustre-ui-spacing-xl-3)"
);
var colour = /* @__PURE__ */ new ColourScaleVariables(
  "var(--lustre-ui-bg)",
  "var(--lustre-ui-bg-subtle)",
  "var(--lustre-ui-tint)",
  "var(--lustre-ui-tint-subtle)",
  "var(--lustre-ui-tint-strong)",
  "var(--lustre-ui-accent)",
  "var(--lustre-ui-accent-subtle)",
  "var(--lustre-ui-accent-strong)",
  "var(--lustre-ui-solid)",
  "var(--lustre-ui-solid-subtle)",
  "var(--lustre-ui-solid-strong)",
  "var(--lustre-ui-solid-text)",
  "var(--lustre-ui-text)",
  "var(--lustre-ui-text-subtle)"
);
function default$() {
  let id = "lustre-ui-default";
  let font$1 = new Fonts(sans, sans, code);
  let radius$1 = perfect_fifth(0.75);
  let space = golden_ratio(0.75);
  let light = default_light_palette();
  let dark = default_dark_palette();
  return new Theme(
    id,
    new Global(),
    font$1,
    radius$1,
    space,
    light,
    new Some([new Class("dark"), dark])
  );
}

// build/dev/javascript/eoc/eoc/ui/button.mjs
function of(element4, attributes, children) {
  return element4(
    prepend(
      class$("lustre-ui-button"),
      prepend(role("button"), attributes)
    ),
    children
  );
}
function button2(attributes, children) {
  return of(
    button,
    prepend(attribute2("tabindex", "0"), attributes),
    children
  );
}

// build/dev/javascript/eoc/eoc/ui.mjs
var FILEPATH13 = "src/eoc/ui.gleam";
var Model = class extends CustomType {
  constructor(input, output) {
    super();
    this.input = input;
    this.output = output;
  }
};
var InputUpdated = class extends CustomType {
  constructor(input) {
    super();
    this.input = input;
  }
};
var Compile = class extends CustomType {
};
var Interpet = class extends CustomType {
};
function init(_) {
  return new Model("", "");
}
function update3(model, msg) {
  if (msg instanceof InputUpdated) {
    let input = msg.input;
    return new Model(input, model.output);
  } else if (msg instanceof Compile) {
    return new Model(
      model.input,
      unwrap_both(compile3(model.input))
    );
  } else {
    return new Model(
      model.input,
      unwrap_both(interpret2(model.input))
    );
  }
}
function code_component(attrs, body) {
  return div(
    toList([class$("grow")]),
    toList([
      textarea(
        prepend(
          style("font-family", font.code),
          prepend(
            style("font-size", spacing.lg),
            prepend(
              style("background-color", colour.bg_subtle),
              prepend(
                class$("resize-none h-full w-full focus:border-none"),
                prepend(autocomplete("off"), attrs)
              )
            )
          )
        ),
        body
      )
    ])
  );
}
function view(model) {
  return inject(
    default$(),
    () => {
      return div(
        toList([class$("my-1 px-3")]),
        toList([
          div(
            toList([class$("p-2 flex flex-row")]),
            toList([
              h1(
                toList([
                  use_base(),
                  style("font-family", font.heading),
                  style("font-size", spacing.lg),
                  class$("mr-2")
                ]),
                toList([text2("Elements of Compilation")])
              ),
              button2(
                toList([
                  use_primary(),
                  class$("mr-2"),
                  on_click(new Compile())
                ]),
                toList([text2("Compile")])
              ),
              button2(
                toList([use_secondary(), on_click(new Interpet())]),
                toList([text2("Interpet")])
              )
            ])
          ),
          div(
            toList([class$("w-screen flex flex-row gap-2 h-svh")]),
            toList([
              code_component(
                toList([
                  on_change((var0) => {
                    return new InputUpdated(var0);
                  })
                ]),
                model.input
              ),
              code_component(toList([readonly(true)]), model.output)
            ])
          )
        ])
      );
    }
  );
}
function main() {
  let app = simple(init, update3, view);
  let $ = start3(app, "#app", void 0);
  if (!($ instanceof Ok)) {
    throw makeError(
      "let_assert",
      FILEPATH13,
      "eoc/ui",
      14,
      "main",
      "Pattern match failed, no pattern matched the value.",
      { value: $, start: 330, end: 379, pattern_start: 341, pattern_end: 346 }
    );
  }
  return void 0;
}

// build/dev/javascript/eoc/eoc.mjs
function main2() {
  return main();
}

// build/.lustre/entry.mjs
main2();
