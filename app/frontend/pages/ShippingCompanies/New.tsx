import PageHeader from "@/components/PageHeader";

import Form from "./components/Form";
import { ShippingCompanyFormRecord } from "./types";

type NewProps = {
  shippingCompany: ShippingCompanyFormRecord;
};

export default function New({ shippingCompany }: NewProps) {
  return (
    <>
      <PageHeader className="mb-8" title="New Shipping Company" />

      <Form
        method="post"
        shippingCompany={shippingCompany}
        submitLabel="Create Shipping Company"
        url="/shipping_companies"
      />
    </>
  );
}
