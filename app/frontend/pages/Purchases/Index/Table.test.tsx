import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { makePurchaseIndexRecord } from "../test/factories";
import type { PurchaseIndexRecord } from "../types";
import IndexTable from "./Table";

describe("Purchases/Index/Table", () => {
  it("calls onTogglePurchase with the purchase id when a checkbox is changed", async () => {
    const user = userEvent.setup();
    const onTogglePurchase = vi.fn<(id: number) => void>();
    renderTable({ onTogglePurchase });

    await user.click(screen.getByRole("checkbox"));

    expect(onTogglePurchase).toHaveBeenCalledWith(1);
  });

  it("does not call onTogglePurchase when data-purchase-id is not a valid number", async () => {
    const user = userEvent.setup();
    const onTogglePurchase = vi.fn<(id: number) => void>();
    renderTable({
      onTogglePurchase,
      purchases: [makePurchaseIndexRecord({ id: NaN })],
    });

    await user.click(screen.getByRole("checkbox"));

    expect(onTogglePurchase).not.toHaveBeenCalled();
  });
});

function renderTable({
  onTogglePurchase = vi.fn<(id: number) => void>(),
  purchases = [makePurchaseIndexRecord()],
  selectedIds = [],
}: {
  onTogglePurchase?: (id: number) => void;
  purchases?: PurchaseIndexRecord[];
  selectedIds?: number[];
} = {}) {
  return render(
    <IndexTable
      onTogglePurchase={onTogglePurchase}
      purchases={purchases}
      selectedIds={selectedIds}
    />,
  );
}
