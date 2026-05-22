import { router, Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
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
      <PageHeader
        actions={
          <li>
            <Link href={`/brands/${brand.id}/edit`}>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        }
        subtitle={`Brand ${brand.id}`}
        title={brand.title}
      />

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
