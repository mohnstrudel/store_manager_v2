import { router, Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import Details from "./components/Details";
import Products from "./components/Products";
import { ColorRecord, ProductRecord } from "./types";

type ShowProps = {
  color: ColorRecord;
  products: ProductRecord[];
};

export default function Show({ color, products }: ShowProps) {
  function destroyColor() {
    if (window.confirm("Are you sure?")) {
      router.delete(`/colors/${color.id}`);
    }
  }

  return (
    <>
      <PageHeader
        actions={
          <li>
            <Link href={`/colors/${color.id}/edit`} prefetch>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        }
        subtitle={`Color ${color.id}`}
        title={color.value}
      />

      <div className="section-wide flex flex-col gap-8 mt-8">
        <Details color={color} />
        <Products products={products} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyColor} variant="danger">
        Destroy this color
      </Button>
    </>
  );
}
