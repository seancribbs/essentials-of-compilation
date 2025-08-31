import { List } from "./gleam.mjs";
import { Graph } from "@dagrejs/graphlib";

export function new_cfg() {
  return new Graph();
}

export function add_vertex(g, v) {
  g.setNode(v);
  return g;
}

export function add_edge(g, v1, v2) {
  g.setEdge(v1, v2);
  return g;
}

export function in_neighbors(g, v) {
  const neighbors = g.predecessors(v);
  return List.fromArray(neighbors);
}

export function out_neighbors(g, v) {
  const neighbors = g.successors(v);
  return List.fromArray(neighbors);
}
