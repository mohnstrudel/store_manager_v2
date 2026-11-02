import { router } from "@inertiajs/react";
import { render, screen, within } from "@testing-library/react";
import userEvent, { type UserEvent } from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makeSalePaymentPlan } from "@/test/factories";
import { nextFormErrors } from "@/test/mocks/inertia";
import type { SalesTagRecord } from "@/types/salesTag";

import Show from "./Show";
import { makeSaleProfitability, makeSaleShow } from "./test/factories";
import type { SaleShowRecord } from "./types";

const tagColors = ["green", "pink", "taupe", "sky", "violet", "fuchsia", "mauve", "olive"] as const;
const rush: SalesTagRecord = { id: 4, name: "Rush", color: "pink" };
const vip: SalesTagRecord = { id: 2, name: "VIP", color: "sky" };
const wholesale: SalesTagRecord = { id: 9, name: "Wholesale", color: "green" };

describe("Sales/Show", () => {
  it("renders the Shopify sale title and composed sections", () => {
    renderShow();

    expect(screen.getByRole("heading", { name: "Sale HSCM#1746" })).toBeInTheDocument();
    expect(screen.getByText("Pikachu Figure")).toBeInTheDocument();
    expect(screen.getByText("Leave at the door")).toBeInTheDocument();
  });

  it("renders the WooCommerce sale title when the sale is only linked to Woo", () => {
    renderShow({
      shop_identifier: "WOO-1",
      shopify_id: "",
      shopify_name: "",
      woo_store_id: "WOO-1",
    });

    expect(screen.getByRole("heading", { name: "Sale WOO-1" })).toBeInTheDocument();
  });

  it("falls back to the local id in the title when the sale has no store identifiers", () => {
    renderShow({ shop_identifier: "", shopify_id: "", shopify_name: "", woo_store_id: "" });

    expect(screen.getByRole("heading", { name: "Sale 1" })).toBeInTheDocument();
  });

  it("renders no subtitle under the title, regardless of a payment plan", () => {
    const { container } = renderShow({
      payment_plans: [makeSalePaymentPlan({ is_origin_sale: false, sale_part_number: 2 })],
    });

    expect(container.querySelector("header h3")).not.toBeInTheDocument();
  });

  describe("follow-up payment presentation", () => {
    it("titles a follow-up payment as Payment, keeping the same identifier a sale would show", () => {
      renderShow({ is_follow_up_payment: true });

      expect(screen.getByRole("heading", { name: "Payment HSCM#1746" })).toBeInTheDocument();
      expect(screen.queryByRole("heading", { name: "Sale HSCM#1746" })).not.toBeInTheDocument();
    });

    it("strips the page down to what a follow-up payment actually knows", () => {
      renderShow({
        is_follow_up_payment: true,
        profitability: null,
        sale_items: [],
        shipping_address: undefined,
        billing_address: undefined,
        billing_differs_from_shipping: undefined,
        discount_total: undefined,
        shipping_total: undefined,
        payment_plans: [
          makeSalePaymentPlan({
            is_origin_sale: false,
            sale_part_number: 2,
            origin_sale: { path: "/sales/9", identifier: "HSCM#1745" },
          }),
        ],
      });

      expect(screen.queryByRole("article", { name: "Profit summary" })).not.toBeInTheDocument();
      expect(screen.queryByRole("table")).not.toBeInTheDocument();
      expect(screen.queryByRole("button", { name: /Shipping/ })).not.toBeInTheDocument();
      expect(screen.queryByRole("button", { name: /Billing/ })).not.toBeInTheDocument();
    });

    it("still shows the title, status, customer, total, identifiers, and place in the plan", () => {
      renderShow({
        is_follow_up_payment: true,
        payment_plans: [
          makeSalePaymentPlan({
            is_origin_sale: false,
            sale_part_number: 2,
            origin_sale: { path: "/sales/9", identifier: "HSCM#1745" },
          }),
        ],
      });

      expect(screen.getByRole("heading", { name: "Payment HSCM#1746" })).toBeInTheDocument();
      expect(screen.getByText("Processing")).toBeInTheDocument();
      const totalField = screen.getByText("Total", { selector: "dt" });
      expect(totalField.nextElementSibling).toHaveTextContent("1060");
      expect(screen.getByRole("link", { name: "HSCM#1745" })).toHaveAttribute("href", "/sales/9");
    });
  });

  it("shows the profit summary as a card of its own", () => {
    renderShow({ partially_paid: true, profitability: makeSaleProfitability() });

    const summary = screen.getByRole("article", { name: "Profit summary" });
    expect(within(summary).getByText("Gross Revenue")).toBeInTheDocument();
  });

  it("leaves the profit summary out when the sale makes no profit claim", () => {
    renderShow({ profitability: null });

    expect(screen.queryByRole("article", { name: "Profit summary" })).not.toBeInTheDocument();
  });

  it("routes a plan's sibling payments through Details rather than a top-of-page card", () => {
    renderShow({
      payment_plans: [
        makeSalePaymentPlan({
          expected_parts: 4,
          sale_part_number: 1,
          payments: [
            { sequence: 1, path: "/sales/1", identifier: "HSCM#1746", is_current_sale: true },
            { sequence: 2, path: "/sales/2", identifier: "HSCM#1747", is_current_sale: false },
          ],
        }),
      ],
    });

    expect(screen.getByRole("link", { name: "Payment 2 of 4 · HSCM#1747" })).toHaveAttribute(
      "href",
      "/sales/2",
    );
    expect(screen.getByText("Payment 1 of 4 · HSCM#1746 (this sale)")).toBeInTheDocument();
  });

  describe("tags", () => {
    const reloadedProps = ["sale", "tag_options", "tag_colors", "can_tag_sales"];

    it("sits directly beneath the heading, before the main content, without a heading or card of its own", () => {
      const { container } = renderShow({ tags: [rush, vip] });

      const shell = container.querySelector("header")?.nextElementSibling;
      const badges = Array.from(shell?.querySelectorAll(".sales_tags li") ?? []);

      expect(badges.map((badge) => badge.textContent)).toEqual(["Rush", "VIP"]);
      expect(screen.getAllByRole("heading").map((heading) => heading.textContent)).not.toContain(
        "Tags",
      );
      expect(shell?.querySelector("article, table")).not.toBeInTheDocument();
      expect(shell?.nextElementSibling).toContainElement(screen.getByText("Pikachu Figure"));
    });

    it("keeps the Payment title and leaves follow-up content reduced when tagged", () => {
      renderShow({ tags: [vip], is_follow_up_payment: true, sale_items: [] });

      expect(screen.getByRole("heading", { name: "Payment HSCM#1746" })).toBeInTheDocument();
      expect(screen.getByText("VIP")).toBeInTheDocument();
      expect(screen.queryByText("Pikachu Figure")).not.toBeInTheDocument();
    });

    it("offers a quiet Edit tags control for a tagged sale", () => {
      renderShow({ tags: [vip] });

      expect(screen.getByRole("button", { name: "Edit tags" })).toBeInTheDocument();
      expect(screen.queryByRole("button", { name: "Add tags" })).not.toBeInTheDocument();
    });

    it("offers Add tags and no empty list for an untagged sale", () => {
      const { container } = renderShow({ tags: [] });

      expect(screen.getByRole("button", { name: "Add tags" })).toBeInTheDocument();
      expect(container.querySelector(".sales_tags")).not.toBeInTheDocument();
    });

    it("shows badges without a control for users who cannot tag sales", () => {
      renderShow({ tags: [vip] }, { can_tag_sales: false });

      expect(screen.getByText("VIP")).toBeInTheDocument();
      expect(screen.queryByRole("button", { name: /tags$/ })).not.toBeInTheDocument();
    });

    it("renders nothing between the heading and the content when there is nothing to show or edit", () => {
      const { container } = renderShow({ tags: [] }, { can_tag_sales: false });

      expect(container.querySelector("header")?.nextElementSibling).toContainElement(
        screen.getByText("Pikachu Figure"),
      );
    });

    it("saves the draft with the marker and original ids, reloading only the sale and tag props", async () => {
      const user = userEvent.setup();
      renderShow({ tags: [vip] });

      await openEditor(user);
      await user.click(screen.getByRole("checkbox", { name: "Rush" }));
      await user.click(screen.getByRole("button", { name: "Save" }));

      expect(router.patch).toHaveBeenCalledTimes(1);
      expect(router.patch).toHaveBeenCalledWith(
        "/sales/1/tags",
        {
          sale: { tagging: { submitted: "1", ids: [2, 4], original_ids: [2] } },
          return_to: "/",
        },
        expect.objectContaining({ only: reloadedProps, preserveScroll: true }),
      );
    });

    it("clears a tag by unchecking it", async () => {
      const user = userEvent.setup();
      renderShow({ tags: [vip] });

      await openEditor(user);
      await user.click(screen.getByRole("checkbox", { name: "VIP" }));
      await user.click(screen.getByRole("button", { name: "Save" }));

      expect(router.patch).toHaveBeenCalledWith(
        "/sales/1/tags",
        { sale: { tagging: { submitted: "1", ids: [], original_ids: [2] } }, return_to: "/" },
        expect.anything(),
      );
    });

    it("edits in a dialog that lists every tag with the saved ones checked, while the badges stay on the page", async () => {
      const user = userEvent.setup();
      const { container } = renderShow({ tags: [vip] });
      expect(screen.queryByRole("dialog")).not.toBeInTheDocument();

      const dialog = await openEditor(user);

      expect(dialog).toHaveAccessibleName("Edit tags");
      expect(within(dialog).getByRole("checkbox", { name: "VIP" })).toBeChecked();
      expect(within(dialog).getByRole("checkbox", { name: "Rush" })).not.toBeChecked();
      expect(within(dialog).getByRole("checkbox", { name: "Wholesale" })).not.toBeChecked();
      expect(within(dialog).getByRole("button", { name: "Save" })).toBeInTheDocument();
      expect(container.querySelector("header")?.nextElementSibling).not.toContainElement(dialog);
      expect(screen.getByRole("button", { name: "Edit tags" })).toBeInTheDocument();
    });

    it("gives each palette color its own line, alphabetical within it", async () => {
      const user = userEvent.setup();
      const apple: SalesTagRecord = { id: 11, name: "apple", color: "green" };
      const zed: SalesTagRecord = { id: 12, name: "Zed", color: "green" };
      const alpha: SalesTagRecord = { id: 13, name: "Alpha", color: "sky" };
      renderShow({ tags: [] }, { tag_options: [vip, zed, rush, alpha, apple] });

      const dialog = await openEditor(user, "Add tags");

      const lines = within(dialog)
        .getAllByRole("list")
        .map((line) =>
          within(line)
            .getAllByRole("checkbox")
            .map((box) => box.closest("label")?.textContent),
        );
      expect(lines).toEqual([["apple", "Zed"], ["Rush"], ["Alpha", "VIP"]]);
    });

    it("filters the list by part of a name, ignoring case", async () => {
      const user = userEvent.setup();
      renderShow({ tags: [] });

      await openEditor(user, "Add tags");
      await user.type(screen.getByRole("searchbox", { name: "Filter tags" }), "RU");

      expect(screen.getByRole("checkbox", { name: "Rush" })).toBeInTheDocument();
      expect(screen.queryByRole("checkbox", { name: "VIP" })).not.toBeInTheDocument();
      expect(screen.queryByRole("checkbox", { name: "Wholesale" })).not.toBeInTheDocument();
    });

    it("keeps a selection made before the filter hid it", async () => {
      const user = userEvent.setup();
      renderShow({ tags: [vip] });

      await openEditor(user);
      await user.click(screen.getByRole("checkbox", { name: "Rush" }));
      await user.type(screen.getByRole("searchbox", { name: "Filter tags" }), "whole");
      expect(screen.queryByRole("checkbox", { name: "Rush" })).not.toBeInTheDocument();
      await user.clear(screen.getByRole("searchbox", { name: "Filter tags" }));
      await user.click(screen.getByRole("button", { name: "Save" }));

      expect(router.patch).toHaveBeenCalledWith(
        "/sales/1/tags",
        { sale: { tagging: { submitted: "1", ids: [2, 4], original_ids: [2] } }, return_to: "/" },
        expect.anything(),
      );
    });

    it("says when nothing matches, and Enter in the filter does not save", async () => {
      const user = userEvent.setup();
      renderShow({ tags: [vip] });

      await openEditor(user);
      await user.type(screen.getByRole("searchbox", { name: "Filter tags" }), "zzz{Enter}");

      expect(screen.getByText("No tags match “zzz”.")).toBeInTheDocument();
      expect(router.patch).not.toHaveBeenCalled();
    });

    it("closes the dialog once the save is confirmed", async () => {
      const user = userEvent.setup();
      renderShow({ tags: [] });

      const dialog = await openEditor(user, "Add tags");
      expect(dialog).toHaveAccessibleName("Add tags");
      await user.click(screen.getByRole("checkbox", { name: "VIP" }));
      await user.click(screen.getByRole("button", { name: "Save" }));

      expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Add tags" })).toBeInTheDocument();
    });

    it("discards the draft on Cancel without sending anything", async () => {
      const user = userEvent.setup();
      renderShow({ tags: [vip] });

      await openEditor(user);
      await user.click(screen.getByRole("checkbox", { name: "Rush" }));
      await user.click(screen.getByRole("button", { name: "Cancel" }));

      expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
      expect(router.patch).not.toHaveBeenCalled();

      await openEditor(user);
      expect(screen.getByRole("checkbox", { name: "Rush" })).not.toBeChecked();
    });

    it("keeps the draft and offers an explicit reload of the show props after a stale save", async () => {
      const user = userEvent.setup();
      const message = "Tags changed since you opened this editor. Reload tags and try again.";
      nextFormErrors.mockReturnValueOnce({ tags: message });
      renderShow({ tags: [vip] });

      await openEditor(user);
      await user.click(screen.getByRole("checkbox", { name: "Rush" }));
      await user.click(screen.getByRole("button", { name: "Save" }));

      expect(screen.getByText(message)).toBeInTheDocument();
      expect(screen.getByRole("checkbox", { name: "Rush" })).toBeChecked();
      expect(router.reload).not.toHaveBeenCalled();

      await user.click(screen.getByRole("button", { name: "Reload tags (discards your changes)" }));

      expect(router.reload).toHaveBeenCalledWith(expect.objectContaining({ only: reloadedProps }));
    });
  });
});

type ShowTagProps = { tag_options?: SalesTagRecord[]; can_tag_sales?: boolean };

function renderShow(
  overrides: Partial<SaleShowRecord> = {},
  { tag_options = [rush, vip, wholesale], can_tag_sales = true }: ShowTagProps = {},
) {
  return render(
    <Show
      can_tag_sales={can_tag_sales}
      sale={makeSaleShow(overrides)}
      tag_colors={[...tagColors]}
      tag_options={tag_options}
    />,
  );
}

async function openEditor(user: UserEvent, name = "Edit tags") {
  await user.click(screen.getByRole("button", { name }));
  return screen.findByRole("dialog");
}
