import { act, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import New from "./New";
import { makeProductForm, makePurchaseForm } from "./test/factories";
import type { FormOptions } from "./types";

vi.mock("./components/Form/TiptapEditor", () => ({ default: () => null }));
vi.mock("@/components/ImageUploader", () => ({ default: () => null }));
vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

const options: FormOptions = {
  franchises: [],
  brands: [],
  shapes: [],
  sizes: [],
  versions: [],
  colors: [],
  suppliers: [],
  warehouses: [],
  store_names: [],
};

describe("Products/New", () => {
  it("renders the new heading and create button", async () => {
    await act(async () => {
      render(<New options={options} product={makeProductForm()} purchase={makePurchaseForm()} />);
    });

    expect(screen.getByRole("heading", { name: "New Product" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Product" })).toBeInTheDocument();
  });
});
