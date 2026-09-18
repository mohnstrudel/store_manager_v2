const MESSAGE = "Do not add prose comments to code; use names, structure, and tests.";

export function scanCssComments(source) {
  const violations = [];
  const cursor = {index: 0, line: 1, column: 0};
  let inString = null;

  while (cursor.index < source.length) {
    const character = source[cursor.index];

    if (inString) {
      if (character === "\\") {
        advance(source, cursor, 2);
        continue;
      }
      if (character === inString) inString = null;
      advance(source, cursor);
      continue;
    }

    if (character === '"' || character === "'") {
      inString = character;
      advance(source, cursor);
      continue;
    }

    if (character === "/" && source[cursor.index + 1] === "*") {
      const violation = consumeBlockComment(source, cursor);
      if (violation) violations.push(violation);
      continue;
    }

    advance(source, cursor);
  }

  return violations;
}

function advance(source, cursor, count = 1) {
  for (let step = 0; step < count; step++) {
    if (source[cursor.index] === "\n") {
      cursor.line++;
      cursor.column = 0;
    } else {
      cursor.column++;
    }
    cursor.index++;
  }
}

function consumeBlockComment(source, cursor) {
  const start = {index: cursor.index, line: cursor.line, column: cursor.column};

  advance(source, cursor, 2);
  while (cursor.index < source.length && !(source[cursor.index] === "*" && source[cursor.index + 1] === "/")) {
    advance(source, cursor);
  }
  advance(source, cursor, 2);

  const body = source.slice(start.index + 2, cursor.index - 2);
  if (body.startsWith("!")) return null;

  return {
    line: start.line,
    column: start.column,
    length: cursor.index - start.index,
    message: MESSAGE,
  };
}
