import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Table from "./components/Table";
import { BrandRecord } from "./types";

type IndexProps = {
  brands: BrandRecord[];
};

export default function Index({ brands }: IndexProps) {
  return (
    <>
      <PageHeader title="Brands">
        <li>
          <Link href="/brands/new" prefetch>
            <i className="icn">🐣</i>
            Add New Record
          </Link>
        </li>
      </PageHeader>

      <div className="section_border_base section_wide">
        <Table brands={brands} />
      </div>
    </>
  );
}
