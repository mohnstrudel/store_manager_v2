import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";

import { makeSize } from "../test/factories";
import type { SizeRecord } from "../types";
import Form from "./Form";

vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

describe("Sizes/components/Form", () => {
  describe("form shell", () => {
    it("configures action, method, and labels for a new size", () => {
      renderForm({
        method: "post",
        size: makeSize({ id: null, value: "", created_at: null, updated_at: null }),
        submitLabel: "Create Size",
        url: "/sizes",
      });

      expect(lastCapturedProps()).toEqual({
        action: "/sizes",
        cancelHref: "/sizes",
        method: "post",
        submitLabel: "Create Size",
        validate: expect.any(Function),
      });
    });

    it("configures action, method, and labels for an existing size", () => {
      renderForm();

      expect(lastCapturedProps()).toEqual({
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
      const validate = lastCapturedProps()?.validate;
      const formData = new FormData();
      formData.set("size[value]", "   ");

      expect(validate?.(formData)).toEqual({ value: "can't be blank" });
    });

    it("accepts values with non-whitespace characters", () => {
      renderForm();
      const validate = lastCapturedProps()?.validate;
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
