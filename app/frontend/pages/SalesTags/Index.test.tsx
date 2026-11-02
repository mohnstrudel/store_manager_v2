import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Index from "./Index";
import { makeSalesTagCatalogRecord } from "./test/factories";
import type { SalesTagDetailRecord, SalesTagFormRecord } from "./types";

const tagColors = ["green", "pink", "sky", "violet", "olive"] as const;

function renderIndex(
  salesTag: SalesTagFormRecord | null = null,
  salesTagDetail: SalesTagDetailRecord | null = null,
) {
  return render(
    <Index
      sales_tag={salesTag}
      sales_tag_detail={salesTagDetail}
      sales_tags={[makeSalesTagCatalogRecord({ id: 1, name: "VIP Order", usage_count: 2 })]}
      tag_colors={[...tagColors]}
    />,
  );
}

describe("SalesTags/Index", () => {
  it("renders the heading, the add link and the catalog without a dialog", () => {
    renderIndex();

    expect(screen.getByRole("heading", { level: 1, name: "Sales Tags" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/sales_tags/new",
    );
    expect(screen.getByRole("cell", { name: "VIP Order" })).toBeInTheDocument();
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
  });

  it("opens the new tag dialog over the list when the page carries a blank draft", () => {
    renderIndex({ id: null, name: "", color: "green" });

    expect(screen.getByRole("dialog", { name: "New tag" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "VIP Order" })).toBeInTheDocument();
  });

  it("opens the edit dialog with the saved tag when the page carries one", () => {
    renderIndex({ id: 1, name: "VIP Order", color: "sky" });

    expect(screen.getByRole("dialog", { name: "Edit tag" })).toBeInTheDocument();
    expect(screen.getByRole("textbox", { name: "Name" })).toHaveValue("VIP Order");
  });

  it("opens the details dialog over the list when the page carries a tag detail", () => {
    renderIndex(null, {
      id: 1,
      name: "VIP Order",
      color: "sky",
      sales: [
        {
          id: 5,
          path: "/sales/5",
          label: "HSCM#1002, Ada Lovelace, ada@example.com",
          items: [],
        },
      ],
    });

    expect(screen.getByRole("dialog", { name: "VIP Order" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /HSCM#1002/ })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "VIP Order" })).toBeInTheDocument();
  });
});
