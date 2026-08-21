import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { makeCustomerDetail } from "../test/factories";
import Details from "./Details";

describe("Customers/components/Details", () => {
  it("renders the customer's identifiers and contact details", () => {
    render(<Details customer={makeCustomerDetail()} />);

    expect(screen.getByText("SHOP-1")).toBeInTheDocument();
    expect(screen.getByText("dale@fbi.gov")).toBeInTheDocument();
  });

  it("shows nothing for missing identifiers and contact details", () => {
    render(
      <Details
        customer={makeCustomerDetail({
          shopify_id_short: "",
          woo_store_id: "",
          email: "",
          phone: "",
        })}
      />,
    );

    const [, dataRow] = screen.getAllByRole("row");
    const cells = within(dataRow).getAllByRole("cell");

    expect(cells[1]).toHaveTextContent("");
    expect(cells[4]).toHaveTextContent("");
    expect(cells[5]).toHaveTextContent("");
  });
});
