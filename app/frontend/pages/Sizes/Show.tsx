import { router } from "@inertiajs/react";
import Button from "@/components/Button";
import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
import Details from "./components/Details";
import Products from "./components/Products";
import { ProductRecord, SizeRecord } from "./types";

type ShowProps = {
  products: ProductRecord[];
  size: SizeRecord;
};

export default function Show({ products, size }: ShowProps) {
  function destroySize() {
    if (window.confirm("Are you sure?")) {
      router.delete(`/sizes/${size.id}`);
    }
  }

  return (
    <>
      <FlashMessages />

      <header className="nav_header">
        <div className="flex gap-4">
          <hgroup>
            <h1>{size.value}</h1>
            <h4>Size {size.id}</h4>
          </hgroup>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={`/sizes/${size.id}/edit`}>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        </menu>
      </header>

      <div className="section-wide flex flex-col gap-8 mt-8">
        <Details size={size} />
        <Products products={products} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroySize} variant="danger">
        Destroy this size
      </Button>
    </>
  );
}
