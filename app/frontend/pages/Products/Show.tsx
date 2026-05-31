import { Link, router } from "@inertiajs/react";
import { ChevronDoubleDownIcon } from "@heroicons/react/20/solid";
import ImageGallery from "./components/ImageGallery";
import ProductVariants from "./components/ProductVariants";
import SalesSection from "./components/SalesSection";
import PurchasesSection from "./components/PurchasesSection";
import CopyToClipboardButton from "@/components/CopyToClipboardButton";
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
  const hasVariants = variants.length > 0;

  return (
    <>
      <header className="nav_header">
        <div className="flex gap-4">
          <hgroup>
            <h1>{product.title}</h1>
            <h2>{product.full_title}</h2>
          </hgroup>
        </div>
        <menu className="nav_menu">
          {product.can_pull_from_shopify && product.shopify_linked && (
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
        </menu>
      </header>

      <div className="section_wide flex flex-col gap-8">
        <div className="cards">
          <ImageGallery media={product.media} />

          <div className="card grow">
            <h5>Title</h5>
            <p>{product.title}</p>
            <h5>Franchise</h5>
            <p>{product.franchise.title}</p>
            <h5>Version</h5>
            <p>{formatList(product.versions.map((v) => v.value))}</p>
            <h5>Brand</h5>
            <p>{formatList(product.brands.map((b) => b.title))}</p>
            <h5>Size</h5>
            <p>{formatList(product.sizes.map((s) => s.value))}</p>
            <h5>Shape</h5>
            <p>{product.shape}</p>
            <h5>Color</h5>
            <p>{formatList(product.colors.map((c) => c.value))}</p>
          </div>

          <div className="card">
            <h5>ID</h5>
            <p>{product.id}</p>
            <h5>Created At</h5>
            <TimestampColumns columns={product.created_at_columns} />
            <h5>Updated At</h5>
            <TimestampColumns columns={product.updated_at_columns} />
            <h5>Woo ID</h5>
            {product.woo_info?.store_id ? (
              <>
                <p>
                  {product.woo_info.product_url ? (
                    <a
                      className="link"
                      href={product.woo_info.product_url}
                      rel="noopener noreferrer"
                      target="_blank"
                    >
                      {product.woo_info.store_id}
                    </a>
                  ) : (
                    product.woo_info.store_id
                  )}
                </p>
                <CopyToClipboardButton
                  className="text-xs btn_xs"
                  text={product.woo_info.store_id}
                />
              </>
            ) : (
              <p>-</p>
            )}
            <h5>Shopify ID</h5>
            {product.shopify_info?.id_short ? (
              <>
                <p className="flex gap-2">
                  <a
                    className="link"
                    href={product.shopify_info.product_url ?? "#"}
                    rel="noopener noreferrer"
                    target="_blank"
                  >
                    {product.shopify_info.id_short}
                  </a>
                </p>
                <CopyToClipboardButton
                  className="text-xs btn_xs"
                  text={product.shopify_info.id_short}
                />
              </>
            ) : (
              <p>-</p>
            )}
            {product.shopify_info && product.shopify_info.tag_list.length > 0 && (
              <>
                <h5>Tags</h5>
                <p className="max-w-min">{product.shopify_info.tag_list.join(", ")}</p>
              </>
            )}
          </div>
        </div>

        {product.description_html && (
          <div className="card w-full pt-8 pr-12 pb-12 pl-6">
            <div
              className="rich_text columns-2 gap-x-20 font-nunito subpixel-antialiased break-words leading-[1.75]"
              dangerouslySetInnerHTML={{ __html: product.description_html }}
            />
          </div>
        )}

        <ProductVariants variants={variants} />

        <SalesSection hasVariants={hasVariants} sales={active_sales} title="Active Sales" />

        <SalesSection hasVariants={hasVariants} sales={completed_sales} title="Completed Sales" />

        <PurchasesSection purchases={purchases} />
      </div>

      <div className="mt-16">
        <button
          className="btn_red w-full h-12 btn_rounded"
          onClick={() => {
            if (confirm("Are you sure?")) {
              router.delete(product.path);
            }
          }}
          type="button"
        >
          Destroy this product
        </button>
      </div>
    </>
  );
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
