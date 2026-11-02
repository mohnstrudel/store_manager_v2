import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { router } from "@/test/mocks/inertia";

import { makeSalesTagCatalogRecord } from "../test/factories";
import Table from "./Table";

const rush = makeSalesTagCatalogRecord({ id: 2, name: "Rush", color: "pink", usage_count: 3 });
const vip = makeSalesTagCatalogRecord({ id: 1, name: "VIP Order", color: "sky", usage_count: 0 });

function bodyRows() {
  return within(screen.getByRole("table")).getAllByRole("row").slice(1);
}

describe("SalesTags/Table", () => {
  it("lists tags in the given order with their sale counts and an edit link", () => {
    render(<Table salesTags={[rush, vip]} />);

    expect(
      bodyRows().map((row) =>
        within(row)
          .getAllByRole("cell")
          .slice(0, 2)
          .map((cell) => cell.textContent),
      ),
    ).toEqual([
      ["Rush", "3"],
      ["VIP Order", "0"],
    ]);
    expect(screen.getByRole("link", { name: "Edit Rush" })).toHaveAttribute(
      "href",
      "/sales_tags/2/edit",
    );
    expect(screen.getByRole("link", { name: "Edit VIP Order" })).toHaveAttribute(
      "href",
      "/sales_tags/1/edit",
    );
  });

  it("opens the tag details from a row click, keeping the list and its scroll position", async () => {
    const user = userEvent.setup();
    render(<Table salesTags={[rush, vip]} />);

    await user.click(within(bodyRows()[1]).getByText("VIP Order"));

    expect(router.visit).toHaveBeenCalledWith("/sales_tags/1", {
      preserveScroll: true,
      preserveState: true,
    });
  });

  it("filters rows by a case-insensitive part of the name as you type, and restores them", async () => {
    const user = userEvent.setup();
    render(<Table salesTags={[rush, vip]} />);

    const filter = screen.getByRole("searchbox", { name: "Filter tags" });
    await user.type(filter, " vIP ");

    expect(bodyRows().map((row) => within(row).getAllByRole("cell")[0].textContent)).toEqual([
      "VIP Order",
    ]);

    await user.clear(filter);

    expect(bodyRows()).toHaveLength(2);
  });

  it("says when no tag matches the filter", async () => {
    const user = userEvent.setup();
    render(<Table salesTags={[rush, vip]} />);

    await user.type(screen.getByRole("searchbox", { name: "Filter tags" }), "zzz");

    expect(screen.getByText("No tags match “zzz”.")).toBeInTheDocument();
    expect(screen.queryByRole("table")).not.toBeInTheDocument();
  });

  it("invites adding the first tag when the catalog is empty", () => {
    render(<Table salesTags={[]} />);

    expect(screen.getByRole("link", { name: /Add your first sales tag/ })).toHaveAttribute(
      "href",
      "/sales_tags/new",
    );
    expect(screen.queryByRole("searchbox")).not.toBeInTheDocument();
  });
});
