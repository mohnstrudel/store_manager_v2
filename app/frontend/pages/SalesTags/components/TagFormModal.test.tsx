import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { nextFormErrors, router } from "@/test/mocks/inertia";

import type { SalesTagFormRecord } from "../types";
import TagFormModal from "./TagFormModal";

const tagColors = ["green", "pink", "sky", "violet", "olive"] as const;
const keepsPageAndReplacesHistory = expect.objectContaining({
  preserveScroll: true,
  preserveState: true,
  replace: true,
});

function renderModal(salesTag: SalesTagFormRecord) {
  return render(<TagFormModal colors={[...tagColors]} salesTag={salesTag} />);
}

describe("SalesTags/TagFormModal", () => {
  it("opens a blank form for a new tag with every color to choose from and green selected", () => {
    renderModal({ id: null, name: "", color: "green" });

    const dialog = screen.getByRole("dialog", { name: "New tag" });

    expect(within(dialog).getByRole("textbox", { name: "Name" })).toHaveValue("");
    expect(within(dialog).getByRole("textbox", { name: "Name" })).toHaveFocus();
    expect(
      within(dialog)
        .getAllByRole("radio")
        .map((radio) => radio.getAttribute("value")),
    ).toEqual([...tagColors]);
    expect(within(dialog).getByRole("radio", { name: "green" })).toBeChecked();
    expect(within(dialog).getByRole("button", { name: "Create" })).toBeInTheDocument();
    expect(within(dialog).queryByRole("button", { name: "Save" })).not.toBeInTheDocument();
  });

  it("posts the draft name and color to the catalog, replacing the history entry", async () => {
    const user = userEvent.setup();
    renderModal({ id: null, name: "", color: "green" });

    await user.type(screen.getByRole("textbox", { name: "Name" }), "VIP Order");
    await user.click(screen.getByRole("radio", { name: "sky" }));
    await user.click(screen.getByRole("button", { name: "Create" }));

    expect(router.post).toHaveBeenCalledWith(
      "/sales_tags",
      { sales_tag: { name: "VIP Order", color: "sky" } },
      keepsPageAndReplacesHistory,
    );
  });

  it("opens an existing tag with its saved name and color and patches that tag", async () => {
    const user = userEvent.setup();
    renderModal({ id: 7, name: "VIP Order", color: "sky" });

    const dialog = screen.getByRole("dialog", { name: "Edit tag" });
    const name = within(dialog).getByRole("textbox", { name: "Name" });
    expect(name).toHaveValue("VIP Order");
    expect(within(dialog).getByRole("radio", { name: "sky" })).toBeChecked();
    expect(within(dialog).queryByRole("button", { name: "Create" })).not.toBeInTheDocument();

    await user.clear(name);
    await user.type(name, "VIP Client");
    await user.click(within(dialog).getByRole("radio", { name: "violet" }));
    await user.click(within(dialog).getByRole("button", { name: "Update" }));

    expect(router.patch).toHaveBeenCalledWith(
      "/sales_tags/7",
      { sales_tag: { name: "VIP Client", color: "violet" } },
      keepsPageAndReplacesHistory,
    );
  });

  it.each(["Cancel", "Close"])(
    "%s leaves for the list without writing, replacing the history entry",
    async (label) => {
      const user = userEvent.setup();
      renderModal({ id: 7, name: "VIP Order", color: "sky" });

      await user.type(screen.getByRole("textbox", { name: "Name" }), " Client");
      await user.click(screen.getByRole("button", { name: label }));

      expect(router.visit).toHaveBeenCalledWith("/sales_tags", keepsPageAndReplacesHistory);
      expect(router.patch).not.toHaveBeenCalled();
      expect(router.post).not.toHaveBeenCalled();
    },
  );

  it("keeps the dialog open with the draft and field errors when the server rejects it", async () => {
    nextFormErrors.mockReturnValue({
      name: "has already been taken",
      color: "is not included in the list",
    });
    const user = userEvent.setup();
    renderModal({ id: 7, name: "Rush", color: "pink" });

    const name = screen.getByRole("textbox", { name: "Name" });
    await user.clear(name);
    await user.type(name, "vip order");
    await user.click(screen.getByRole("radio", { name: "olive" }));
    await user.click(screen.getByRole("button", { name: "Update" }));

    expect(screen.getByRole("dialog", { name: "Edit tag" })).toBeInTheDocument();
    expect(name).toHaveValue("vip order");
    expect(name).toHaveAccessibleDescription("has already been taken");
    expect(screen.getByText("is not included in the list")).toBeInTheDocument();
    expect(screen.getByRole("radio", { name: "olive" })).toBeChecked();
  });
});
