import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Table from "./components/Table";
import { ShippingCompanyRecord } from "./types";

type IndexProps = {
  shippingCompanies: ShippingCompanyRecord[];
};

export default function Index({ shippingCompanies }: IndexProps) {
  return (
    <>
      <PageHeader title="Shipping Companies">
        <li>
          <Link href="/shipping_companies/new" prefetch>
            <i className="icn">🐣</i>
            Add New Record
          </Link>
        </li>
      </PageHeader>

      <div className="section_border_base section_wide">
        <Table shippingCompanies={shippingCompanies} />
      </div>
    </>
  );
}
