import { Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import { useConfirmAction } from "@/utils/useConfirmAction";
import Details from "./components/Details";
import Products from "./components/Products";
import { ProductRecord, SizeRecord } from "./types";

type ShowProps = {
  products: ProductRecord[];
  size: SizeRecord;
};

export default function Show({ products, size }: ShowProps) {
  const destroySize = useConfirmAction("delete", `/sizes/${size.id}`);

  return (
    <>
      <PageHeader subtitle={`Size ${size.id}`} title={size.value}>
        <li>
          <Link href={`/sizes/${size.id}/edit`} prefetch>
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
