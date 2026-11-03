import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import TagBadges from "./TagBadges";

describe("TagBadges", () => {
  it("renders each tag name in the order given and exposes its color", () => {
    render(
      <TagBadges
        tags={[
          { id: 2, name: "Rush", color: "pink" },
          { id: 1, name: "VIP Order", color: "sky" },
        ]}
      />,
    );

    const items = within(screen.getByRole("list")).getAllByRole("listitem");

    expect(items.map((item) => item.textContent)).toEqual(["Rush", "VIP Order"]);
    expect(screen.getByText("Rush")).toHaveAttribute("data-color", "pink");
    expect(screen.getByText("VIP Order")).toHaveAttribute("data-color", "sky");
  });

  it("renders nothing for an untagged sale", () => {
    const { container } = render(<TagBadges tags={[]} />);

    expect(container).toBeEmptyDOMElement();
  });
});
