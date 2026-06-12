import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";
import Form from "./Form";
import { makeBrand } from "../test/factories";
import type { BrandRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));
vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

describe("Brands/components/Form", () => {

  describe("form shell", () => {
    it("configures action, method, and labels for a new brand", () => {
      renderForm({
        brand: makeBrand({ id: null, title: "", created_at: null, updated_at: null }),
        method: "post",
        submitLabel: "Create Brand",
        url: "/brands",
      });

      expect(lastCapturedProps()).toEqual({
        action: "/brands",
        cancelHref: "/brands",
        method: "post",
        submitLabel: "Create Brand",
        validate: expect.any(Function),
      });
    });

    it("configures action, method, and labels for an existing brand", () => {
      renderForm();

      expect(lastCapturedProps()).toEqual({
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
      const validate = lastCapturedProps()?.validate;
      const formData = new FormData();
      formData.set("brand[title]", "   ");

      expect(validate?.(formData)).toEqual({ title: "can't be blank" });
    });

    it("accepts values with non-whitespace characters", () => {
      renderForm();
      const validate = lastCapturedProps()?.validate;
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
