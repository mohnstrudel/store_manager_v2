import { Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import { useConfirmAction } from "@/lib/useConfirmAction";
import Details from "./components/Details";
import Products from "./components/Products";
import { ColorRecord, ProductRecord } from "./types";

type ShowProps = {
  color: ColorRecord;
  products: ProductRecord[];
};

export default function Show({ color, products }: ShowProps) {
  const destroyColor = useConfirmAction("delete", `/colors/${color.id}`);

  return (
    <>
      <PageHeader subtitle={`Color ${color.id}`} title={color.value}>
        <li>
          <Link href={`/colors/${color.id}/edit`} prefetch>
            <i className="icn">✏</i>
            Edit
          </Link>
        </li>
      </PageHeader>

      <div className="section_wide flex flex-col gap-8 mt-8">
        <Details color={color} />
        <Products products={products} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyColor} variant="danger">
        Destroy this color
      </Button>
    </>
  );
}
