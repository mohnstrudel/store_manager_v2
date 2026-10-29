import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import type { SalesTagRecord } from "@/types/salesTag";

import TagPicker from "./TagPicker";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/singleSmartSelect"));

const options: SalesTagRecord[] = [
  { id: 4, name: "Rush", color: "pink" },
  { id: 2, name: "VIP", color: "sky" },
  { id: 9, name: "Wholesale", color: "green" },
];

function renderPicker(overrides: Partial<Parameters<typeof TagPicker>[0]> = {}) {
  const onChange = vi.fn<(ids: number[]) => void>();
  render(
    <TagPicker
      disabled={false}
      inputId="picker"
      label="Tags"
      onChange={onChange}
      options={options}
      selectedIds={[]}
      {...overrides}
    />,
  );
  return onChange;
}

function searchTags() {
  return screen.findByRole("combobox", { name: "Tags" });
}

function offeredLabels(select: HTMLElement) {
  return within(select)
    .getAllByRole("option")
    .filter((option) => option.getAttribute("value") !== "")
    .map((option) => option.textContent);
}

describe("TagPicker", () => {
  describe("searching existing tags", () => {
    it("labels the search and offers every unselected catalog tag in the given order", async () => {
      renderPicker();

      expect(offeredLabels(await searchTags())).toEqual(["Rush", "VIP", "Wholesale"]);
    });

    it("no longer offers tags that are already selected", async () => {
      renderPicker({ selectedIds: [9, 4] });

      expect(offeredLabels(await searchTags())).toEqual(["VIP"]);
    });

    it("reports the chosen id appended to the selection", async () => {
      const user = userEvent.setup();
      const onChange = renderPicker({ selectedIds: [4] });

      await user.selectOptions(await searchTags(), "VIP");

      expect(onChange).toHaveBeenLastCalledWith([4, 2]);
    });

    it("disables the search and links the error text", async () => {
      renderPicker({ disabled: true, errorId: "picker-error" });

      const search = await searchTags();

      expect(search).toBeDisabled();
      expect(search).toHaveAttribute("aria-describedby", "picker-error");
    });

    it("offers no way to create a tag", async () => {
      renderPicker();

      await searchTags();

      expect(screen.queryByRole("textbox")).not.toBeInTheDocument();
      expect(screen.queryByRole("radio")).not.toBeInTheDocument();
    });
  });

  describe("managing the selection", () => {
    it("lists selected tags in catalog order with their colors", () => {
      renderPicker({ selectedIds: [9, 4] });

      const items = within(screen.getByRole("list", { name: "Selected tags" })).getAllByRole(
        "listitem",
      );

      expect(items.map((item) => item.textContent)).toEqual(["Rush×", "Wholesale×"]);
      expect(
        items.map((item) => item.querySelector(".sales_tag")?.getAttribute("data-color")),
      ).toEqual(["pink", "green"]);
    });

    it("removes a selected tag and keeps the others", async () => {
      const user = userEvent.setup();
      const onChange = renderPicker({ selectedIds: [4, 2, 9] });

      await user.click(screen.getByRole("button", { name: "Remove VIP" }));

      expect(onChange).toHaveBeenLastCalledWith([4, 9]);
    });

    it("reports an empty selection when the last tag is removed", async () => {
      const user = userEvent.setup();
      const onChange = renderPicker({ selectedIds: [4] });

      await user.click(screen.getByRole("button", { name: "Remove Rush" }));

      expect(onChange).toHaveBeenLastCalledWith([]);
    });

    it("shows no list while nothing is selected", () => {
      renderPicker();

      expect(screen.queryByRole("list")).not.toBeInTheDocument();
    });

    it("disables the remove buttons while disabled", () => {
      renderPicker({ disabled: true, selectedIds: [4] });

      expect(screen.getByRole("button", { name: "Remove Rush" })).toBeDisabled();
    });
  });
});
