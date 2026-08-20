import { act, fireEvent, render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

// oxlint-disable-next-line import/no-unassigned-import
import "@/components/SmartSelect";
import type { VariantAvailability } from "@/types/variantAssignment";

import VariantAssignmentSelect from "./VariantAssignmentSelect";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

const baseAvailability: VariantAvailability = {
  mode: "base",
  variants: [{ value: 11, label: "Base Model", base_model: true }],
};
const selectAvailability: VariantAvailability = {
  mode: "select",
  variants: [
    { value: 21, label: "Large", base_model: false },
    { value: 22, label: "Small", base_model: false },
  ],
};

describe("VariantAssignmentSelect", () => {
  beforeEach(() => {
    vi.stubGlobal("fetch", vi.fn());
  });

  it("submits the fixed Base Variant in base mode", () => {
    renderSelect({
      initialAvailability: baseAvailability,
      initialProductId: 1,
      productId: 1,
    });

    expect(screen.getByText("Base Model")).toBeInTheDocument();
    expect(screen.queryByRole("combobox", { name: "Variant" })).not.toBeInTheDocument();
    expect(document.querySelector('input[name="purchase[variant_id]"]')).toHaveValue("11");
  });

  it("requires an explicit real Variant without selecting the first option", async () => {
    const onChange = vi.fn<(variantId: number | null) => void>();

    renderSelect({
      initialAvailability: selectAvailability,
      initialProductId: 1,
      onChange,
      productId: 1,
    });
    await flushLazySelect();

    expect(screen.getByRole("combobox", { name: "Variant" })).toHaveValue("");
    expect(document.querySelector('input[name="purchase[variant_id]"]')).toHaveValue("");
    expect(onChange).not.toHaveBeenCalledWith(21);
  });

  it("submits the explicitly selected real Variant", async () => {
    const onChange = vi.fn<(variantId: number | null) => void>();

    renderSelect({
      initialAvailability: selectAvailability,
      initialProductId: 1,
      onChange,
      productId: 1,
    });
    await flushLazySelect();

    fireEvent.change(screen.getByRole("combobox", { name: "Variant" }), {
      target: { value: "22" },
    });

    expect(onChange).toHaveBeenCalledWith(22);
  });

  it("ignores a stale response after the Product changes", async () => {
    const firstResponse = deferredResponse();
    const secondResponse = deferredResponse();
    vi.mocked(fetch)
      .mockReturnValueOnce(firstResponse.promise)
      .mockReturnValueOnce(secondResponse.promise);
    const { rerender } = renderSelect({ productId: 1 });

    rerender(selectElement({ productId: 2 }));
    await resolveResponse(secondResponse, {
      mode: "select",
      variants: [{ value: 202, label: "Second Product", base_model: false }],
    });
    await resolveResponse(firstResponse, {
      mode: "select",
      variants: [{ value: 101, label: "Stale Product", base_model: false }],
    });
    await flushLazySelect();

    expect(screen.getByRole("option", { name: "Second Product" })).toBeInTheDocument();
    expect(screen.queryByRole("option", { name: "Stale Product" })).not.toBeInTheDocument();
  });

  it("shows a row-specific backend error", async () => {
    renderSelect({
      error: "must be selected",
      initialAvailability: selectAvailability,
      initialProductId: 1,
      productId: 1,
    });
    await flushLazySelect();

    expect(screen.getByText("must be selected")).toBeInTheDocument();
    expect(screen.getByLabelText("Variant").parentElement).toHaveClass("field_with_errors");
  });
});

function renderSelect(
  overrides: Partial<React.ComponentProps<typeof VariantAssignmentSelect>> = {},
) {
  const props = {
    initialAvailability: null,
    initialProductId: null,
    inputId: "purchase_variant_id",
    name: "purchase[variant_id]",
    onChange: vi.fn<(variantId: number | null) => void>(),
    productId: null,
    value: null,
    ...overrides,
  };

  return render(<VariantAssignmentSelect {...props} />);
}

function selectElement(
  overrides: Partial<React.ComponentProps<typeof VariantAssignmentSelect>> = {},
) {
  return (
    <VariantAssignmentSelect
      initialAvailability={null}
      initialProductId={null}
      inputId="purchase_variant_id"
      name="purchase[variant_id]"
      onChange={vi.fn<(variantId: number | null) => void>()}
      productId={null}
      value={null}
      {...overrides}
    />
  );
}

function deferredResponse() {
  let resolve!: (response: Response) => void;
  const promise = new Promise<Response>((accept) => {
    resolve = accept;
  });
  return { promise, resolve };
}

async function resolveResponse(
  deferred: ReturnType<typeof deferredResponse>,
  body: VariantAvailability,
) {
  await act(async () => {
    deferred.resolve({
      json: async () => body,
      ok: true,
      status: 200,
    } as Response);
    await deferred.promise;
  });
}

async function flushLazySelect() {
  await act(async () => {});
}
