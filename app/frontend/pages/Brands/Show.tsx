import { Link } from "@inertiajs/react";

import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";
import { useConfirmAction } from "@/utils/useConfirmAction";

import Details from "./components/Details";
import Products from "./components/Products";
import { BrandRecord, ProductRecord } from "./types";

type ShowProps = {
  brand: BrandRecord;
  products: ProductRecord[];
};

export default function Show({ brand, products }: ShowProps) {
  const currentBrandPath =
    brand.id === null ? routes.brands.index.path() : routes.brands.show.path({ id: brand.id });
  const currentEditPath =
    brand.id === null ? routes.brands.new.path() : routes.brands.edit.path({ id: brand.id });
  const destroyBrand = useConfirmAction("delete", currentBrandPath);

  return (
    <>
      <PageHeader subtitle={`Brand ${brand.id}`} title={brand.title}>
        <li>
          <Link href={currentEditPath} prefetch>
            <i className="icn">✏</i>
            Edit
          </Link>
        </li>
      </PageHeader>

      <div className="section_wide flex flex-col gap-8 mt-8">
        <Details brand={brand} />
        <Products products={products} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyBrand} variant="danger">
        Destroy this brand
      </Button>
    </>
  );
}
