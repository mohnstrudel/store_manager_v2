import { Link } from "@inertiajs/react";

import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";
import { useConfirmAction } from "@/utils/useConfirmAction";

import Details from "./components/Details";
import Products from "./components/Products";
import { FranchiseRecord, ProductRecord } from "./types";

type ShowProps = {
  franchise: FranchiseRecord;
  products: ProductRecord[];
};

export default function Show({ franchise, products }: ShowProps) {
  const currentFranchisePath =
    franchise.id === null
      ? routes.franchises.index.path()
      : routes.franchises.show.path({ id: franchise.id });
  const currentEditPath =
    franchise.id === null
      ? routes.franchises.new.path()
      : routes.franchises.edit.path({ id: franchise.id });
  const destroyFranchise = useConfirmAction("delete", currentFranchisePath);

  return (
    <>
      <PageHeader subtitle={`Franchise ${franchise.id}`} title={franchise.title}>
        <li>
          <Link href={currentEditPath} prefetch>
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
