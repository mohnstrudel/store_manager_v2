import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { usePage } from "@inertiajs/react";
import { mockPageProps } from "@/test/mocks/inertia";
import Form from "./Form";
import { makeBrand } from "../test/factories";
import type { BrandRecord } from "../types";

type ResourceFormProps = {
  action: string;
  cancelHref: string;
  children: ReactNode | ((props: { errors: Record<string, string> }) => ReactNode);
  method: string;
  submitLabel: string;
  validate?: (formData: FormData) => Record<string, string> | null;
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

describe("Brands/components/Form", () => {
  beforeEach(() => {
    resourceFormProps = null;
  });

  describe("form shell", () => {
    it("configures action, method, and labels for a new brand", () => {
      renderForm({
        brand: makeBrand({ id: null, title: "", created_at: null, updated_at: null }),
        method: "post",
        submitLabel: "Create Brand",
        url: "/brands",
      });

      expect(resourceFormProps).toEqual({
        action: "/brands",
        cancelHref: "/brands",
        method: "post",
        submitLabel: "Create Brand",
        validate: expect.any(Function),
      });
    });

    it("configures action, method, and labels for an existing brand", () => {
      renderForm();

      expect(resourceFormProps).toEqual({
        action: "/brands/1",
        cancelHref: "/brands",
        method: "patch",
        submitLabel: "Update Brand",
        validate: expect.any(Function),
      });
    });
  });

  describe("field rendering", () => {
    it("renders the title field with the current brand title", () => {
      renderForm();

      expect(screen.getByLabelText("Title")).toHaveValue("Moonbow");
      expect(screen.getByRole("button", { name: "Update Brand" })).toBeInTheDocument();
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
      formData.set("brand[title]", "   ");

      expect(validate?.(formData)).toEqual({ title: "can't be blank" });
    });

    it("accepts values with non-whitespace characters", () => {
      renderForm();
      const validate = resourceFormProps?.validate;
      const formData = new FormData();
      formData.set("brand[title]", "  Moonbow  ");

      expect(validate?.(formData)).toBeNull();
    });
  });
});

function renderForm({
  brand = makeBrand(),
  method = "patch",
  pageErrors = {},
  submitLabel = "Update Brand",
  url = "/brands/1",
}: {
  brand?: BrandRecord;
  method?: "post" | "patch";
  pageErrors?: Record<string, string>;
  submitLabel?: string;
  url?: string;
} = {}) {
  mockPageProps({ errors: pageErrors });

  return render(<Form brand={brand} method={method} submitLabel={submitLabel} url={url} />);
}
