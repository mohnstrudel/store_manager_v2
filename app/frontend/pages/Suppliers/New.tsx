import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { SupplierRecord } from "./types";

type NewProps = {
  supplier: SupplierRecord;
};

export default function New({ supplier }: NewProps) {
  return (
    <>
      <PageHeader className="mb-8" title="New Supplier" />

      <Form method="post" submitLabel="Create Supplier" supplier={supplier} url="/suppliers" />
    </>
  );
}
