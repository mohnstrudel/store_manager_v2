import { Link } from "@inertiajs/react";
import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import type { WarehouseFormOptions, WarehouseFormRecord } from "./types";

type EditProps = {
  options: WarehouseFormOptions;
  warehouse: WarehouseFormRecord;
};

export default function Edit({ options, warehouse }: EditProps) {
  const warehousePath = warehouse.path || "/warehouses";

  return (
    <>
      <ErrorNotice />

      <PageHeader className="mb-8" title="Edit Warehouse">
        <li>
          <Link href={warehousePath} prefetch>
            <i className="icn">📄</i>
            View Warehouse Page
          </Link>
        </li>
      </PageHeader>

      <Form isNew={false} options={options} submitLabel="Update Warehouse" warehouse={warehouse} />
    </>
  );
}
