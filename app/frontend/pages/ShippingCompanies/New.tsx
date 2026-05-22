import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { ShippingCompanyRecord } from "./types";

type NewProps = {
  shippingCompany: ShippingCompanyRecord;
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
