import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { usePage } from "@inertiajs/react";
import { mockPageProps } from "@/test/mocks/inertia";
import Form from "./Form";
import { makeColor } from "../test/factories";
import type { ColorRecord } from "../types";

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

describe("Colors/components/Form", () => {
  beforeEach(() => {
    resourceFormProps = null;
  });

  describe("form shell", () => {
    it("configures action, method, and labels for a new color", () => {
      renderForm({
        color: makeColor({ id: null, value: "", created_at: null, updated_at: null }),
        method: "post",
        submitLabel: "Create Color",
        url: "/colors",
      });

      expect(resourceFormProps).toEqual({
        action: "/colors",
        cancelHref: "/colors",
        method: "post",
        submitLabel: "Create Color",
        validate: expect.any(Function),
      });
    });

    it("configures action, method, and labels for an existing color", () => {
      renderForm();

      expect(resourceFormProps).toEqual({
        action: "/colors/1",
        cancelHref: "/colors",
        method: "patch",
        submitLabel: "Update Color",
        validate: expect.any(Function),
      });
    });
  });

  describe("field rendering", () => {
    it("renders the value field with the current color value", () => {
      renderForm();

      expect(screen.getByLabelText("Value")).toHaveValue("Azure");
      expect(screen.getByRole("button", { name: "Update Color" })).toBeInTheDocument();
    });

    it("shows validation errors on the value field", () => {
      renderForm({ pageErrors: { value: "can't be blank" } });

      expect(screen.getByText("can't be blank")).toBeInTheDocument();
      expect(screen.getByLabelText("Value")).toHaveAttribute("aria-invalid", "true");
    });
  });

  describe("validation", () => {
    it("rejects blank values", () => {
      renderForm();
      const validate = resourceFormProps?.validate;
      const formData = new FormData();
      formData.set("color[value]", "   ");

      expect(validate?.(formData)).toEqual({ value: "can't be blank" });
    });

    it("accepts values with non-whitespace characters", () => {
      renderForm();
      const validate = resourceFormProps?.validate;
      const formData = new FormData();
      formData.set("color[value]", "  Azure  ");

      expect(validate?.(formData)).toBeNull();
    });
  });
});

function renderForm({
  color = makeColor(),
  method = "patch",
  pageErrors = {},
  submitLabel = "Update Color",
  url = "/colors/1",
}: {
  color?: ColorRecord;
  method?: "post" | "patch";
  pageErrors?: Record<string, string>;
  submitLabel?: string;
  url?: string;
} = {}) {
  mockPageProps({ errors: pageErrors });

  return render(<Form color={color} method={method} submitLabel={submitLabel} url={url} />);
}
