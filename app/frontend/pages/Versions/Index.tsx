import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Table from "./components/Table";
import { VersionRecord } from "./types";

type IndexProps = {
  versions: VersionRecord[];
};

export default function Index({ versions }: IndexProps) {
  return (
    <>
      <PageHeader title="Versions">
        <li>
          <Link href="/versions/new" prefetch>
            <i className="icn">🐣</i>
            Add New Record
          </Link>
        </li>
      </PageHeader>

      <div className="section_border_base section_wide">
        <Table versions={versions} />
      </div>
    </>
  );
}
