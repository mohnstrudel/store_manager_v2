import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";
import Form from "./Form";
import { makeShippingCompany } from "../test/factories";
import type { ShippingCompanyRecord } from "../types";

vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

describe("ShippingCompanies/components/Form", () => {
  describe("form shell", () => {
    it("configures action, method, and labels for a new shipping company", () => {
      renderForm({
        shippingCompany: makeShippingCompany({
          id: null,
          name: "",
          tracking_url: null,
          created_at: null,
          updated_at: null,
        }),
        method: "post",
        submitLabel: "Create Shipping Company",
        url: "/shipping_companies",
      });

      expect(lastCapturedProps()).toEqual({
        action: "/shipping_companies",
        cancelHref: "/shipping_companies",
        method: "post",
        submitLabel: "Create Shipping Company",
        validate: expect.any(Function),
      });
    });

    it("configures action, method, and labels for an existing shipping company", () => {
      renderForm();

      expect(lastCapturedProps()).toEqual({
        action: "/shipping_companies/1",
        cancelHref: "/shipping_companies",
        method: "patch",
        submitLabel: "Update Shipping Company",
        validate: expect.any(Function),
      });
    });
  });

  describe("field rendering", () => {
    it("renders the name and tracking URL fields with current values", () => {
      renderForm();

      expect(screen.getByLabelText("Name")).toHaveValue("DHL");
      expect(screen.getByLabelText("Tracking URL")).toHaveValue("https://dhl.com/track");
      expect(screen.getByRole("button", { name: "Update Shipping Company" })).toBeInTheDocument();
    });

    it("shows validation errors on the tracking URL field", () => {
      renderForm({ pageErrors: { tracking_url: "can't be blank" } });

      expect(screen.getByText("can't be blank")).toBeInTheDocument();
      expect(screen.getByLabelText("Tracking URL")).toHaveAttribute("aria-invalid", "true");
    });
  });

  describe("validation", () => {
    it("rejects a blank tracking URL", () => {
      renderForm();
      const formData = new FormData();
      formData.set("shipping_company[tracking_url]", "   ");

      expect(lastCapturedProps()?.validate?.(formData)).toEqual({
        tracking_url: "can't be blank",
      });
    });

    it("accepts a non-blank tracking URL", () => {
      renderForm();
      const formData = new FormData();
      formData.set("shipping_company[tracking_url]", "  https://dhl.com/track  ");

      expect(lastCapturedProps()?.validate?.(formData)).toBeNull();
    });
  });
});

function renderForm({
  pageErrors = {},
  shippingCompany = makeShippingCompany(),
  method = "patch",
  submitLabel = "Update Shipping Company",
  url = "/shipping_companies/1",
}: {
  pageErrors?: Record<string, string>;
  shippingCompany?: ShippingCompanyRecord;
  method?: "post" | "patch";
  submitLabel?: string;
  url?: string;
} = {}) {
  mockPageProps({ errors: pageErrors });

  return render(
    <Form method={method} shippingCompany={shippingCompany} submitLabel={submitLabel} url={url} />,
  );
}
