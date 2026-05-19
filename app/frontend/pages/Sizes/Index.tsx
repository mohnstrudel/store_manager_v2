import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Table from "./components/Table";
import { SizeRecord } from "./types";

type IndexProps = {
  sizes: SizeRecord[];
};

export default function Index({ sizes }: IndexProps) {
  return (
    <>

      <PageHeader
        actions={
          <li>
            <Link href="/sizes/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        }
        title="Sizes"
      />

      <div className="section-border-base section-wide">
        <Table sizes={sizes} />
      </div>
    </>
  );
}
