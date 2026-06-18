import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { usePage } from "@inertiajs/react";
import { mockPageProps } from "@/test/mocks/inertia";
import Form from "./Form";
import { makeVersion } from "../test/factories";
import type { VersionRecord } from "../types";

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

describe("Versions/components/Form", () => {
  beforeEach(() => {
    resourceFormProps = null;
  });

  describe("form shell", () => {
    it("configures action, method, and labels for a new version", () => {
      renderForm({
        method: "post",
        submitLabel: "Create Version",
        url: "/versions",
        version: makeVersion({
          id: null,
          value: "",
          created_at: null,
          updated_at: null,
        }),
      });

      expect(resourceFormProps).toEqual({
        action: "/versions",
        cancelHref: "/versions",
        method: "post",
        submitLabel: "Create Version",
        validate: expect.any(Function),
      });
    });

    it("configures action, method, and labels for an existing version", () => {
      renderForm();

      expect(resourceFormProps).toEqual({
        action: "/versions/1",
        cancelHref: "/versions",
        method: "patch",
        submitLabel: "Update Version",
        validate: expect.any(Function),
      });
    });
  });

  describe("field rendering", () => {
    it("renders the value field with the current version value", () => {
      renderForm();

      expect(screen.getByLabelText("Value")).toHaveValue("Classic");
      expect(screen.getByRole("button", { name: "Update Version" })).toBeInTheDocument();
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
      formData.set("version[value]", "   ");

      expect(validate?.(formData)).toEqual({ value: "can't be blank" });
    });

    it("accepts values with non-whitespace characters", () => {
      renderForm();
      const validate = resourceFormProps?.validate;
      const formData = new FormData();
      formData.set("version[value]", "  Classic  ");

      expect(validate?.(formData)).toBeNull();
    });
  });
});

function renderForm({
  method = "patch",
  pageErrors = {},
  submitLabel = "Update Version",
  url = "/versions/1",
  version = makeVersion(),
}: {
  method?: "post" | "patch";
  pageErrors?: Record<string, string>;
  submitLabel?: string;
  url?: string;
  version?: VersionRecord;
} = {}) {
  mockPageProps({ errors: pageErrors });

  return render(<Form method={method} submitLabel={submitLabel} url={url} version={version} />);
}
