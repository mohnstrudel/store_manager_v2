import { Link } from "@inertiajs/react";
import { ChevronDoubleDownIcon } from "@heroicons/react/20/solid";
import ImageGallery from "./components/ImageGallery";
import ProductVariants from "./components/ProductVariants";
import SalesSection from "./components/SalesSection";
import PurchasesSection from "./components/PurchasesSection";
import Button from "@/components/Button";
import CopyToClipboardButton from "@/components/CopyToClipboardButton";
import PageHeader from "@/components/PageHeader";
import { useConfirmedDestroy } from "@/lib/useConfirmedDestroy";
import {
  type ProductShowRecord,
  type PurchaseRecord,
  type SaleItemRecord,
  type TimestampColumn,
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
  const destroyProduct = useConfirmedDestroy(product.path);

  return (
    <>
      <PageHeader subtitle={product.full_title} title={product.title}>
        <ProductActions product={product} />
      </PageHeader>

      <div className="section_wide flex flex-col gap-8">
        <ProductOverview product={product} />
        <ProductDescription html={product.description_html} />
        <ProductActivity
          activeSales={active_sales}
          completedSales={completed_sales}
          purchases={purchases}
          variants={variants}
        />
      </div>

      <DestroyProductButton onDestroy={destroyProduct} />
    </>
  );
}

type ProductProps = {
  product: ProductShowRecord;
};

function ProductActions({ product }: ProductProps) {
  return (
    <>
      {canFetchFromShopify(product) && (
        <li>
          <Link className="btn_rounded" href={product.shopify_pull_path} method="post">
            <ChevronDoubleDownIcon height={20} width={20} />
            Fetch
          </Link>
        </li>
      )}
      <li>
        <Link href={product.new_purchase_path} prefetch>
          <i className="icn">💰</i>
          New Purchase
        </Link>
      </li>
      <li>
        <Link href={product.edit_path} prefetch>
          <i className="icn">✏</i>
          Edit
        </Link>
      </li>
    </>
  );
}

function ProductOverview({ product }: ProductProps) {
  return (
    <div className="cards">
      <ImageGallery media={product.media} />
      <ProductDetailsCard product={product} />
      <StoreIdentifiersCard product={product} />
    </div>
  );
}

function ProductDetailsCard({ product }: ProductProps) {
  return (
    <div className="card grow">
      <h5>Title</h5>
      <p>{product.title}</p>
      <h5>Franchise</h5>
      <p>{product.franchise.title}</p>
      <h5>Version</h5>
      <p>{formatList(product.versions.map((version) => version.value))}</p>
      <h5>Brand</h5>
      <p>{formatList(product.brands.map((brand) => brand.title))}</p>
      <h5>Size</h5>
      <p>{formatList(product.sizes.map((size) => size.value))}</p>
      <h5>Shape</h5>
      <p>{product.shape}</p>
      <h5>Color</h5>
      <p>{formatList(product.colors.map((color) => color.value))}</p>
    </div>
  );
}

function StoreIdentifiersCard({ product }: ProductProps) {
  return (
    <div className="card">
      <h5>ID</h5>
      <p>{product.id}</p>
      <h5>Created At</h5>
      <TimestampColumns columns={product.created_at_columns} />
      <h5>Updated At</h5>
      <TimestampColumns columns={product.updated_at_columns} />
      <h5>Woo ID</h5>
      <WooIdentifier product={product} />
      <h5>Shopify ID</h5>
      <ShopifyIdentifier product={product} />
      <ShopifyTags product={product} />
    </div>
  );
}

function WooIdentifier({ product }: ProductProps) {
  const wooInfo = product.woo_info;

  if (!wooInfo?.store_id) return <p>-</p>;

  return (
    <>
      <p>
        {wooInfo.product_url ? (
          <ExternalStoreLink href={wooInfo.product_url}>{wooInfo.store_id}</ExternalStoreLink>
        ) : (
          wooInfo.store_id
        )}
      </p>
      <CopyStoreIdButton storeId={wooInfo.store_id} />
    </>
  );
}

function ShopifyIdentifier({ product }: ProductProps) {
  const shopifyInfo = product.shopify_info;

  if (!shopifyInfo?.id_short) return <p>-</p>;

  return (
    <>
      <p className="flex gap-2">
        <ExternalStoreLink href={shopifyInfo.product_url ?? "#"}>
          {shopifyInfo.id_short}
        </ExternalStoreLink>
      </p>
      <CopyStoreIdButton storeId={shopifyInfo.id_short} />
    </>
  );
}

function ShopifyTags({ product }: ProductProps) {
  if (!product.shopify_info || product.shopify_info.tag_list.length === 0) return null;

  return (
    <>
      <h5>Tags</h5>
      <p className="max-w-min">{product.shopify_info.tag_list.join(", ")}</p>
    </>
  );
}

type ExternalStoreLinkProps = {
  children: string;
  href: string;
};

function ExternalStoreLink({ children, href }: ExternalStoreLinkProps) {
  return (
    <a className="link" href={href} rel="noopener noreferrer" target="_blank">
      {children}
    </a>
  );
}

function CopyStoreIdButton({ storeId }: { storeId: string }) {
  return <CopyToClipboardButton className="text-xs btn_xs" text={storeId} />;
}

function ProductDescription({ html }: { html: string }) {
  if (!html) return null;

  return (
    <div className="card w-full pt-8 pr-12 pb-12 pl-6">
      <div
        className="rich_text columns-2 gap-x-20 font-nunito subpixel-antialiased break-words leading-[1.75]"
        dangerouslySetInnerHTML={{ __html: html }}
      />
    </div>
  );
}

type ProductActivityProps = {
  activeSales: SaleItemRecord[];
  completedSales: SaleItemRecord[];
  purchases: PurchaseRecord[];
  variants: VariantRecord[];
};

function ProductActivity({
  activeSales,
  completedSales,
  purchases,
  variants,
}: ProductActivityProps) {
  const hasVariants = variants.length > 0;

  return (
    <>
      <ProductVariants variants={variants} />
      <SalesSection hasVariants={hasVariants} sales={activeSales} title="Active Sales" />
      <SalesSection hasVariants={hasVariants} sales={completedSales} title="Completed Sales" />
      <PurchasesSection purchases={purchases} />
    </>
  );
}

function DestroyProductButton({ onDestroy }: { onDestroy: () => void }) {
  return (
    <Button className="w-full h-12 mt-16" onClick={onDestroy} variant="danger">
      Destroy this product
    </Button>
  );
}

function canFetchFromShopify(product: ProductShowRecord) {
  return product.can_pull_from_shopify && product.shopify_linked;
}

function formatList(values: string[]) {
  const presentValues = values.filter(Boolean);

  return presentValues.length > 0 ? presentValues.join(", ") : "-";
}

function TimestampColumns({ columns }: { columns: TimestampColumn[] }) {
  return (
    <div className="grid grid-flow-col auto-cols-max gap-6">
      {columns.map((column) => (
        <div className="flex flex-col gap-1" key={column.key}>
          <span className="mt-1 text-xs/1 font-medium uppercase tracking-wide text-gray-400 dark:text-gray-400">
            {column.label}
          </span>
          <span className="text-sm">{column.value}</span>
        </div>
      ))}
    </div>
  );
}
