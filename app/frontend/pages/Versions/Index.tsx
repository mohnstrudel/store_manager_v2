import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Table from "./components/Table";
import { VersionRecord } from "./types";

type IndexProps = {
  versions: VersionRecord[];
};

export default function Index({ versions }: IndexProps) {
  return (
    <>
      <FlashMessages />

      <PageHeader
        actions={
          <li>
            <Link href="/versions/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        }
        title="Versions"
      />

      <div className="section-border-base section-wide">
        <Table versions={versions} />
      </div>
    </>
  );
}
