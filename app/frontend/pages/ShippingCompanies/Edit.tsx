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
      <PageHeader className="mb-8" title="Edit Shipping Company">
        <li>
          <Link href={`/shipping_companies/${shippingCompany.id}`} prefetch>
            <i className="icn">📄</i>
            View Shipping Company Page
          </Link>
        </li>
      </PageHeader>

      <Form
        method="patch"
        shippingCompany={shippingCompany}
        submitLabel="Update Shipping Company"
        url={`/shipping_companies/${shippingCompany.id}`}
      />
    </>
  );
}
