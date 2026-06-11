import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { usePage } from "@inertiajs/react";
import { mockPageProps } from "@/test/mocks/inertia";
import Form from "./Form";
import { makeCustomer } from "../test/factories";
import type { CustomerRecord } from "../types";

type ResourceFormProps = {
  action: string;
  cancelHref: string;
  children: ReactNode | ((props: { errors: Record<string, string> }) => ReactNode);
  method: string;
  submitLabel: string;
};

let resourceFormProps: Omit<ResourceFormProps, "children"> | null = null;

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

vi.mock("@/components/ResourceForm", () => ({
  default: function ResourceFormStub({
    action,
    cancelHref,
    children,
    method,
    submitLabel,
  }: ResourceFormProps) {
    const errors = (usePage().props.errors ?? {}) as Record<string, string>;
    resourceFormProps = { action, cancelHref, method, submitLabel };

    return (
      <form data-testid="resource-form">
        {typeof children === "function" ? children({ errors }) : children}
        <button type="submit">{submitLabel}</button>
      </form>
    );
  },
}));

describe("Customers/components/Form", () => {
  beforeEach(() => {
    resourceFormProps = null;
  });

  describe("form shell", () => {
    it("configures action, method, and labels for a new customer", () => {
      renderForm({
        customer: makeCustomer({
          id: null,
          first_name: "",
          last_name: "",
          full_name: "",
          email: "",
          phone: "",
          woo_store_id: "",
          created_at: null,
          updated_at: null,
          path: "/customers/new",
        }),
        method: "post",
        submitLabel: "Create Customer",
        url: "/customers",
      });

      expect(resourceFormProps).toEqual({
        action: "/customers",
        cancelHref: "/customers",
        method: "post",
        submitLabel: "Create Customer",
      });
    });

    it("configures action, method, and labels for an existing customer", () => {
      renderForm();

      expect(resourceFormProps).toEqual({
        action: "/customers/1",
        cancelHref: "/customers",
        method: "patch",
        submitLabel: "Update Customer",
      });
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
