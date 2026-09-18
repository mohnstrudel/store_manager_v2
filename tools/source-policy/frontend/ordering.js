function hasIncomingEdge(definitions, target) {
  return definitions.some((definition) => definition.callees.includes(target));
}

export function computeExpectedOrder(definitions) {
  const visited = new Set();
  const ordered = [];

  const visit = (definition) => {
    if (visited.has(definition)) return;
    visited.add(definition);
    ordered.push(definition);
    for (const callee of definition.callees) visit(callee);
  };

  const roots = definitions.filter((definition) => !hasIncomingEdge(definitions, definition));
  for (const root of roots) visit(root);
  for (const definition of definitions) visit(definition);

  return ordered;
}

export function findInversions(definitions, syntheticRoot) {
  if (definitions.length < 2) return [];

  const graph = syntheticRoot ? [syntheticRoot, ...definitions] : definitions;
  const expectedOrder = computeExpectedOrder(graph);
  const expectedRank = new Map(expectedOrder.map((definition, index) => [definition, index]));

  const inversions = [];
  for (let index = 0; index < definitions.length - 1; index++) {
    const earlier = definitions[index];
    const later = definitions[index + 1];
    if (expectedRank.get(earlier) < expectedRank.get(later)) continue;

    inversions.push({earlier, later});
  }

  return inversions;
}
