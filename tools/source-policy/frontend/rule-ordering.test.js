import {describe, it} from "vitest";
import {RuleTester} from "oxlint/plugins-dev";
import plugin from "./oxlint-plugin.js";

RuleTester.describe = describe;
RuleTester.it = it;

const ruleTester = new RuleTester({languageOptions: {parserOptions: {lang: "tsx"}}});

ruleTester.run("ordering", plugin.rules.ordering, {
  valid: [
    // Caller followed depth-first by its callee subtree (A, B, D, C).
    `
      function a() {
        b();
        c();
      }

      function b() {
        d();
      }

      function d() {}

      function c() {}
    `,
    // Variable-bound arrow functions, caller before callee.
    `
      const entryPoint = () => {
        helper();
      };

      const helper = () => {};
    `,
    // Nested synthetic root: the enclosing body's own call order ranks its
    // direct nested declarations.
    `
      function outer() {
        function helper() {}
        function another() {}
        helper();
        another();
      }
    `,
    // JSX component reference, caller (Parent) before callee (Child).
    `
      function Parent() {
        return <Child />;
      }

      function Child() {
        return <div />;
      }
    `,
    // class \`this.method()\` edges, caller before callee.
    `
      class Widget {
        render() {
          return this.helper();
        }

        helper() {
          return 1;
        }
      }
    `,
    // Excluded: calls through another receiver do not create an edge.
    `
      function entry() {
        SomeService.helper();
        return 1;
      }

      function helper() {}
    `,
    // Excluded: computed calls do not create an edge.
    `
      function entry() {
        const key = "helper";
        return globalThis[key]();
      }

      function helper() {}
    `,
    // Excluded: a callback passed by reference (not called) does not create an edge.
    `
      function entry() {
        return [1, 2].map(helper);
      }

      function helper(value) {
        return value;
      }
    `,
    // Excluded: object-literal methods are not tracked as orderable declarations.
    `
      function entry() {
        const obj = {
          helper() {
            return 1;
          },
        };
        return obj.helper();
      }
    `,
    // Excluded: an imported name is not a local declaration to order.
    `
      import {helper} from "./helper";

      function entry() {
        return helper();
      }
    `,
  ],
  invalid: [
    {
      code: `
        function a() {
          b();
          c();
        }

        function b() {
          d();
        }

        function c() {}

        function d() {}
      `,
      errors: [{messageId: "outOfOrder", data: {callee: "d", caller: "c"}}],
    },
    {
      code: `
        const helper = () => {};

        const entryPoint = () => {
          helper();
        };
      `,
      errors: [{messageId: "outOfOrder", data: {callee: "entryPoint", caller: "helper"}}],
    },
    {
      code: `
        function outer() {
          function another() {}
          function helper() {}
          helper();
          another();
        }
      `,
      errors: [{messageId: "outOfOrder", data: {callee: "helper", caller: "another"}}],
    },
    {
      code: `
        function Child() {
          return <div />;
        }

        function Parent() {
          return <Child />;
        }
      `,
      errors: [{messageId: "outOfOrder", data: {callee: "Parent", caller: "Child"}}],
    },
    {
      code: `
        class Widget {
          helper() {
            return 1;
          }

          render() {
            return this.helper();
          }
        }
      `,
      errors: [{messageId: "outOfOrder", data: {callee: "render", caller: "helper"}}],
    },
  ],
});
