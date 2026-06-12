import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";
import Form from "./Form";
import { makeColor } from "../test/factories";
import type { ColorRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));
vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

describe("Colors/components/Form", () => {

  describe("form shell", () => {
    it("configures action, method, and labels for a new color", () => {
      renderForm({
        color: makeColor({ id: null, value: "", created_at: null, updated_at: null }),
        method: "post",
        submitLabel: "Create Color",
        url: "/colors",
      });

      expect(lastCapturedProps()).toEqual({
        action: "/colors",
        cancelHref: "/colors",
        method: "post",
        submitLabel: "Create Color",
        validate: expect.any(Function),
      });
    });

    it("configures action, method, and labels for an existing color", () => {
      renderForm();

      expect(lastCapturedProps()).toEqual({
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
      const validate = lastCapturedProps()?.validate;
      const formData = new FormData();
      formData.set("color[value]", "   ");

      expect(validate?.(formData)).toEqual({ value: "can't be blank" });
    });

    it("accepts values with non-whitespace characters", () => {
      renderForm();
      const validate = lastCapturedProps()?.validate;
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
