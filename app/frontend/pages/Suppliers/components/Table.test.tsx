import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it } from "vitest";
import Table from "./Table";
import { makeSupplier } from "../test/factories";


describe("Suppliers/components/Table", () => {
  it("renders supplier rows with show and edit links", () => {
        render(<Table suppliers={[makeSupplier()]}/>);

    expect(screen.getByRole("cell", { name: "GoodSmile" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute("href", "/suppliers/1");
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/suppliers/1/edit");
  });

  it("navigates to the supplier page when a row is clicked", async () => {
    const user = userEvent.setup();
        render(<Table suppliers={[makeSupplier()]}/>);
    const supplierRow = screen.getByRole("cell", { name: "GoodSmile" }).closest("tr");

    expect(supplierRow).not.toBeNull();
    await user.click(supplierRow!);

    expect(router.visit).toHaveBeenCalledWith("/suppliers/1");
  });
});


