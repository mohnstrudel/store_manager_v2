import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
import Table from "./components/Table";
import { VersionRecord } from "./types";

type IndexProps = {
  versions: VersionRecord[];
};

export default function Index({ versions }: IndexProps) {
  return (
    <>
      <FlashMessages />

      <header className="nav_header">
        <hgroup>
          <h1>Versions</h1>
        </hgroup>
        <menu className="nav_menu">
          <li>
            <Link href="/versions/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        </menu>
      </header>

      <div className="section-border-base section-wide">
        <Table versions={versions} />
      </div>
    </>
  );
}
