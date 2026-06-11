import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";
import Form from "./components/Form";
import { SupplierRecord } from "./types";

type EditProps = {
  supplier: SupplierRecord;
};

export default function Edit({ supplier }: EditProps) {
  const currentSupplierPath = routes.suppliers.show.path({ id: supplier.id! });

  return (
    <>
      <PageHeader className="mb-8" title="Edit Supplier">
        <li>
          <Link href={currentSupplierPath} prefetch>
            <i className="icn">📄</i>
            View Supplier Page
          </Link>
        </li>
      </PageHeader>

      <Form
        method="patch"
        submitLabel="Update Supplier"
        supplier={supplier}
        url={currentSupplierPath}
      />
    </>
  );
}
