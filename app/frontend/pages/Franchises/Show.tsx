import { router } from "@inertiajs/react";
import Button from "@/components/Button";
import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
import Details from "./components/Details";
import Products from "./components/Products";
import { FranchiseRecord, ProductRecord } from "./types";

type ShowProps = {
  franchise: FranchiseRecord;
  products: ProductRecord[];
};

export default function Show({ franchise, products }: ShowProps) {
  function destroyFranchise() {
    if (window.confirm("Are you sure?")) {
      router.delete(`/franchises/${franchise.id}`);
    }
  }

  return (
    <>
      <FlashMessages />

      <header className="nav_header">
        <div className="flex gap-4">
          <hgroup>
            <h1>{franchise.title}</h1>
            <h4>Franchise {franchise.id}</h4>
          </hgroup>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={`/franchises/${franchise.id}/edit`}>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        </menu>
      </header>

      <div className="section-wide flex flex-col gap-8 mt-8">
        <Details franchise={franchise} />
        <Products products={products} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyFranchise} variant="danger">
        Destroy this franchise
      </Button>
    </>
  );
}
