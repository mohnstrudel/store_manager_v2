import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { SupplierErrors, SupplierRecord } from "./types";

type NewProps = {
  errors?: SupplierErrors;
  supplier: SupplierRecord;
};

export default function New({ errors = {}, supplier }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader className="mb-8" title="New Supplier" />

      <Form
        errors={errors}
        method="post"
        submitLabel="Create Supplier"
        supplier={supplier}
        url="/suppliers"
      />
    </>
  );
}
