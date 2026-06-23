import { render } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import TagSelect from "./TagSelect";

describe("TagSelect", () => {
  it("renders a combobox with the rs class prefix applied", () => {
    const { container } = render(<TagSelect options={[{ value: "tag-1", label: "Tag A" }]} />);

    expect(container.querySelector(".rs__control")).toBeInTheDocument();
  });

  it("applies the multi-value layout override to the control", () => {
    const { container } = render(<TagSelect options={[]} />);

    expect(container.querySelector(".rs__control")).toHaveClass("!h-auto");
  });
});
