import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Table from "./components/Table";
import { ColorRecord } from "./types";

type IndexProps = {
  colors: ColorRecord[];
};

export default function Index({ colors }: IndexProps) {
  return (
    <>

      <PageHeader
        actions={
          <li>
            <Link href="/colors/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        }
        title="Colors"
      />

      <div className="section-border-base section-wide">
        <Table colors={colors} />
      </div>
    </>
  );
}
