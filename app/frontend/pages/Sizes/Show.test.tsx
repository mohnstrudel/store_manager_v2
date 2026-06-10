import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Show from "./Show";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Sizes/Show", () => {
  it("renders size details and linked products", () => {
    render(
      <Show
        products={[
          {
            id: 10,
            full_title: "Studio Ghibli — Spirited Away",
            path: "/products/10",
          },
        ]}
        size={{
          id: 1,
          value: "1:6",
          created_at: "19. May '26 16:18",
          updated_at: "19. May '26 16:18",
        }}
      />,
    );

    expect(screen.getByRole("heading", { name: "1:6" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Products" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "Studio Ghibli — Spirited Away" })).toBeInTheDocument();
  });
});
