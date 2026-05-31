import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Table from "./components/Table";
import { SizeRecord } from "./types";

type IndexProps = {
  sizes: SizeRecord[];
};

export default function Index({ sizes }: IndexProps) {
  return (
    <>
      <PageHeader title="Sizes">
        <li>
          <Link href="/sizes/new" prefetch>
            <i className="icn">🐣</i>
            Add New Record
          </Link>
        </li>
      </PageHeader>

      <div className="section_border_base section_wide">
        <Table sizes={sizes} />
      </div>
    </>
  );
}
