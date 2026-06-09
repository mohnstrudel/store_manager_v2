import ProductActions from "./Show/ProductActions";
import ProductDescription from "./Show/ProductDescription";
import ProductOverview from "./Show/ProductOverview";
import ProductVariants from "./Show/ProductVariants";
import PurchasesSection from "./Show/PurchasesSection";
import SalesSection from "./Show/SalesSection";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import { useConfirmAction } from "@/utils/useConfirmAction";
import {
  type ProductShowRecord,
  type PurchaseRecord,
  type SaleItemRecord,
  type VariantRecord,
} from "./types";

type ShowProps = {
  active_sales: SaleItemRecord[];
  completed_sales: SaleItemRecord[];
  product: ProductShowRecord;
  purchases: PurchaseRecord[];
  variants: VariantRecord[];
};

export default function Show({
  active_sales,
  completed_sales,
  product,
  purchases,
  variants,
}: ShowProps) {
  const destroyProduct = useConfirmAction("delete", product.path);
  const hasVariants = variants.length > 0;

  return (
    <>
      <PageHeader subtitle={product.full_title} title={product.title}>
        <ProductActions product={product} />
      </PageHeader>

      <div className="section_wide flex flex-col gap-8">
        <ProductOverview product={product} />
        <ProductDescription html={product.description_html} />
        {hasVariants && <ProductVariants variants={variants} />}
        <SalesSection hasVariants={hasVariants} sales={active_sales} title="Active Sales" />
        <SalesSection hasVariants={hasVariants} sales={completed_sales} title="Completed Sales" />
        <PurchasesSection purchases={purchases} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyProduct} variant="danger">
        Destroy this product
      </Button>
    </>
  );
}
