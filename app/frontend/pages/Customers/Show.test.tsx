import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { describe, expect, it, vi } from "vitest";
import Show from "./Show";

vi.mock("@inertiajs/react", () => ({
  Link: ({ children, href, ...props }: { children: ReactNode; href: string }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
  router: {
    delete: vi.fn<(...args: unknown[]) => unknown>(),
    visit: vi.fn<(...args: unknown[]) => unknown>(),
  },
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
      sale_identifier: "HSCM#1958",
      sold_product_name: "Twin Peaks Cherry Pie",
      product_thumb_url: null,
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
    expect(
      screen.getByRole("img", {
        name: "Image unavailable for Twin Peaks Cherry Pie",
      }),
    ).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Twin Peaks Cherry Pie HSCM#1958" })).toHaveAttribute(
      "href",
      "/sales/10",
    );
    expect(screen.getByText("Twin Peaks Cherry Pie")).toHaveClass("group-hover:text-blue-600");
    expect(screen.getByText("Completed")).toBeInTheDocument();
  });
});
