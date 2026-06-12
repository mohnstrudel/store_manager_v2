import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";
import Form from "./components/Form";
import { SupplierRecord } from "./types";

type NewProps = {
  supplier: SupplierRecord;
};

export default function New({ supplier }: NewProps) {
  return (
    <>
      <PageHeader className="mb-8" title="New Supplier" />

      <Form
        method="post"
        submitLabel="Create Supplier"
        supplier={supplier}
        url={routes.suppliers.create.path()}
      />
    </>
  );
}
