import { router } from "@inertiajs/react";
import { useCallback, type FormEvent, useMemo, useState } from "react";

import SmartSelect from "@/components/SmartSelect";
import type { WarehouseOption } from "@/types/warehouse";

type WarehouseSelectOption = { value: number; label: string };

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
  const [destination, setDestination] = useState<WarehouseSelectOption | null>(null);
  const visible = selectedIds.length > 0;

  const warehouseOptions = useMemo(
    () => warehouses.map((warehouse) => ({ value: warehouse.id, label: warehouse.name })),
    [warehouses],
  );

  const handleDestinationChange = useCallback((option: WarehouseSelectOption | null) => {
    setDestination(option);
  }, []);

  const handleSubmit = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      if (!destination) return;

      router.post(
        movePath,
        {
          destination_id: String(destination.value),
          purchase_id: purchaseId,
          redirect_to_sale_item: redirectToSaleItem || undefined,
          sale_id: saleId,
          selected_items_ids: selectedIds,
        },
        { onSuccess: onMoved },
      );
    },
    [destination, movePath, onMoved, purchaseId, redirectToSaleItem, saleId, selectedIds],
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
        <label className="sr-only" htmlFor="warehouse-destination">
          Destination warehouse
        </label>
        <SmartSelect
          className="flex-1"
          inputId="warehouse-destination"
          menuPlacement="top"
          onChange={handleDestinationChange}
          options={warehouseOptions}
          placeholder="Select a warehouse"
          value={destination}
        />
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
