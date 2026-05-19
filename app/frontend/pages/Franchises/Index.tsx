import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
import Table from "./components/Table";
import { FranchiseRecord } from "./types";

type IndexProps = {
  franchises: FranchiseRecord[];
};

export default function Index({ franchises }: IndexProps) {
  return (
    <>
      <FlashMessages />

      <header className="nav_header">
        <hgroup>
          <h1>Franchises</h1>
        </hgroup>
        <menu className="nav_menu">
          <li>
            <Link href="/franchises/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        </menu>
      </header>

      <div className="section-border-base section-wide">
        <Table franchises={franchises} />
      </div>
    </>
  );
}
