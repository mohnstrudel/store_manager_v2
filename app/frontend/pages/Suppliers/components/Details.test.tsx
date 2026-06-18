import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Details from "./Details";
import { makeSupplier } from "../test/factories";


describe("Suppliers/components/Details", () => {
  it("renders the supplier detail table", () => {
        render(<Details supplier={makeSupplier()}/>);

    expect(screen.getByRole("cell", { name: "1" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "GoodSmile" })).toBeInTheDocument();
    expect(screen.getByText("19. May '26 16:18")).toBeInTheDocument();
    expect(screen.getByText("20. May '26 16:18")).toBeInTheDocument();
  });
});


