import {describe, expect, it} from "vitest";
import {findInversions} from "./ordering.js";

function def(name) {
  return {name, callees: []};
}

describe("findInversions", () => {
  it("accepts a caller followed depth-first by its callee subtree", () => {
    const a = def("a");
    const b = def("b");
    const c = def("c");
    const d = def("d");
    a.callees = [b, c];
    b.callees = [d];

    expect(findInversions([a, b, d, c])).toEqual([]);
  });

  it("flags a callee subtree interrupted by a later sibling callee", () => {
    const a = def("a");
    const b = def("b");
    const c = def("c");
    const d = def("d");
    a.callees = [b, c];
    b.callees = [d];

    const inversions = findInversions([a, b, c, d]);

    expect(inversions).toEqual([{earlier: c, later: d}]);
  });

  it("flags a callee exported and declared before its caller", () => {
    const helper = def("helper");
    const entryPoint = def("entryPoint");
    entryPoint.callees = [helper];

    const inversions = findInversions([helper, entryPoint]);

    expect(inversions).toEqual([{earlier: helper, later: entryPoint}]);
  });

  it("accepts a shared helper positioned right after the first root that reaches it", () => {
    const rootOne = def("rootOne");
    const helper = def("helper");
    const rootTwo = def("rootTwo");
    rootOne.callees = [helper];
    rootTwo.callees = [helper];

    expect(findInversions([rootOne, helper, rootTwo])).toEqual([]);
  });

  it("accepts disconnected declarations kept in their declared source order", () => {
    const one = def("one");
    const two = def("two");
    const three = def("three");

    expect(findInversions([one, two, three])).toEqual([]);
  });

  it("terminates a mutual cycle and accepts its declared order", () => {
    const a = def("a");
    const b = def("b");
    a.callees = [b];
    b.callees = [a];

    expect(findInversions([a, b])).toEqual([]);
  });

  it("terminates a cycle reached from an external root", () => {
    const entry = def("entry");
    const a = def("a");
    const b = def("b");
    entry.callees = [a];
    a.callees = [b];
    b.callees = [a];

    expect(findInversions([entry, a, b])).toEqual([]);
  });

  it("ranks direct nested declarations by the enclosing body's synthetic root", () => {
    const helper = def("helper");
    const another = def("another");
    const syntheticRoot = {name: "<body>", callees: [helper, another]};

    expect(findInversions([another, helper], syntheticRoot)).toEqual([
      {earlier: another, later: helper},
    ]);
    expect(findInversions([helper, another], syntheticRoot)).toEqual([]);
  });
});
