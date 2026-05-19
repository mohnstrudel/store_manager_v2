import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
import Table from "./components/Table";
import { ColorRecord } from "./types";

type IndexProps = {
  colors: ColorRecord[];
};

export default function Index({ colors }: IndexProps) {
  return (
    <>
      <FlashMessages />

      <header className="nav_header">
        <hgroup>
          <h1>Colors</h1>
        </hgroup>
        <menu className="nav_menu">
          <li>
            <Link href="/colors/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        </menu>
      </header>

      <div className="section-border-base section-wide">
        <Table colors={colors} />
      </div>
    </>
  );
}
