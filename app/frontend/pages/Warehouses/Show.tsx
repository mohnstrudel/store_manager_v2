import { Link } from "@inertiajs/react";
import Button from "@/components/Button";
import { useConfirmAction } from "@/lib/useConfirmAction";
import { PurchaseItemsSection } from "./Show/PurchaseItemsSection";
import { WarehouseDetails } from "./Show/WarehouseDetails";
import type {
  PaginationMeta,
  ShippingCompanyOption,
  WarehouseOption,
  WarehousePurchaseItemRecord,
  WarehouseShowRecord,
} from "./types";

type ShowProps = {
  pagination: PaginationMeta;
  purchase_items: WarehousePurchaseItemRecord[];
  search: { q: string };
  selected_id: number | null;
  shipping_companies: ShippingCompanyOption[];
  total_purchase_items: number;
  warehouse: WarehouseShowRecord;
  warehouse_move_path: string;
  warehouses: WarehouseOption[];
};

export default function WarehouseShow(props: ShowProps) {
  const { warehouse } = props;
  const destroyWarehouse = useConfirmAction("delete", warehouse.destroy_path);

  return (
    <>
      <WarehouseHeader warehouse={warehouse} />

      <div className="section_wide flex flex-col gap-8">
        <PurchaseItemsSection {...props} />
        <WarehouseDetails warehouse={warehouse} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyWarehouse} variant="danger">
        Destroy this warehouse
      </Button>
    </>
  );
}

function WarehouseHeader({ warehouse }: { warehouse: WarehouseShowRecord }) {
  return (
    <header className="nav_header">
      <div className="flex gap-4">
        <h1 className="text-3xl lg:text-5xl">{warehouse.name}</h1>
      </div>
      <menu className="nav_menu">
        <li>
          <Link href={warehouse.new_item_path} prefetch>
            <i className="icn">📦</i>
            Add product
          </Link>
        </li>
        <li>
          <Link href={warehouse.edit_path} prefetch>
            <i className="icn">✏</i>
            Edit
          </Link>
        </li>
      </menu>
    </header>
  );
}
