import { router, Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
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
      <PageHeader
        actions={
          <li>
            <Link href={`/sizes/${size.id}/edit`} prefetch>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        }
        subtitle={`Size ${size.id}`}
        title={size.value}
      />

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
