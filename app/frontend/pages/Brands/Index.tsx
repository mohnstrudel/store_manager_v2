import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
import Table from "./components/Table";
import { BrandRecord } from "./types";

type IndexProps = {
  brands: BrandRecord[];
};

export default function Index({ brands }: IndexProps) {
  return (
    <>
      <FlashMessages />

      <header className="nav_header">
        <hgroup>
          <h1>Brands</h1>
        </hgroup>
        <menu className="nav_menu">
          <li>
            <Link href="/brands/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        </menu>
      </header>

      <div className="section-border-base section-wide">
        <Table brands={brands} />
      </div>
    </>
  );
}
