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
      <PageHeader title="Franchises">
        <li>
          <Link href="/franchises/new" prefetch>
            <i className="icn">🐣</i>
            Add New Record
          </Link>
        </li>
      </PageHeader>

      <div className="section_border_base section_wide">
        <Table franchises={franchises} />
      </div>
    </>
  );
}
