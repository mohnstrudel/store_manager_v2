import { fireEvent, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { router } from "@/test/mocks/inertia";

import type { SalesTagDetailRecord } from "../types";
import TagDetailModal from "./TagDetailModal";

const meruem = "Hunter X Hunter — Meruem | Hunter Fan Studio → 1:4";

const detail: SalesTagDetailRecord = {
  id: 7,
  name: "VIP Order",
  color: "sky",
  sales: [
    {
      id: 2,
      path: "/sales/hscm-2377",
      label: `HSCM#2377, Adrian Zwatschek, planetholyy@gmail.com, ${meruem}`,
      items: [
        { id: 21, title: "Spirited Away", product_thumb_url: null },
        { id: 22, title: meruem, product_thumb_url: "/thumbs/meruem.webp" },
      ],
    },
    {
      id: 1,
      path: "/sales/hscm-1001",
      label: "HSCM#1001, Ada Lovelace, ada@example.com",
      items: [],
    },
  ],
};

function listItems() {
  return within(screen.getByRole("list", { name: "Sales with this tag" })).getAllByRole("listitem");
}

describe("SalesTags/TagDetailModal", () => {
  it("titles the dialog with the tag name on a heading that carries the tag's color", () => {
    render(<TagDetailModal salesTag={detail} />);

    const heading = screen.getByRole("heading", { name: "VIP Order" });

    expect(screen.getByRole("dialog", { name: "VIP Order" })).toBeInTheDocument();
    expect(within(heading).getByText("VIP Order")).toHaveAttribute("data-color", "sky");
  });

  it("numbers the sales in the given order, each with its link and a preview of its first item picture", () => {
    render(<TagDetailModal salesTag={detail} />);

    const [first, second] = listItems();

    expect(first).toHaveTextContent(/^1\./);
    expect(within(first).getByRole("link")).toHaveTextContent(detail.sales[0].label);
    expect(within(first).getByRole("link")).toHaveAttribute("href", "/sales/hscm-2377");
    expect(within(first).getByRole("img", { name: meruem })).toHaveAttribute(
      "src",
      "/thumbs/meruem.webp",
    );
    expect(second).toHaveTextContent(/^2\./);
    expect(within(second).getByRole("link")).toHaveAttribute("href", "/sales/hscm-1001");
  });

  it("shows a placeholder when no item of the sale has a picture", () => {
    render(<TagDetailModal salesTag={detail} />);

    const [, second] = listItems();

    expect(
      within(second).getByRole("img", { name: `Image unavailable for ${detail.sales[1].label}` }),
    ).toBeInTheDocument();
  });

  it("falls back to the placeholder when the picture fails to load", () => {
    render(<TagDetailModal salesTag={detail} />);

    const [first] = listItems();
    fireEvent.error(within(first).getByRole("img", { name: meruem }));

    expect(
      within(first).getByRole("img", { name: `Image unavailable for ${detail.sales[0].label}` }),
    ).toBeInTheDocument();
  });

  it("says when no sale uses the tag", () => {
    render(<TagDetailModal salesTag={{ ...detail, sales: [] }} />);

    expect(screen.getByText("No sale uses this tag yet.")).toBeInTheDocument();
    expect(screen.queryByRole("list", { name: "Sales with this tag" })).not.toBeInTheDocument();
  });

  it("closes onto the list, replacing the history entry", async () => {
    const user = userEvent.setup();
    render(<TagDetailModal salesTag={detail} />);

    await user.click(screen.getByRole("button", { name: "Close" }));

    expect(router.visit).toHaveBeenCalledWith("/sales_tags", {
      preserveScroll: true,
      preserveState: true,
      replace: true,
    });
  });
});
