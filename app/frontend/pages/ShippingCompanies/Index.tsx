import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Table from "./components/Table";
import { ShippingCompanyRecord } from "./types";

type IndexProps = {
  shippingCompanies: ShippingCompanyRecord[];
};

export default function Index({ shippingCompanies }: IndexProps) {
  return (
    <>

      <PageHeader
        actions={
          <li>
            <Link href="/shipping_companies/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        }
        title="Shipping Companies"
      />

      <div className="section-border-base section-wide">
        <Table shippingCompanies={shippingCompanies} />
      </div>
    </>
  );
}
