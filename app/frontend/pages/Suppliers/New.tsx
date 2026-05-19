import ErrorNotice from "@/components/ErrorNotice";
import Form from "./components/Form";
import { SupplierErrors, SupplierRecord } from "./types";

type NewProps = {
  errors: SupplierErrors;
  supplier: SupplierRecord;
};

export default function New({ errors, supplier }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>New Supplier</h1>
        </div>
      </header>

      <Form errors={errors} method="post" submitLabel="Create Supplier" supplier={supplier} url="/suppliers" />
    </>
  );
}
