import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";
import Form from "./Form";
import { makeExpenseRate } from "../test/factories";
import type { ExpenseRateRecord } from "../types";

vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

describe("ExpenseRates/components/Form", () => {
  describe("form shell", () => {
    it("configures action, method, and labels for a new expense rate", () => {
      renderForm({
        expenseRate: makeExpenseRate({ id: null, name: "", rate_percent: 0 }),
        method: "post",
        submitLabel: "Create OpEx Rate",
        url: "/expense_rates",
      });

      expect(lastCapturedProps()).toEqual({
        action: "/expense_rates",
        cancelHref: "/expense_rates",
        method: "post",
        submitLabel: "Create OpEx Rate",
        validate: expect.any(Function),
      });
    });

    it("configures action, method, and labels for an existing expense rate", () => {
      renderForm();

      expect(lastCapturedProps()).toEqual({
        action: "/expense_rates/1",
        cancelHref: "/expense_rates",
        method: "patch",
        submitLabel: "Update OpEx Rate",
        validate: expect.any(Function),
      });
    });
  });

  describe("field rendering", () => {
    it("renders the fields with current values", () => {
      renderForm();

      expect(screen.getByLabelText("Name")).toHaveValue("Payroll");
      expect(screen.getByLabelText("OpEx rate (% of revenue)")).toHaveValue(15);
    });

    it("shows validation errors on the rate field", () => {
      renderForm({ pageErrors: { rate_percent: "can't be blank" } });

      expect(screen.getByText("can't be blank")).toBeInTheDocument();
      expect(screen.getByLabelText("OpEx rate (% of revenue)")).toHaveAttribute(
        "aria-invalid",
        "true",
      );
    });
  });

  describe("validation", () => {
    it("rejects a blank name and rate", () => {
      renderForm();
      const formData = new FormData();
      formData.set("expense_rate[name]", "   ");
      formData.set("expense_rate[rate_percent]", "");

      expect(lastCapturedProps()?.validate?.(formData)).toEqual({
        name: "can't be blank",
        rate_percent: "can't be blank",
      });
    });

    it("rejects a rate above 100", () => {
      renderForm();
      const formData = new FormData();
      formData.set("expense_rate[name]", "Payroll");
      formData.set("expense_rate[rate_percent]", "150");

      expect(lastCapturedProps()?.validate?.(formData)).toEqual({
        rate_percent: "must be between 0 and 100",
      });
    });

    it("accepts a valid name and rate", () => {
      renderForm();
      const formData = new FormData();
      formData.set("expense_rate[name]", "Payroll");
      formData.set("expense_rate[rate_percent]", "15");

      expect(lastCapturedProps()?.validate?.(formData)).toBeNull();
    });
  });
});

function renderForm({
  pageErrors = {},
  expenseRate = makeExpenseRate(),
  method = "patch",
  submitLabel = "Update OpEx Rate",
  url = "/expense_rates/1",
}: {
  pageErrors?: Record<string, string>;
  expenseRate?: ExpenseRateRecord;
  method?: "post" | "patch";
  submitLabel?: string;
  url?: string;
} = {}) {
  mockPageProps({ errors: pageErrors });

  return render(
    <Form expenseRate={expenseRate} method={method} submitLabel={submitLabel} url={url} />,
  );
}
