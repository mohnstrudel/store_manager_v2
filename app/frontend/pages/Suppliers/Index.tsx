import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Table from "./components/Table";
import { SupplierRecord } from "./types";

type IndexProps = {
  suppliers: SupplierRecord[];
};

export default function Index({ suppliers }: IndexProps) {
  return (
    <>
      <PageHeader title="Suppliers">
        <li>
          <Link href="/suppliers/new" prefetch>
            <i className="icn">🐣</i>
            Add New Record
          </Link>
        </li>
      </PageHeader>

      <div className="section_border_base section_wide">
        <Table suppliers={suppliers} />
      </div>
    </>
  );
}
