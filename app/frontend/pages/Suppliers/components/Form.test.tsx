import { usePage } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";

import { makeSupplier } from "../test/factories";
import type { SupplierRecord } from "../types";
import Form from "./Form";

type ResourceFormProps = {
  action: string;
  cancelHref: string;
  children: ReactNode | ((props: { errors: Record<string, string> }) => ReactNode);
  method: string;
  submitLabel: string;
  validate?: (formData: FormData) => Record<string, string> | null;
};

let resourceFormProps: Omit<ResourceFormProps, "children"> | null = null;

vi.mock("@/components/ResourceForm", () => ({
  default: function ResourceFormStub({
    action,
    cancelHref,
    children,
    method,
    submitLabel,
    validate,
  }: ResourceFormProps) {
    const errors = (usePage().props.errors ?? {}) as Record<string, string>;
    resourceFormProps = { action, cancelHref, method, submitLabel, validate };

    return (
      <form data-testid="resource-form">
        {typeof children === "function" ? children({ errors }) : children}
        <button type="submit">{submitLabel}</button>
      </form>
    );
  },
}));

describe("Suppliers/components/Form", () => {
  beforeEach(() => {
    resourceFormProps = null;
  });

  describe("form shell", () => {
    it("configures action, method, and labels for a new supplier", () => {
      renderForm({
        supplier: makeSupplier({
          id: null,
          title: "",
          created_at: null,
          updated_at: null,
        }),
        method: "post",
        submitLabel: "Create Supplier",
        url: "/suppliers",
      });

      expect(resourceFormProps).toEqual({
        action: "/suppliers",
        cancelHref: "/suppliers",
        method: "post",
        submitLabel: "Create Supplier",
        validate: expect.any(Function),
      });
    });

    it("configures action, method, and labels for an existing supplier", () => {
      renderForm();

      expect(resourceFormProps).toEqual({
        action: "/suppliers/1",
        cancelHref: "/suppliers",
        method: "patch",
        submitLabel: "Update Supplier",
        validate: expect.any(Function),
      });
    });
  });

  describe("field rendering", () => {
    it("renders the title field with the current supplier title", () => {
      renderForm();

      expect(screen.getByLabelText("Title")).toHaveValue("GoodSmile");
      expect(screen.getByRole("button", { name: "Update Supplier" })).toBeInTheDocument();
    });

    it("shows validation errors on the title field", () => {
      renderForm({ pageErrors: { title: "can't be blank" } });

      expect(screen.getByText("can't be blank")).toBeInTheDocument();
      expect(screen.getByLabelText("Title")).toHaveAttribute("aria-invalid", "true");
    });
  });

  describe("validation", () => {
    it("rejects blank values", () => {
      renderForm();
      const validate = resourceFormProps?.validate;
      const formData = new FormData();
      formData.set("supplier[title]", "   ");

      expect(validate?.(formData)).toEqual({ title: "can't be blank" });
    });

    it("accepts values with non-whitespace characters", () => {
      renderForm();
      const validate = resourceFormProps?.validate;
      const formData = new FormData();
      formData.set("supplier[title]", "  GoodSmile  ");

      expect(validate?.(formData)).toBeNull();
    });
  });
});

function renderForm({
  pageErrors = {},
  supplier = makeSupplier(),
  method = "patch",
  submitLabel = "Update Supplier",
  url = "/suppliers/1",
}: {
  pageErrors?: Record<string, string>;
  supplier?: SupplierRecord;
  method?: "post" | "patch";
  submitLabel?: string;
  url?: string;
} = {}) {
  mockPageProps({ errors: pageErrors });

  return render(<Form method={method} submitLabel={submitLabel} supplier={supplier} url={url} />);
}
