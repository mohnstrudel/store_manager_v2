import { Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";
import { useConfirmAction } from "@/utils/useConfirmAction";
import Details from "./components/Details";
import Products from "./components/Products";
import { ProductRecord, SizeRecord } from "./types";

type ShowProps = {
  products: ProductRecord[];
  size: SizeRecord;
};

export default function Show({ products, size }: ShowProps) {
  const currentSizePath =
    size.id === null ? routes.sizes.index.path() : routes.sizes.show.path({ id: size.id });
  const currentEditPath =
    size.id === null ? routes.sizes.new.path() : routes.sizes.edit.path({ id: size.id });
  const destroySize = useConfirmAction("delete", currentSizePath);

  return (
    <>
      <PageHeader subtitle={`Size ${size.id}`} title={size.value}>
        <li>
          <Link href={currentEditPath} prefetch>
            <i className="icn">✏</i>
            Edit
          </Link>
        </li>
      </PageHeader>

      <div className="section_wide flex flex-col gap-8 mt-8">
        <Details size={size} />
        <Products products={products} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroySize} variant="danger">
        Destroy this size
      </Button>
    </>
  );
}
