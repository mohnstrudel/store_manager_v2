import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { usePage } from "@inertiajs/react";
import { mockPageProps } from "@/test/mocks/inertia";
import Form from "./Form";
import { makeSize } from "../test/factories";
import type { SizeRecord } from "../types";

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

describe("Sizes/components/Form", () => {
  beforeEach(() => {
    resourceFormProps = null;
  });

  describe("form shell", () => {
    it("configures action, method, and labels for a new size", () => {
      renderForm({
        method: "post",
        size: makeSize({ id: null, value: "", created_at: null, updated_at: null }),
        submitLabel: "Create Size",
        url: "/sizes",
      });

      expect(resourceFormProps).toEqual({
        action: "/sizes",
        cancelHref: "/sizes",
        method: "post",
        submitLabel: "Create Size",
        validate: expect.any(Function),
      });
    });

    it("configures action, method, and labels for an existing size", () => {
      renderForm();

      expect(resourceFormProps).toEqual({
        action: "/sizes/1",
        cancelHref: "/sizes",
        method: "patch",
        submitLabel: "Update Size",
        validate: expect.any(Function),
      });
    });
  });

  describe("field rendering", () => {
    it("renders the value field with the current size value", () => {
      renderForm();

      expect(screen.getByLabelText("Value")).toHaveValue("1:6");
      expect(screen.getByRole("button", { name: "Update Size" })).toBeInTheDocument();
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
      formData.set("size[value]", "   ");

      expect(validate?.(formData)).toEqual({ value: "can't be blank" });
    });

    it("accepts values with non-whitespace characters", () => {
      renderForm();
      const validate = resourceFormProps?.validate;
      const formData = new FormData();
      formData.set("size[value]", "  1:4  ");

      expect(validate?.(formData)).toBeNull();
    });
  });
});

function renderForm({
  method = "patch",
  pageErrors = {},
  size = makeSize(),
  submitLabel = "Update Size",
  url = "/sizes/1",
}: {
  method?: "post" | "patch";
  pageErrors?: Record<string, string>;
  size?: SizeRecord;
  submitLabel?: string;
  url?: string;
} = {}) {
  mockPageProps({ errors: pageErrors });

  return render(<Form method={method} size={size} submitLabel={submitLabel} url={url} />);
}
