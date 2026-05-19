import { router } from "@inertiajs/react";
import Button from "@/components/Button";
import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
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
      <FlashMessages />

      <header className="nav_header">
        <div className="flex gap-4">
          <hgroup>
            <h1>{color.value}</h1>
            <h4>Color {color.id}</h4>
          </hgroup>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={`/colors/${color.id}/edit`}>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        </menu>
      </header>

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
