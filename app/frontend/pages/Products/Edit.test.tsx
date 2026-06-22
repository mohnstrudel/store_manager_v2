import { act, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Edit from "./Edit";
import { makeProductForm } from "./test/factories";
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

describe("Products/Edit", () => {
  it("renders the edit heading, view link, and update button", async () => {
    await act(async () => {
      render(<Edit options={options} product={makeProductForm({ id: 1, path: "/products/1" })} />);
    });

    expect(screen.getByRole("heading", { name: "Edit Product" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Product/ })).toHaveAttribute(
      "href",
      "/products/1",
    );
    expect(screen.getByRole("button", { name: "Update Product" })).toBeInTheDocument();
  });
});
