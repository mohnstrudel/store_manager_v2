import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";
import ProductVariantSelect from "./Form/ProductVariantSelect";
import { type SelectOption } from "../types";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

const initialVariants: SelectOption<number>[] = [
  { value: 101, label: "First variant" },
  { value: 102, label: "Second variant" },
];

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("ProductVariantSelect", () => {
  it("loads variants for the selected product and selects the first loaded variant", async () => {
    const onChange = vi.fn<(variantId: number | null) => void>();
    const fetch = vi.fn<(input: RequestInfo | URL, init?: RequestInit) => Promise<Response>>(() =>
      Promise.resolve(jsonResponse({ variants: [{ value: 201, label: "Loaded variant" }] })),
    );
    vi.stubGlobal("fetch", fetch);

    render(
      <ProductVariantSelect
        initialVariants={[]}
        onChange={onChange}
        productId={20}
        productVariantsPath="/purchase_variants"
        value={null}
      />,
    );

    await waitFor(() => {
      expect(screen.getByRole("option", { name: "Loaded variant" })).toBeInTheDocument();
    });
    expect(onChange).toHaveBeenCalledWith(201);
    expect(fetch).toHaveBeenCalledWith(
      "/purchase_variants?product_id=20",
      expect.objectContaining({ headers: { Accept: "application/json" } }),
    );
  });

  it("notifies the parent when the user selects a different variant", async () => {
    const user = userEvent.setup();
    const onChange = vi.fn<(variantId: number | null) => void>();
    vi.stubGlobal(
      "fetch",
      vi.fn<() => Promise<never>>(() => new Promise(() => {})),
    );

    render(
      <ProductVariantSelect
        initialVariants={initialVariants}
        onChange={onChange}
        productId={10}
        productVariantsPath="/purchase_variants"
        value={101}
      />,
    );

    await user.selectOptions(screen.getByLabelText("Variant"), "102");

    expect(onChange).toHaveBeenCalledWith(102);
  });

  it("selects the first loaded variant but clears stale options when the product is removed", async () => {
    const onChange = vi.fn<(variantId: number | null) => void>();
    vi.stubGlobal(
      "fetch",
      vi.fn<() => Promise<never>>(() => new Promise(() => {})),
    );

    const { rerender } = render(
      <ProductVariantSelect
        initialVariants={initialVariants}
        onChange={onChange}
        productId={10}
        productVariantsPath="/purchase_variants"
        value={null}
      />,
    );

    await waitFor(() => {
      expect(onChange).toHaveBeenCalledWith(101);
    });

    rerender(
      <ProductVariantSelect
        initialVariants={initialVariants}
        onChange={onChange}
        productId={10}
        productVariantsPath="/purchase_variants"
        value={101}
      />,
    );

    const callsAfterSelection = onChange.mock.calls.length;

    rerender(
      <ProductVariantSelect
        initialVariants={initialVariants}
        onChange={onChange}
        productId={null}
        productVariantsPath="/purchase_variants"
        value={null}
      />,
    );

    await waitFor(() => {
      expect(screen.queryByRole("option", { name: "First variant" })).not.toBeInTheDocument();
    });

    expect(onChange.mock.calls.length).toBe(callsAfterSelection);
  });
});

function jsonResponse(body: unknown) {
  return new Response(JSON.stringify(body), {
    headers: { "Content-Type": "application/json" },
    status: 200,
  });
}
