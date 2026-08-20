import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";

import { makeExpenseRateOption, makeOperationalExpense } from "../test/factories";
import Form from "./Form";

vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

describe("OperationalExpenses/components/Form", () => {
  it("renders a signed amount, date, category, and an optional rate", () => {
    renderForm();

    expect(screen.getByLabelText("Date")).toHaveValue("2026-07-13");
    expect(screen.getByLabelText("Category")).toHaveValue("Packaging");
    expect(screen.getByLabelText("Amount")).toHaveValue(125.5);
    expect(screen.getByLabelText("OpEx rate (optional)")).toHaveValue("1");
  });

  it("prefills the category when a rate is selected, while leaving it editable", async () => {
    const user = userEvent.setup();
    renderForm({
      expenseRates: [makeExpenseRateOption(), makeExpenseRateOption({ id: 2, name: "Taxes" })],
    });

    await user.selectOptions(screen.getByLabelText("OpEx rate (optional)"), "2");
    await user.clear(screen.getByLabelText("Category"));
    await user.type(screen.getByLabelText("Category"), "Extra tax");

    expect(screen.getByLabelText("Category")).toHaveValue("Extra tax");
  });

  it("renders field errors", () => {
    mockPageProps({ errors: { amount: "must be a number" } });
    renderForm();

    expect(screen.getByText("must be a number")).toBeInTheDocument();
  });

  it("configures the update endpoint", () => {
    renderForm();

    expect(lastCapturedProps()).toMatchObject({
      action: "/operational_expenses/1",
      cancelHref: "/operational_expenses",
      method: "patch",
      submitLabel: "Update OpEx Entry",
    });
  });
});

function renderForm({
  expense = makeOperationalExpense(),
  expenseRates = [makeExpenseRateOption()],
}: {
  expense?: ReturnType<typeof makeOperationalExpense>;
  expenseRates?: ReturnType<typeof makeExpenseRateOption>[];
} = {}) {
  return render(
    <Form
      expense={expense}
      expenseRates={expenseRates}
      method="patch"
      submitLabel="Update OpEx Entry"
      url="/operational_expenses/1"
    />,
  );
}
