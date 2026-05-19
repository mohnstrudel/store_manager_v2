import { router } from "@inertiajs/react";
import Button from "@/components/Button";
import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
import Details from "./components/Details";
import Products from "./components/Products";
import { BrandRecord, ProductRecord } from "./types";

type ShowProps = {
  brand: BrandRecord;
  products: ProductRecord[];
};

export default function Show({ brand, products }: ShowProps) {
  function destroyBrand() {
    if (window.confirm("Are you sure?")) {
      router.delete(`/brands/${brand.id}`);
    }
  }

  return (
    <>
      <FlashMessages />

      <header className="nav_header">
        <div className="flex gap-4">
          <hgroup>
            <h1>{brand.title}</h1>
            <h4>Brand {brand.id}</h4>
          </hgroup>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={`/brands/${brand.id}/edit`}>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        </menu>
      </header>

      <div className="section-wide flex flex-col gap-8 mt-8">
        <Details brand={brand} />
        <Products products={products} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyBrand} variant="danger">
        Destroy this brand
      </Button>
    </>
  );
}
