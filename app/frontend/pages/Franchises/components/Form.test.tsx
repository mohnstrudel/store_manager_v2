import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";
import Form from "./Form";
import { makeFranchise } from "../test/factories";
import type { FranchiseRecord } from "../types";

vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

describe("Franchises/components/Form", () => {
  describe("form shell", () => {
    it("configures action, method, and labels for a new franchise", () => {
      renderForm({
        franchise: makeFranchise({
          id: null,
          title: "",
          created_at: null,
          updated_at: null,
        }),
        method: "post",
        submitLabel: "Create Franchise",
        url: "/franchises",
      });

      expect(lastCapturedProps()).toEqual({
        action: "/franchises",
        cancelHref: "/franchises",
        method: "post",
        submitLabel: "Create Franchise",
        validate: expect.any(Function),
      });
    });

    it("configures action, method, and labels for an existing franchise", () => {
      renderForm();

      expect(lastCapturedProps()).toEqual({
        action: "/franchises/1",
        cancelHref: "/franchises",
        method: "patch",
        submitLabel: "Update Franchise",
        validate: expect.any(Function),
      });
    });
  });

  describe("field rendering", () => {
    it("renders the title field with the current franchise title", () => {
      renderForm();

      expect(screen.getByLabelText("Title")).toHaveValue("Pokemon");
      expect(screen.getByRole("button", { name: "Update Franchise" })).toBeInTheDocument();
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
      formData.set("franchise[title]", "   ");

      expect(validate?.(formData)).toEqual({ title: "can't be blank" });
    });

    it("accepts values with non-whitespace characters", () => {
      renderForm();
      const validate = lastCapturedProps()?.validate;
      const formData = new FormData();
      formData.set("franchise[title]", "  Pokemon  ");

      expect(validate?.(formData)).toBeNull();
    });
  });
});

function renderForm({
  franchise = makeFranchise(),
  method = "patch",
  pageErrors = {},
  submitLabel = "Update Franchise",
  url = "/franchises/1",
}: {
  franchise?: FranchiseRecord;
  method?: "post" | "patch";
  pageErrors?: Record<string, string>;
  submitLabel?: string;
  url?: string;
} = {}) {
  mockPageProps({ errors: pageErrors });

  return render(<Form franchise={franchise} method={method} submitLabel={submitLabel} url={url} />);
}
