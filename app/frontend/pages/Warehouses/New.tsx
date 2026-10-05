import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";

import Form from "./components/Form";
import type { WarehouseFormOptions, WarehouseFormRecord } from "./types";

type NewProps = {
  options: WarehouseFormOptions;
  warehouse: WarehouseFormRecord;
};

export default function New({ options, warehouse }: NewProps) {
  return (
    <>
      <ErrorNotice />

      <PageHeader className="mb-8" title="New Warehouse" />

      <Form isNew options={options} submitLabel="Create Warehouse" warehouse={warehouse} />
    </>
  );
}
