import type { WarehousePurchaseItemRecord } from "../types";

export function InlineEditorActions({ onCancel }: { onCancel: () => void }) {
  return (
    <div className="flex gap-1 justify-center">
      <button className="btn_rounded btn_xs btn_green" type="submit">
        Save
      </button>
      <button className="btn_red btn_xs btn_rounded" onClick={onCancel} type="button">
        Exit
      </button>
    </div>
  );
}

export function stopInlineEditorNavigation(event: { stopPropagation(): void }) {
  event.stopPropagation();
}

export function updatePurchaseItem(
  purchaseItems: WarehousePurchaseItemRecord[],
  itemId: number,
  updates: Partial<WarehousePurchaseItemRecord>,
) {
  return purchaseItems.map((purchaseItem) =>
    purchaseItem.id === itemId ? { ...purchaseItem, ...updates } : purchaseItem,
  );
}
