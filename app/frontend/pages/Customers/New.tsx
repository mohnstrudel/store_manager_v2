import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { CustomerRecord } from "./types";

type NewProps = {
  customer: CustomerRecord;
};

export default function New({ customer }: NewProps) {
  return (
    <>
      <PageHeader className="mb-8" title="New Customer" />

      <Form customer={customer} method="post" submitLabel="Create Customer" url="/customers" />
    </>
  );
}
