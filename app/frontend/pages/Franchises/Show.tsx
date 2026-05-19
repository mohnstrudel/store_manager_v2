import { router } from "@inertiajs/react";
import Button from "@/components/Button";
import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
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
      <FlashMessages />

      <PageHeader
        actions={
          <li>
            <Link href={`/franchises/${franchise.id}/edit`}>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        }
        subtitle={`Franchise ${franchise.id}`}
        title={franchise.title}
      />

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
