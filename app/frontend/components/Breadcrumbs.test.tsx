import { render, screen, waitFor } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Breadcrumbs from "./Breadcrumbs";

type PageState = {
  props: { breadcrumb: string | null };
  url: string;
};

let pageState: PageState = {
  props: { breadcrumb: null },
  url: "/",
};

vi.mock("@inertiajs/react", () => ({
  Link: ({ children, href, ...props }: { children: ReactNode; href: string }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
  usePage: () => pageState,
}));

describe("Breadcrumbs", () => {
  beforeEach(() => {
    pageState = { props: { breadcrumb: null }, url: "/" };
    window.sessionStorage.clear();
  });

  it("normalizes the current url and persists the most recent trail entry", async () => {
    window.sessionStorage.setItem(
      "breadcrumb_trail",
      JSON.stringify([
        { name: "One", url: "/one" },
        { name: "Two", url: "/two" },
        { name: "Three", url: "/three" },
        { name: "Four", url: "/four" },
      ]),
    );
    pageState = { props: { breadcrumb: "📦 Product" }, url: "/products/5?tab=all#top" };

    render(<Breadcrumbs />);

    expect(screen.getByRole("navigation", { name: "Breadcrumb" })).toBeInTheDocument();
    expect(screen.getByText("Product")).toBeInTheDocument();

    await waitFor(() => {
      expect(JSON.parse(window.sessionStorage.getItem("breadcrumb_trail") ?? "[]")).toEqual([
        { name: "Two", url: "/two" },
        { name: "Three", url: "/three" },
        { name: "Four", url: "/four" },
        { name: "📦 Product", url: "/products/5" },
      ]);
    });
  });
});
