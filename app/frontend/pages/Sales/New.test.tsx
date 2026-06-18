import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import New from "./New";
import { makeSaleForm, makeSaleFormOptions } from "./test/factories";

vi.mock("./components/Form", () => ({
  default: () => <div data-testid="sale-form" />,
}));

describe("Sales/New", () => {
  it("renders the form without an error notice when there are no errors", () => {
        render(<New options={makeSaleFormOptions({ customers: [], products: [] })} sale={makeSaleForm()}/>);

    expect(screen.queryByText("Fix errors and try again")).not.toBeInTheDocument();
    expect(screen.getByTestId("sale-form")).toBeInTheDocument();
  });

  it("shows the error notice with field errors when validation fails", () => {
    mockPageProps({ errors: { customer: "can't be blank", status: "is invalid" } });

        render(<New options={makeSaleFormOptions({ customers: [], products: [] })} sale={makeSaleForm()}/>);

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getByText("can't be blank")).toBeInTheDocument();
    expect(screen.getByText("is invalid")).toBeInTheDocument();
  });
});


