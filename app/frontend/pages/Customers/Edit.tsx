import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { CustomerRecord } from "./types";

type EditProps = {
  customer: CustomerRecord;
};

export default function Edit({ customer }: EditProps) {
  return (
    <>

      <PageHeader
        actions={
          <li>
            <Link href={`/customers/${customer.id}`}>
              <i className="icn">📄</i>
              View Customer Page
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Customer"
      />

      <Form
        customer={customer}
        method="patch"
        submitLabel="Update Customer"
        url={`/customers/${customer.id}`}
      />
    </>
  );
}
