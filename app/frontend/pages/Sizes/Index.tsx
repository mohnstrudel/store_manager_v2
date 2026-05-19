import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
import Table from "./components/Table";
import { SizeRecord } from "./types";

type IndexProps = {
  sizes: SizeRecord[];
};

export default function Index({ sizes }: IndexProps) {
  return (
    <>
      <FlashMessages />

      <header className="nav_header">
        <h1>Sizes</h1>
        <menu className="nav_menu">
          <li>
            <Link href="/sizes/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        </menu>
      </header>

      <div className="section-border-base section-wide">
        <Table sizes={sizes} />
      </div>
    </>
  );
}
