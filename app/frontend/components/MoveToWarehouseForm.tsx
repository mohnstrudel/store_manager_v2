import { router } from "@inertiajs/react";
import { useCallback, type ChangeEvent, type FormEvent, useState } from "react";
import type { WarehouseOption } from "@/types/warehouse";

type MoveToWarehouseFormProps = {
  fixed?: boolean;
  movePath: string;
  onMoved?: () => void;
  purchaseId?: number;
  redirectToSaleItem?: boolean;
  saleId?: number;
  selectedIds: number[];
  warehouses: WarehouseOption[];
};

export default function MoveToWarehouseForm({
  fixed = true,
  movePath,
  onMoved,
  purchaseId,
  redirectToSaleItem = false,
  saleId,
  selectedIds,
  warehouses,
}: MoveToWarehouseFormProps) {
  const [destinationId, setDestinationId] = useState("");
  const visible = selectedIds.length > 0;

  const handleDestinationChange = useCallback((event: ChangeEvent<HTMLSelectElement>) => {
    setDestinationId(event.target.value);
  }, []);

  const handleSubmit = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      if (!destinationId) return;

      router.post(
        movePath,
        {
          destination_id: destinationId,
          purchase_id: purchaseId,
          redirect_to_sale_item: redirectToSaleItem || undefined,
          sale_id: saleId,
          selected_items_ids: selectedIds,
        },
        { onSuccess: onMoved },
      );
    },
    [destinationId, movePath, onMoved, purchaseId, redirectToSaleItem, saleId, selectedIds],
  );

  if (!visible) return null;

  return (
    <div
      className={
        fixed
          ? "move_to_warehouse__form fixed bottom-4 inset-x-2 mx-auto z-228 backdrop-blur-xl shadow-xl rounded-xl border border-gray-100 p-4 dark:border-gray-800 lg:bottom-8 lg:inset-x-0 lg:p-8 lg:w-4/5"
          : "mb-4"
      }
    >
      <form
        className="flex flex-col lg:flex-row items-stretch lg:items-center gap-4"
        onSubmit={handleSubmit}
      >
        <select className="select" onChange={handleDestinationChange} value={destinationId}>
          <option value="">Select a warehouse</option>
          {warehouses.map((warehouse) => (
            <option key={warehouse.id} value={warehouse.id}>
              {warehouse.name}
            </option>
          ))}
        </select>
        <button className="btn_rounded btn_blue h-11 w-full lg:w-auto" type="submit">
          <i className="icn">🚚</i>
          Move
          {selectedIds.length > 0 && (
            <span className="text-nowrap -ml-1">&nbsp;{selectedIds.length}</span>
          )}
        </button>
      </form>
    </div>
  );
}
