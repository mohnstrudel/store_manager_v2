import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { ShippingCompanyRecord } from "./types";

type EditProps = {
  shippingCompany: ShippingCompanyRecord;
};

export default function Edit({ shippingCompany }: EditProps) {
  return (
    <>
      <PageHeader
        actions={
          <li>
            <Link href={`/shipping_companies/${shippingCompany.id}`}>
              <i className="icn">📄</i>
              View Shipping Company Page
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Shipping Company"
      />

      <Form
        method="patch"
        shippingCompany={shippingCompany}
        submitLabel="Update Shipping Company"
        url={`/shipping_companies/${shippingCompany.id}`}
      />
    </>
  );
}
