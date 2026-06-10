import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Index from "./Index";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

const pagination = {
  current_page: 1,
  total_pages: 2,
  total_count: 50,
  limit: 50,
};

describe("Purchases/Index", () => {
  it("keeps pagination visible even when the list is empty", () => {
    render(
      <Index
        move_path="/purchases/move"
        pagination={pagination}
        purchases={[]}
        search={{ q: "" }}
        warehouses={[]}
      />,
    );

    expect(screen.getByRole("heading", { name: "Purchases" })).toBeInTheDocument();
    expect(screen.getAllByRole("navigation", { name: "Pagination" })).toHaveLength(2);
  });
});
