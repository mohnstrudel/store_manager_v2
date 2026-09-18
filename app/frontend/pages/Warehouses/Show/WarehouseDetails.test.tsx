import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { makeWarehouseShowRecord } from "../test/factories";
import { WarehouseDetails } from "./WarehouseDetails";

describe("Warehouses/Show/WarehouseDetails", () => {
  it("links the courier tracking url when present", () => {
    render(
      <WarehouseDetails
        warehouse={makeWarehouseShowRecord({
          courier_tracking_url: "https://tracking.example/container",
        })}
      />,
    );

    expect(
      screen.getByRole("link", { name: "https://tracking.example/container" }),
    ).toHaveAttribute("href", "https://tracking.example/container");
  });

  it("hides the courier tracking url row when unavailable", () => {
    render(<WarehouseDetails warehouse={makeWarehouseShowRecord({ courier_tracking_url: "" })} />);

    expect(screen.queryByRole("link")).not.toBeInTheDocument();
    expect(screen.queryByText("Courier Tracking URL")).not.toBeInTheDocument();
  });
});
