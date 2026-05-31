import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Table from "./components/Table";
import { ColorRecord } from "./types";

type IndexProps = {
  colors: ColorRecord[];
};

export default function Index({ colors }: IndexProps) {
  return (
    <>
      <PageHeader title="Colors">
        <li>
          <Link href="/colors/new" prefetch>
            <i className="icn">🐣</i>
            Add New Record
          </Link>
        </li>
      </PageHeader>

      <div className="section_border_base section_wide">
        <Table colors={colors} />
      </div>
    </>
  );
}
