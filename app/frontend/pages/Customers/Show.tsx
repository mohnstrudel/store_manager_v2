import { router } from "@inertiajs/react";
import Button from "@/components/Button";
import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Details from "./components/Details";
import Sales from "./components/Sales";
import { CustomerDetailRecord, SaleRecord } from "./types";

type ShowProps = {
  active_sales: SaleRecord[];
  completed_sales: SaleRecord[];
  customer: CustomerDetailRecord;
};

export default function Show({ active_sales, completed_sales, customer }: ShowProps) {
  function destroyCustomer() {
    if (window.confirm("Are you sure?")) {
      router.delete(`/customers/${customer.id}`);
    }
  }

  return (
    <>
      <PageHeader
        actions={
          <li>
            <Link href={`/customers/${customer.id}/edit`}>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        }
        subtitle={`Customer ${customer.id}`}
        title={customer.full_name || customer.email || `Customer ${customer.id}`}
      />

      <div className="section-wide flex flex-col gap-8 mt-8">
        <Details customer={customer} />
        <Sales heading="Active Sales" sales={active_sales} />
        <Sales heading="Completed Sales" sales={completed_sales} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyCustomer} variant="danger">
        Destroy this customer
      </Button>
    </>
  );
}
