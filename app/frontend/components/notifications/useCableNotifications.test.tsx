import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { useCableNotifications } from "./useCableNotifications";

vi.mock("@rails/actioncable", () => {
  throw new Error("Failed to fetch dynamically imported module");
});

describe("useCableNotifications", () => {
  it("leaves the page working without an unhandled rejection when the live connection cannot load", async () => {
    render(<PageWithLiveNotifications />);
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(screen.getByText("Page content")).toBeInTheDocument();
  });
});

function PageWithLiveNotifications() {
  useCableNotifications(true);

  return <p>Page content</p>;
}
