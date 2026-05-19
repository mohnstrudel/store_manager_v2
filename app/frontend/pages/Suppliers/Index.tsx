import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
import Table from "./components/Table";
import { SupplierRecord } from "./types";

type IndexProps = {
  suppliers: SupplierRecord[];
};

export default function Index({ suppliers }: IndexProps) {
  return (
    <>
      <FlashMessages />

      <header className="nav_header">
        <hgroup>
          <h1>Suppliers</h1>
        </hgroup>
        <menu className="nav_menu">
          <li>
            <Link href="/suppliers/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        </menu>
      </header>

      <div className="section-border-base section-wide">
        <Table suppliers={suppliers} />
      </div>
    </>
  );
}
