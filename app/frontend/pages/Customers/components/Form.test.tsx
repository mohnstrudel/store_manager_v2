import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";

import { makeCustomer, makeCustomerForm } from "../test/factories";
import type { CustomerRecord } from "../types";
import Form from "./Form";

vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

describe("Customers/components/Form", () => {
  describe("form shell", () => {
    it("configures action, method, and labels for a new customer", () => {
      renderForm({
        customer: makeCustomerForm(),
        method: "post",
        submitLabel: "Create Customer",
        url: "/customers",
      });

      expect(lastCapturedProps()).toEqual(
        expect.objectContaining({
          action: "/customers",
          cancelHref: "/customers",
          method: "post",
          submitLabel: "Create Customer",
        }),
      );
    });

    it("configures action, method, and labels for an existing customer", () => {
      renderForm();

      expect(lastCapturedProps()).toEqual(
        expect.objectContaining({
          action: "/customers/1",
          cancelHref: "/customers",
          method: "patch",
          submitLabel: "Update Customer",
        }),
      );
    });
  });

  describe("field rendering", () => {
    it("renders the customer fields with the current values", () => {
      renderForm();

      expect(screen.getByLabelText("First name")).toHaveValue("Dale");
      expect(screen.getByLabelText("Last name")).toHaveValue("Cooper");
      expect(screen.getByLabelText("Email")).toHaveValue("dale@fbi.gov");
      expect(screen.getByLabelText("Phone")).toHaveValue("+1555000");
    });

    it("shows validation errors on matching fields", () => {
      renderForm({ pageErrors: { first_name: "can't be blank" } });

      expect(screen.getByText("can't be blank")).toBeInTheDocument();
      expect(screen.getByLabelText("First name")).toHaveAttribute("aria-invalid", "true");
    });
  });
});

function renderForm({
  customer = makeCustomer(),
  method = "patch",
  pageErrors = {},
  submitLabel = "Update Customer",
  url = "/customers/1",
}: {
  customer?: CustomerRecord;
  method?: "post" | "patch";
  pageErrors?: Record<string, string>;
  submitLabel?: string;
  url?: string;
} = {}) {
  mockPageProps({ errors: pageErrors });

  return render(<Form customer={customer} method={method} submitLabel={submitLabel} url={url} />);
}
