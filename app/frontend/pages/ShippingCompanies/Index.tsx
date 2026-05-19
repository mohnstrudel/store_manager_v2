import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
import Table from "./components/Table";
import { ShippingCompanyRecord } from "./types";

type IndexProps = {
  shippingCompanies: ShippingCompanyRecord[];
};

export default function Index({ shippingCompanies }: IndexProps) {
  return (
    <>
      <FlashMessages />

      <header className="nav_header">
        <hgroup>
          <h1>Shipping Companies</h1>
        </hgroup>
        <menu className="nav_menu">
          <li>
            <Link href="/shipping_companies/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        </menu>
      </header>

      <div className="section-border-base section-wide">
        <Table shippingCompanies={shippingCompanies} />
      </div>
    </>
  );
}
