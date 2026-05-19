import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { describe, expect, it, vi } from "vitest";
import Show from "./Show";

vi.mock("@/components/Link", () => ({
  default: ({ children, href }: { children: ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}));

vi.mock("@inertiajs/react", () => ({
  router: { delete: vi.fn(), visit: vi.fn() },
}));

const customer = {
  id: 1,
  first_name: "Dale",
  last_name: "Cooper",
  full_name: "Dale Cooper",
  email: "dale@fbi.gov",
  phone: "+1555000",
  woo_store_id: "WOO-1",
  shopify_id: "",
  shopify_id_short: "",
  created_at: "19. May '26 10:00",
  updated_at: "19. May '26 10:00",
  path: "/customers/1",
};

describe("Customers/Show", () => {
  it("renders customer details and heading", () => {
    render(<Show active_sales={[]} completed_sales={[]} customer={customer} />);

    expect(screen.getByRole("heading", { name: "Dale Cooper" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "dale@fbi.gov" })).toBeInTheDocument();
  });

  it("renders sales when present", () => {
    const sale = {
      id: 10,
      path: "/sales/10",
      store_id: "1001",
      store_type: "shopify" as const,
      status: "completed",
      active: false,
      total: "100",
      country: "DE",
      city: "Berlin",
      note: "",
      created_at: "19. May '26",
      updated_at: "19. May '26",
    };

    render(<Show active_sales={[]} completed_sales={[sale]} customer={customer} />);

    expect(screen.getByRole("heading", { name: "Completed Sales" })).toBeInTheDocument();
    expect(screen.getByText("Completed")).toBeInTheDocument();
  });
});
