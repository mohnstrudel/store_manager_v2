import { Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import { useConfirmAction } from "@/lib/useConfirmAction";
import Details from "./components/Details";
import Sales from "./components/Sales";
import { CustomerDetailRecord, SaleRecord } from "./types";

type ShowProps = {
  active_sales: SaleRecord[];
  completed_sales: SaleRecord[];
  customer: CustomerDetailRecord;
};

export default function Show({ active_sales, completed_sales, customer }: ShowProps) {
  const editPath = customer.path ? `${customer.path}/edit` : "#";
  const destroyPath = customer.path || "#";
  const destroyCustomer = useConfirmAction("delete", destroyPath);
  const title =
    customer.full_name ||
    customer.email ||
    (customer.id != null ? `Customer ${customer.id}` : "Customer");
  const subtitle = customer.id != null ? `Customer ${customer.id}` : undefined;

  return (
    <>
      <PageHeader subtitle={subtitle} title={title}>
        <li>
          <Link href={editPath} prefetch>
            <i className="icn">✏</i>
            Edit
          </Link>
        </li>
      </PageHeader>

      <div className="section_wide flex flex-col gap-8 mt-8">
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
