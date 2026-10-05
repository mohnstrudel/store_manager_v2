import { createInertiaApp } from "@inertiajs/react";
import createServer from "@inertiajs/react/server";
import { createElement } from "react";
import ReactDOMServer from "react-dom/server";

import AppLayout from "@/layouts/AppLayout";
import { resolvePage } from "@/utils/resolvePage";

createServer((page) =>
  createInertiaApp({
    page,
    render: ReactDOMServer.renderToString,
    layout: () => AppLayout,
    resolve: resolvePage,
    setup: ({ App, props }) => createElement(App, props),
  }),
);
