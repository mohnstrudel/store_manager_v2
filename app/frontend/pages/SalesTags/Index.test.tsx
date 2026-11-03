import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { router } from "@/test/mocks/inertia";

import Index from "./Index";
import { makeSalesTagCatalogRecord } from "./test/factories";
import type { SalesTagCatalogRecord, SalesTagDetailRecord, SalesTagFormRecord } from "./types";

const tagColors = ["green", "pink", "sky", "violet", "olive"] as const;

function renderIndex(
  salesTag: SalesTagFormRecord | null = null,
  salesTagDetail: SalesTagDetailRecord | null = null,
  salesTags: SalesTagCatalogRecord[] = [
    makeSalesTagCatalogRecord({ id: 1, name: "VIP Order", usage_count: 2 }),
  ],
) {
  return render(
    <Index
      sales_tag={salesTag}
      sales_tag_detail={salesTagDetail}
      sales_tags={salesTags}
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

  describe("deleting a tag", () => {
    it("asks naming the tag, its sale count and that sales are kept, then deletes on confirmation", async () => {
      const confirm = vi.spyOn(window, "confirm").mockReturnValue(true);
      const user = userEvent.setup();
      renderIndex();

      await user.click(screen.getByRole("button", { name: "Delete VIP Order" }));

      expect(confirm).toHaveBeenCalledWith('Delete "VIP Order" from 2 sales? Sales will be kept.');
      expect(router.delete).toHaveBeenCalledWith("/sales_tags/1");
    });

    it.each([
      [0, 'Delete "Rush"?'],
      [1, 'Delete "Rush" from 1 sale? Sales will be kept.'],
    ])("words the question for %i sales", async (usageCount, question) => {
      const confirm = vi.spyOn(window, "confirm").mockReturnValue(false);
      const user = userEvent.setup();
      renderIndex(null, null, [
        makeSalesTagCatalogRecord({ id: 4, name: "Rush", usage_count: usageCount }),
      ]);

      await user.click(screen.getByRole("button", { name: "Delete Rush" }));

      expect(confirm).toHaveBeenCalledWith(question);
    });

    it("changes nothing and keeps the page open when the question is declined", async () => {
      vi.spyOn(window, "confirm").mockReturnValue(false);
      const user = userEvent.setup();
      renderIndex();

      await user.click(screen.getByRole("button", { name: "Delete VIP Order" }));

      expect(router.delete).not.toHaveBeenCalled();
      expect(router.visit).not.toHaveBeenCalled();
      expect(screen.getByRole("cell", { name: "VIP Order" })).toBeInTheDocument();
    });

    it("deletes from the keyboard without opening the tag details", async () => {
      vi.spyOn(window, "confirm").mockReturnValue(true);
      const user = userEvent.setup();
      renderIndex();

      screen.getByRole("button", { name: "Delete VIP Order" }).focus();
      await user.keyboard("{Enter}");

      expect(router.delete).toHaveBeenCalledWith("/sales_tags/1");
      expect(router.visit).not.toHaveBeenCalled();
    });
  });
});
