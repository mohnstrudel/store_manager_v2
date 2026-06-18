import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { usePage } from "@inertiajs/react";
import { mockPageProps } from "@/test/mocks/inertia";
import Form from "./Form";
import { makeUserForm } from "../test/factories";
import type { UserFormValues } from "./Form";

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

describe("Users/components/Form", () => {
  beforeEach(() => {
    resourceFormProps = null;
  });

  describe("form shell", () => {
    it("configures action, method, and labels", () => {
      renderForm();

      expect(resourceFormProps).toEqual({
        action: "/users/1",
        cancelHref: "/users/1",
        method: "patch",
        submitLabel: "Update User",
        validate: expect.any(Function),
      });
    });
  });

  describe("field rendering", () => {
    it("renders the editable fields", () => {
      renderForm();

      expect(screen.getByLabelText("Email")).toHaveValue("ash@example.com");
      expect(screen.getByLabelText("First Name")).toHaveValue("Ash");
      expect(screen.getByLabelText("Last Name")).toHaveValue("Ketchum");
      expect(screen.getByRole("combobox", { name: "Role" })).toBeInTheDocument();
    });

    it("hides the role field when editing a restricted user", () => {
      renderForm({ canEditRole: false });

      expect(screen.queryByRole("combobox", { name: "Role" })).not.toBeInTheDocument();
    });

    it("shows validation errors on the email field", () => {
      renderForm({ pageErrors: { email_address: "can't be blank" } });

      expect(screen.getByText("can't be blank")).toBeInTheDocument();
      expect(screen.getByLabelText("Email")).toHaveAttribute("aria-invalid", "true");
    });
  });

  describe("validation", () => {
    it("rejects blank email values", () => {
      renderForm();
      const validate = resourceFormProps?.validate;
      const formData = new FormData();
      formData.set("user[email_address]", "");

      expect(validate?.(formData)).toEqual({ email_address: "can't be blank" });
    });

    it("accepts a valid email value", () => {
      renderForm();
      const validate = resourceFormProps?.validate;
      const formData = new FormData();
      formData.set("user[email_address]", "ash@example.com");

      expect(validate?.(formData)).toBeNull();
    });
  });
});

function renderForm({
  canEditRole = true,
  pageErrors = {},
  roleOptions = [["Manager", "manager"]],
  user = makeUserForm(),
}: {
  canEditRole?: boolean;
  pageErrors?: Record<string, string>;
  roleOptions?: [string, string][];
  user?: UserFormValues;
} = {}) {
  mockPageProps({ errors: pageErrors });

  return render(<Form canEditRole={canEditRole} roleOptions={roleOptions} user={user} />);
}
