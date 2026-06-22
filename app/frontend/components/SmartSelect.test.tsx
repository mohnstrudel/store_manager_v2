import { render } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import SmartSelect from "./SmartSelect";

describe("SmartSelect", () => {
  it("renders a combobox with the rs class prefix applied", () => {
    const { container } = render(<SmartSelect options={[{ value: 1, label: "Option A" }]} />);

    expect(container.querySelector(".rs__control")).toBeInTheDocument();
  });
});
