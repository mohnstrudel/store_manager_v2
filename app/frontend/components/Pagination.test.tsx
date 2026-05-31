import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { describe, expect, it, vi } from "vitest";
import Pagination from "./Pagination";

vi.mock("@inertiajs/react", () => ({
  Link: ({ children, href, ...props }: { children: ReactNode; href: string }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
}));

describe("Pagination", () => {
  it("renders first pages, current page, last page, previous, and next links", () => {
    render(
      <Pagination pagination={{ current_page: 6, total_pages: 10 }} path="/items" query="makima" />,
    );

    expect(screen.getByRole("link", { name: "Previous" })).toHaveAttribute(
      "href",
      "/items?page=5&q=makima",
    );
    expect(screen.getByRole("link", { name: "1" })).toHaveAttribute(
      "href",
      "/items?page=1&q=makima",
    );
    expect(screen.getByRole("link", { name: "2" })).toHaveAttribute(
      "href",
      "/items?page=2&q=makima",
    );
    expect(screen.getByRole("link", { name: "3" })).toHaveAttribute(
      "href",
      "/items?page=3&q=makima",
    );
    expect(screen.getByText("6")).toHaveAttribute("aria-current", "page");
    expect(screen.getByRole("link", { name: "10" })).toHaveAttribute(
      "href",
      "/items?page=10&q=makima",
    );
    expect(screen.queryByText("Page 6 of 10")).not.toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Next" })).toHaveAttribute(
      "href",
      "/items?page=7&q=makima",
    );
  });

  it("omits the previous link on the first page", () => {
    render(<Pagination pagination={{ current_page: 1, total_pages: 3 }} path="/items" />);

    expect(screen.queryByRole("link", { name: "Previous" })).not.toBeInTheDocument();
    expect(screen.getByText("1")).toHaveAttribute("aria-current", "page");
    expect(screen.getByRole("link", { name: "Next" })).toHaveAttribute("href", "/items?page=2");
  });

  it("omits the next link on the last page", () => {
    render(<Pagination pagination={{ current_page: 3, total_pages: 3 }} path="/items" />);

    expect(screen.getByRole("link", { name: "Previous" })).toHaveAttribute("href", "/items?page=2");
    expect(screen.getByText("3")).toHaveAttribute("aria-current", "page");
    expect(screen.queryByRole("link", { name: "Next" })).not.toBeInTheDocument();
  });

  it("does not render when there is only one page", () => {
    render(<Pagination pagination={{ current_page: 1, total_pages: 1 }} path="/items" />);

    expect(screen.queryByRole("navigation", { name: "Pagination" })).not.toBeInTheDocument();
  });
});
