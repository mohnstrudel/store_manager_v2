import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Table from "./components/Table";
import { BrandRecord } from "./types";

type IndexProps = {
  brands: BrandRecord[];
};

export default function Index({ brands }: IndexProps) {
  return (
    <>

      <PageHeader
        actions={
          <li>
            <Link href="/brands/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        }
        title="Brands"
      />

      <div className="section-border-base section-wide">
        <Table brands={brands} />
      </div>
    </>
  );
}
