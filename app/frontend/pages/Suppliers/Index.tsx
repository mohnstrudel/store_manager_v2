import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Table from "./components/Table";
import { SupplierRecord } from "./types";

type IndexProps = {
  suppliers: SupplierRecord[];
};

export default function Index({ suppliers }: IndexProps) {
  return (
    <>
      <FlashMessages />

      <PageHeader
        actions={
          <li>
            <Link href="/suppliers/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        }
        title="Suppliers"
      />

      <div className="section-border-base section-wide">
        <Table suppliers={suppliers} />
      </div>
    </>
  );
}
