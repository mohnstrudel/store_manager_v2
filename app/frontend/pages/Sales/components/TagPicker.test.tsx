import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import type { SalesTagRecord } from "@/types/salesTag";

import TagPicker from "./TagPicker";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/multiSmartSelect"));

const options: SalesTagRecord[] = [
  { id: 4, name: "Rush", color: "red" },
  { id: 2, name: "VIP", color: "blue" },
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

describe("TagPicker", () => {
  it("labels the control and offers every catalog tag in the given order", async () => {
    renderPicker();

    const picker = await screen.findByRole("listbox", { name: "Tags" });

    expect(Array.from(picker.querySelectorAll("option"), (option) => option.textContent)).toEqual([
      "Rush",
      "VIP",
      "Wholesale",
    ]);
  });

  it("marks the selected ids", async () => {
    renderPicker({ selectedIds: [9, 4] });

    const picker = await screen.findByRole("listbox", { name: "Tags" });

    expect(
      Array.from(picker.querySelectorAll("option"), (option) => [
        option.textContent,
        option.selected,
      ]),
    ).toEqual([
      ["Rush", true],
      ["VIP", false],
      ["Wholesale", true],
    ]);
  });

  it("reports the chosen ids", async () => {
    const user = userEvent.setup();
    const onChange = renderPicker({ selectedIds: [4] });

    await user.selectOptions(await screen.findByRole("listbox", { name: "Tags" }), ["VIP"]);

    expect(onChange).toHaveBeenLastCalledWith([4, 2]);
  });

  it("reports an empty selection when everything is removed", async () => {
    const user = userEvent.setup();
    const onChange = renderPicker({ selectedIds: [4] });

    await user.deselectOptions(await screen.findByRole("listbox", { name: "Tags" }), ["Rush"]);

    expect(onChange).toHaveBeenLastCalledWith([]);
  });

  it("disables the control and links the error text", async () => {
    renderPicker({ disabled: true, errorId: "picker-error" });

    const picker = await screen.findByRole("listbox", { name: "Tags" });

    expect(picker).toBeDisabled();
    expect(picker).toHaveAttribute("aria-describedby", "picker-error");
  });
});
