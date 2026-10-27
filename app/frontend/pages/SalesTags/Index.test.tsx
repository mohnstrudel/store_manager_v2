import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { nextFormErrors, router } from "@/test/mocks/inertia";

import Index from "./Index";
import { makeSalesTagCatalogRecord } from "./test/factories";
import type { SalesTagCatalogRecord } from "./types";

const tagColors = ["red", "yellow", "green", "blue", "violet", "fuchsia"] as const;

function renderIndex(salesTags: SalesTagCatalogRecord[] = [], query = "") {
  return render(<Index sales_tags={salesTags} search={{ q: query }} tag_colors={[...tagColors]} />);
}

describe("SalesTags/Index", () => {
  it("lists catalog tags in the given order with their sale counts", () => {
    renderIndex([
      makeSalesTagCatalogRecord({ id: 2, name: "Rush", color: "red", usage_count: 3 }),
      makeSalesTagCatalogRecord({ id: 1, name: "VIP Order", usage_count: 0 }),
    ]);

    const rows = within(screen.getByRole("table")).getAllByRole("row").slice(1);

    expect(screen.getByRole("heading", { level: 1, name: "Sales Tags" })).toBeInTheDocument();
    expect(rows.map((row) => row.textContent)).toEqual(["Rush3", "VIP Order0"]);
  });

  it("places the add form first, then the search, then the tags table", () => {
    renderIndex([makeSalesTagCatalogRecord()]);

    const addButton = screen.getByRole("button", { name: "Add tag" });
    const search = screen.getByRole("searchbox");
    const table = screen.getByRole("table");

    expect(addButton.compareDocumentPosition(search)).toBe(Node.DOCUMENT_POSITION_FOLLOWING);
    expect(search.compareDocumentPosition(table)).toBe(Node.DOCUMENT_POSITION_FOLLOWING);
  });

  it("explains an empty catalog and an empty search result differently", () => {
    const { unmount } = renderIndex();
    expect(screen.getByText("No sales tags yet. Add the first one above.")).toBeInTheDocument();

    unmount();
    renderIndex([], "vip");
    expect(screen.getByText("No sales tags match “vip”.")).toBeInTheDocument();
  });

  it("offers the six named colors with yellow selected by default", async () => {
    const user = userEvent.setup();
    renderIndex();

    const colors = within(screen.getByRole("group", { name: "Color" })).getAllByRole("radio");

    expect(colors.map((radio) => radio.getAttribute("value"))).toEqual([...tagColors]);
    expect(screen.getByRole("radio", { name: "yellow" })).toBeChecked();

    await user.click(screen.getByRole("radio", { name: "violet" }));

    expect(screen.getByRole("radio", { name: "violet" })).toBeChecked();
    expect(screen.getByRole("radio", { name: "yellow" })).not.toBeChecked();
  });

  it("posts the draft name and color to the catalog, keeping the management search, then clears the draft", async () => {
    const user = userEvent.setup();
    renderIndex([], "vip");

    await user.type(screen.getByRole("textbox", { name: "Tag name" }), "VIP Order");
    await user.click(screen.getByRole("radio", { name: "blue" }));
    await user.click(screen.getByRole("button", { name: "Add tag" }));

    expect(router.post).toHaveBeenCalledWith(
      "/sales_tags?q=vip",
      { sales_tag: { name: "VIP Order", color: "blue" } },
      expect.objectContaining({ preserveState: true }),
    );
    expect(screen.getByRole("textbox", { name: "Tag name" })).toHaveValue("");
    expect(screen.getByRole("radio", { name: "yellow" })).toBeChecked();
  });

  it("keeps the draft and shows field errors when the server rejects the tag", async () => {
    nextFormErrors.mockReturnValue({
      name: "must be one or two words",
      color: "is not included in the list",
    });
    const user = userEvent.setup();
    renderIndex();

    await user.type(screen.getByRole("textbox", { name: "Tag name" }), "one two three");
    await user.click(screen.getByRole("radio", { name: "red" }));
    await user.click(screen.getByRole("button", { name: "Add tag" }));

    expect(screen.getByRole("textbox", { name: "Tag name" })).toHaveValue("one two three");
    expect(screen.getByRole("textbox", { name: "Tag name" })).toHaveAccessibleDescription(
      "must be one or two words",
    );
    expect(screen.getByText("is not included in the list")).toBeInTheDocument();
    expect(screen.getByRole("radio", { name: "red" })).toBeChecked();
  });
});
