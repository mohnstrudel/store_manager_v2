import {findInversions} from "./ordering.js";
import {isAllowedComment} from "./comments.js";

const ORDERING_MESSAGE_ID = "outOfOrder";
const COMMENT_MESSAGE = "Do not add prose comments to code; use names, structure, and tests.";

const SKIPPED_CHILD_KEYS = new Set(["parent", "loc", "range", "start", "end", "type"]);

function isNodeLike(value) {
  return value !== null && typeof value === "object" && typeof value.type === "string";
}

function eachChildNode(node, visit) {
  for (const key of Object.keys(node)) {
    if (SKIPPED_CHILD_KEYS.has(key)) continue;

    const value = node[key];
    if (Array.isArray(value)) {
      for (const item of value) {
        if (isNodeLike(item)) visit(item);
      }
    } else if (isNodeLike(value)) {
      visit(value);
    }
  }
}

function isFunctionValue(node) {
  return node && (node.type === "FunctionExpression" || node.type === "ArrowFunctionExpression");
}

function blockBodyOf(fn) {
  return fn.body && fn.body.type === "BlockStatement" ? fn.body : null;
}

// Finds the next scope-boundary node(s) reachable from `node` without crossing
// through another scope boundary first, so each nested scope is analyzed exactly once.
function directScopeBoundaries(node, results) {
  if (!isNodeLike(node)) return;

  if (node.type === "FunctionDeclaration") {
    results.push({node, name: node.id ? node.id.name : null, body: blockBodyOf(node)});
    return;
  }

  if (node.type === "ClassDeclaration" || node.type === "ClassExpression") {
    results.push({node, classBody: node.body});
    return;
  }

  if (node.type === "VariableDeclarator" && isFunctionValue(node.init)) {
    const name = node.id.type === "Identifier" ? node.id.name : null;
    results.push({node, name, body: blockBodyOf(node.init)});
    return;
  }

  if (isFunctionValue(node)) {
    results.push({node, name: null, body: blockBodyOf(node)});
    return;
  }

  eachChildNode(node, (child) => directScopeBoundaries(child, results));
}

const SCOPE_BOUNDARY_TYPES = new Set([
  "FunctionDeclaration",
  "FunctionExpression",
  "ArrowFunctionExpression",
  "ClassDeclaration",
  "ClassExpression",
]);

function directCallsAndJsxNames(node, matchableNames, calleeNames) {
  eachChildNode(node, (child) => {
    if (SCOPE_BOUNDARY_TYPES.has(child.type)) return;

    if (child.type === "CallExpression" || child.type === "OptionalCallExpression") {
      const name = calleeIdentifierName(child.callee);
      if (name && matchableNames.has(name)) calleeNames.push(name);
    }

    if (child.type === "JSXOpeningElement" && child.name.type === "JSXIdentifier") {
      const name = child.name.name;
      if (matchableNames.has(name)) calleeNames.push(name);
    }

    directCallsAndJsxNames(child, matchableNames, calleeNames);
  });
}

function directCallsAndJsxNamesForStatement(statement, matchableNames, calleeNames) {
  if (SCOPE_BOUNDARY_TYPES.has(statement.type)) return;

  directCallsAndJsxNames(statement, matchableNames, calleeNames);
}

function calleeIdentifierName(callee) {
  if (callee.type === "Identifier") return callee.name;
  if (
    callee.type === "MemberExpression" &&
    !callee.computed &&
    callee.object.type === "ThisExpression" &&
    callee.property.type === "Identifier"
  ) {
    return callee.property.name;
  }
  return null;
}

function reportInversions(context, definitions, syntheticRoot) {
  for (const {earlier, later} of findInversions(definitions, syntheticRoot)) {
    context.report({
      node: later.reportNode,
      messageId: ORDERING_MESSAGE_ID,
      data: {callee: later.name, caller: earlier.name},
    });
  }
}

function analyzeFunctionLikeScope(context, statements) {
  const boundaries = [];
  for (const statement of statements) directScopeBoundaries(statement, boundaries);

  const named = boundaries.filter((boundary) => boundary.name);
  const matchableNames = new Set(named.map((boundary) => boundary.name));
  const definitions = named.map((boundary) => ({
    name: boundary.name,
    reportNode: boundary.node,
    callees: [],
  }));
  const definitionsByName = new Map(definitions.map((definition) => [definition.name, definition]));

  named.forEach((boundary, index) => {
    if (!boundary.body) return;

    const calleeNames = [];
    directCallsAndJsxNames(boundary.body, matchableNames, calleeNames);
    definitions[index].callees = [...new Set(calleeNames)].map((name) => definitionsByName.get(name));
  });

  const rootCalleeNames = [];
  for (const statement of statements) directCallsAndJsxNamesForStatement(statement, matchableNames, rootCalleeNames);
  const syntheticRoot = {
    name: "<body>",
    callees: [...new Set(rootCalleeNames)].map((name) => definitionsByName.get(name)),
  };

  if (definitions.length >= 2) reportInversions(context, definitions, syntheticRoot);

  for (const boundary of boundaries) {
    if (boundary.body) analyzeFunctionLikeScope(context, boundary.body.body);
    if (boundary.classBody) analyzeClassScope(context, boundary.classBody);
  }
}

function analyzeClassScope(context, classBody) {
  const methods = classBody.body.filter(
    (element) =>
      element.type === "MethodDefinition" &&
      element.key.type === "Identifier" &&
      !element.computed &&
      element.value.type === "FunctionExpression"
  );

  const matchableNames = new Set(methods.map((method) => method.key.name));
  const definitions = methods.map((method) => ({name: method.key.name, reportNode: method.key, callees: []}));
  const definitionsByName = new Map(definitions.map((definition) => [definition.name, definition]));

  methods.forEach((method, index) => {
    const calleeNames = [];
    directCallsAndJsxNames(method.value.body, matchableNames, calleeNames);
    definitions[index].callees = [...new Set(calleeNames)].map((name) => definitionsByName.get(name));
  });

  if (definitions.length >= 2) reportInversions(context, definitions);

  for (const method of methods) analyzeFunctionLikeScope(context, method.value.body.body);
}

const orderingRule = {
  meta: {
    messages: {
      outOfOrder: "`{{callee}}` must be defined before `{{caller}}` (depth-first call order).",
    },
  },
  create(context) {
    return {
      Program(node) {
        analyzeFunctionLikeScope(context, node.body);
      },
    };
  },
};

const noProseCommentsRule = {
  create(context) {
    return {
      Program() {
        for (const comment of context.sourceCode.getAllComments()) {
          if (isAllowedComment(comment)) continue;

          context.report({loc: comment.loc, message: COMMENT_MESSAGE});
        }
      },
    };
  },
};

const plugin = {
  meta: {name: "source-policy"},
  rules: {
    ordering: orderingRule,
    "no-prose-comments": noProseCommentsRule,
  },
};

export default plugin;
