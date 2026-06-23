import { render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it } from "vitest";
import { mockPage } from "@/test/mocks/inertia";
import Breadcrumbs from "./Breadcrumbs";

describe("Breadcrumbs", () => {
  beforeEach(() => {
    window.sessionStorage.clear();
  });

  it("renders nothing when the trail is empty", () => {
    const { container } = render(<Breadcrumbs />);
    expect(container.firstChild).toBeNull();
  });

  it("limits the trail to 4 entries", async () => {
    window.sessionStorage.setItem(
      "breadcrumb_trail",
      JSON.stringify([
        { name: "One", url: "/one" },
        { name: "Two", url: "/two" },
        { name: "Three", url: "/three" },
        { name: "Four", url: "/four" },
      ]),
    );
    mockPage({ url: "/five", props: { breadcrumb: "Five" } });
    render(<Breadcrumbs />);

    await waitFor(() => {
      const saved = JSON.parse(window.sessionStorage.getItem("breadcrumb_trail") ?? "[]");
      expect(saved).toHaveLength(4);
      expect(saved[0].name).toBe("Two");
      expect(saved[3].name).toBe("Five");
    });
  });

  it("renders the current page without a link and previous pages as links", async () => {
    window.sessionStorage.setItem(
      "breadcrumb_trail",
      JSON.stringify([{ name: "Products", url: "/products" }]),
    );
    mockPage({ url: "/products/1", props: { breadcrumb: "Pikachu" } });
    render(<Breadcrumbs />);

    await waitFor(() => {
      expect(screen.getByRole("link", { name: "Products" })).toHaveAttribute("href", "/products");
      expect(screen.queryByRole("link", { name: "Pikachu" })).toBeNull();
      expect(screen.getByText("Pikachu")).toBeInTheDocument();
    });
  });

  it("does not create duplicate entries when the same page is visited twice", async () => {
    window.sessionStorage.setItem(
      "breadcrumb_trail",
      JSON.stringify([{ name: "Pikachu", url: "/products/1" }]),
    );
    mockPage({ url: "/products/1", props: { breadcrumb: "Pikachu" } });
    render(<Breadcrumbs />);

    await waitFor(() => {
      const saved = JSON.parse(window.sessionStorage.getItem("breadcrumb_trail") ?? "[]");
      const pikachu = saved.filter((e: { name: string }) => e.name === "Pikachu");
      expect(pikachu).toHaveLength(1);
    });
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
    mockPage({ url: "/products/5?tab=all#top", props: { breadcrumb: "📦 Product" } });
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
