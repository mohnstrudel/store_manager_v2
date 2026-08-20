import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";

import ResourceForm from "./ResourceForm";

describe("ResourceForm", () => {
  describe("form shell", () => {
    it("renders children via the render slot", () => {
      renderResourceForm({
        children: ({ errors }) => (
          <>
            <input name="title" aria-label="Title" />
            {errors.title && <span>{errors.title}</span>}
          </>
        ),
      });

      expect(screen.getByLabelText("Title")).toBeInTheDocument();
    });

    it("renders the submit button with the given label", () => {
      renderResourceForm({ submitLabel: "Save Product" });

      expect(screen.getByRole("button", { name: "Save Product" })).toBeInTheDocument();
    });

    it("renders the cancel link", () => {
      renderResourceForm({ cancelHref: "/products" });

      expect(screen.getByRole("link", { name: "Cancel" })).toHaveAttribute("href", "/products");
    });
  });

  describe("error display", () => {
    it("shows the ErrorNotice when the server returns errors", () => {
      mockPageProps({ errors: { title: "can't be blank" } });

      renderResourceForm({
        children: ({ errors }) => (
          <input name="title" aria-invalid={!!errors.title} aria-label="Title" />
        ),
      });

      expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    });

    it("passes server errors to the slot", () => {
      mockPageProps({ errors: { title: "can't be blank" } });

      renderResourceForm({
        children: ({ errors }) => <span data-testid="err">{errors.title}</span>,
      });

      expect(screen.getByTestId("err")).toHaveTextContent("can't be blank");
    });
  });

  describe("client validation", () => {
    it("shows the ErrorNotice and blocks submit when validate returns errors", async () => {
      const user = userEvent.setup();
      const validate = vi.fn<(data: FormData) => Record<string, string>>(() => ({
        quantity: "must be greater than 0",
      }));

      renderResourceForm({ validate });

      await user.click(screen.getByRole("button", { name: "Save" }));

      expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    });

    it("passes client errors to the slot", async () => {
      const user = userEvent.setup();
      const validate = vi.fn<(data: FormData) => Record<string, string>>(() => ({
        quantity: "must be greater than 0",
      }));

      renderResourceForm({
        validate,
        children: ({ errors }) => <span data-testid="err">{errors.quantity}</span>,
      });

      await user.click(screen.getByRole("button", { name: "Save" }));

      expect(screen.getByTestId("err")).toHaveTextContent("must be greater than 0");
    });

    it("clears client errors and allows submit when validation passes", async () => {
      const user = userEvent.setup();
      let shouldFail = true;
      const validate = vi.fn<(data: FormData) => Record<string, string> | null>(() =>
        shouldFail ? { quantity: "invalid" } : null,
      );

      renderResourceForm({
        validate,
        children: ({ errors }) => <span data-testid="err">{errors.quantity}</span>,
      });

      await user.click(screen.getByRole("button", { name: "Save" }));
      expect(screen.getByTestId("err")).toHaveTextContent("invalid");

      shouldFail = false;
      await user.click(screen.getByRole("button", { name: "Save" }));

      expect(screen.getByTestId("err")).toHaveTextContent("");
    });

    it("merges client and server errors in the slot", () => {
      mockPageProps({ errors: { title: "can't be blank" } });

      renderResourceForm({
        children: ({ errors }) => (
          <>
            <span data-testid="title-err">{errors.title}</span>
            <span data-testid="qty-err">{errors.quantity}</span>
          </>
        ),
      });

      expect(screen.getByTestId("title-err")).toHaveTextContent("can't be blank");
    });
  });
});

type RenderResourceFormOptions = {
  action?: string;
  cancelHref?: string;
  children?:
    | ((props: { errors: Record<string, string>; processing: boolean }) => React.ReactNode)
    | React.ReactNode;
  method?: "post" | "patch" | "put";
  submitLabel?: string;
  validate?: (data: FormData) => Record<string, string> | null;
};

function renderResourceForm({
  action = "/products",
  cancelHref = "/products",
  children = <input name="title" aria-label="Title" />,
  method = "post",
  submitLabel = "Save",
  validate,
}: RenderResourceFormOptions = {}) {
  return render(
    <ResourceForm
      action={action}
      cancelHref={cancelHref}
      method={method}
      submitLabel={submitLabel}
      validate={validate}
    >
      {children}
    </ResourceForm>,
  );
}
