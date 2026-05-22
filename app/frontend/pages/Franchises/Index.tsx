import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Table from "./components/Table";
import { FranchiseRecord } from "./types";

type IndexProps = {
  franchises: FranchiseRecord[];
};

export default function Index({ franchises }: IndexProps) {
  return (
    <>
      <PageHeader
        actions={
          <li>
            <Link href="/franchises/new" prefetch>
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        }
        title="Franchises"
      />

      <div className="section-border-base section-wide">
        <Table franchises={franchises} />
      </div>
    </>
  );
}
