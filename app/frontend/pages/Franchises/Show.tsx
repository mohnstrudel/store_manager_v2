import { router, Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
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
      <PageHeader subtitle={`Franchise ${franchise.id}`} title={franchise.title}>
        <li>
          <Link href={`/franchises/${franchise.id}/edit`} prefetch>
            <i className="icn">✏</i>
            Edit
          </Link>
        </li>
      </PageHeader>

      <div className="section_wide flex flex-col gap-8 mt-8">
        <Details franchise={franchise} />
        <Products products={products} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyFranchise} variant="danger">
        Destroy this franchise
      </Button>
    </>
  );
}
