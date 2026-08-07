import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import Details from "./Details";
import { makeSaleShow } from "../test/factories";
import { makeSalePaymentPlan } from "@/test/factories";

describe("Sales/Show/Details", () => {
  it("renders the customer, note, totals, and store identifiers", () => {
    render(<Details sale={makeSaleShow()} />);

    expect(screen.getByText("Processing")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Dale Cooper" })).toHaveAttribute(
      "href",
      "/customers/2",
    );
    expect(screen.getByText("Leave at the door")).toBeInTheDocument();
    expect(screen.getByText("1060")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "7383283466569" })).toHaveAttribute(
      "href",
      "https://admin.shopify.com/store/68d8f5-af/orders/7383283466569",
    );
  });

  it("switches to the billing tab and renders the billing address", async () => {
    const user = userEvent.setup();
    render(<Details sale={makeSaleShow()} />);

    await user.click(screen.getByRole("button", { name: /Billing/ }));

    expect(screen.getByLabelText("More information")).toHaveTextContent("*");
    expect(screen.getByText("456 Side St")).toBeInTheDocument();
    expect(screen.getByText("Paris")).toBeInTheDocument();
  });

  it("hides empty customer and address details", () => {
    render(
      <Details
        sale={makeSaleShow({
          billing_address: null,
          customer: makeSaleShow().customer,
          note: "",
          shipping_address: null,
        })}
      />,
    );

    expect(screen.queryByText("Leave at the door")).not.toBeInTheDocument();
    expect(screen.queryByText("Note")).not.toBeInTheDocument();
    expect(screen.queryByText("Address 1")).not.toBeInTheDocument();
  });

  it("hides totals rows when there is no total, discount, or shipping data", () => {
    render(<Details sale={makeSaleShow({ discount_total: "", shipping_total: "", total: "" })} />);

    expect(screen.queryByText("Total", { selector: "dt" })).not.toBeInTheDocument();
    expect(screen.queryByText("Discount", { selector: "dt" })).not.toBeInTheDocument();
    expect(screen.queryByText("Shipping", { selector: "dt" })).not.toBeInTheDocument();
  });

  it("omits discount, shipping, and the whole address panel for a follow-up payment", () => {
    render(
      <Details
        sale={makeSaleShow({
          is_follow_up_payment: true,
          discount_total: undefined,
          shipping_total: undefined,
          shipping_address: undefined,
          billing_address: undefined,
          billing_differs_from_shipping: undefined,
        })}
      />,
    );

    expect(screen.queryByText("Discount", { selector: "dt" })).not.toBeInTheDocument();
    expect(screen.queryByText("Shipping", { selector: "dt" })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /Shipping/ })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /Billing/ })).not.toBeInTheDocument();
    expect(screen.queryByText("Address 1")).not.toBeInTheDocument();

    // The rest of the details card is unaffected.
    expect(screen.getByText("Processing")).toBeInTheDocument();
    expect(screen.getByText("1060")).toBeInTheDocument();
    expect(screen.getByText("ID", { selector: "dt" })).toBeInTheDocument();
  });

  it("shows the projected total right after the order total", () => {
    render(
      <Details
        sale={makeSaleShow({
          total: "300",
          payment_plans: [makeSalePaymentPlan({ projected_total: "1 020 EUR" })],
        })}
      />,
    );

    const total = screen.getByText("Total", { selector: "dt" });
    const projectedTotal = screen.getByText("Projected total", { selector: "dt" });

    expect(screen.getByText("300")).toBeInTheDocument();
    expect(screen.getByText("1 020 EUR")).toBeInTheDocument();
    // "Projected total" must render as the very next field after "Total".
    expect(total.nextElementSibling?.nextElementSibling).toBe(projectedTotal);
  });

  it("omits the projected total when no plan on the sale carries one", () => {
    render(
      <Details
        sale={makeSaleShow({
          payment_plans: [makeSalePaymentPlan({ projected_total: null })],
        })}
      />,
    );

    expect(screen.queryByText("Projected total", { selector: "dt" })).not.toBeInTheDocument();
  });

  it("omits the projected total when two plans on the sale disagree", () => {
    render(
      <Details
        sale={makeSaleShow({
          payment_plans: [
            makeSalePaymentPlan({ id: 1, projected_total: "1 020 EUR" }),
            makeSalePaymentPlan({ id: 2, projected_total: "990 EUR" }),
          ],
        })}
      />,
    );

    expect(screen.queryByText("Projected total", { selector: "dt" })).not.toBeInTheDocument();
  });

  it("shows the projected total when two plans on the sale agree", () => {
    render(
      <Details
        sale={makeSaleShow({
          payment_plans: [
            makeSalePaymentPlan({ id: 1, projected_total: "1 020 EUR" }),
            makeSalePaymentPlan({ id: 2, projected_total: "1 020 EUR" }),
          ],
        })}
      />,
    );

    expect(screen.getByText("Projected total", { selector: "dt" })).toBeInTheDocument();
    expect(screen.getByText("1 020 EUR")).toBeInTheDocument();
  });

  it("shows the origin sale as the first field of a follow-up payment", () => {
    render(
      <Details
        sale={makeSaleShow({
          is_follow_up_payment: true,
          payment_plans: [
            makeSalePaymentPlan({
              is_origin_sale: false,
              sale_part_number: 2,
              origin_sale: { path: "/sales/9", identifier: "HSCM#1746" },
            }),
          ],
        })}
      />,
    );

    const originField = screen.getByText("Original Sale", { selector: "dt" });
    expect(originField.nextElementSibling).toHaveTextContent("HSCM#1746");
    expect(screen.getByRole("link", { name: "HSCM#1746" })).toHaveAttribute("href", "/sales/9");
    // It comes before every other field.
    expect(originField.previousElementSibling).toBeNull();
  });

  it("shows the follow-up payment's plan progress in place of the address card", () => {
    const { container } = render(
      <Details
        sale={makeSaleShow({
          is_follow_up_payment: true,
          payment_plans: [
            makeSalePaymentPlan({
              expected_parts: 4,
              sale_part_number: 2,
              payments: [
                { sequence: 1, path: "/sales/1", identifier: "HSCM#1", is_current_sale: false },
                { sequence: 2, path: "/sales/2", identifier: "HSCM#2", is_current_sale: true },
              ],
            }),
          ],
        })}
      />,
    );

    expect(container.querySelector(".plan_progress_bar")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Payment 1 of 4 · HSCM#1" })).toHaveAttribute(
      "href",
      "/sales/1",
    );
    expect(screen.getByText("Payment 2 of 4 · HSCM#2 (this sale)")).toBeInTheDocument();
  });

  it("lists a plan's payments inline in the details card for the originating sale", () => {
    render(
      <Details
        sale={makeSaleShow({
          is_follow_up_payment: false,
          discount_total: "",
          payment_plans: [
            makeSalePaymentPlan({
              expected_parts: 3,
              sale_part_number: 1,
              payments: [
                { sequence: 1, path: "/sales/1", identifier: "HSCM#1", is_current_sale: true },
                { sequence: 2, path: "/sales/2", identifier: "HSCM#2", is_current_sale: false },
              ],
            }),
          ],
        })}
      />,
    );

    const link = screen.getByRole("link", { name: "Payment 2 of 3 · HSCM#2" });
    expect(link).toHaveAttribute("href", "/sales/2");
    expect(screen.getByText("Payment 1 of 3 · HSCM#1 (this sale)")).toBeInTheDocument();
    // The list sits in the plan's own card, under the progress bar it belongs
    // to — not in the totals card, which states this order's figures alone.
    const totals = screen.getByText("Total", { selector: "dt" }).closest(".card");
    expect(totals).not.toContainElement(link);
    expect(link.closest(".card")).toContainElement(screen.getByText("This payment"));
  });
});
