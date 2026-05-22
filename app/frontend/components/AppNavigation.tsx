import { Bars3Icon } from "@heroicons/react/24/outline";
import { router, usePage, Link } from "@inertiajs/react";
import type { PageProps } from "@/types/inertia";

const emptyPagination = { current_page: 1, total_pages: 1, total_count: 0, limit: 50 };
const emptySearch = { q: "" };

type NavLink = {
  href: string;
  label: string;
  component: string;
  pageProps: Record<string, unknown>;
};

const primaryLinks: NavLink[] = [
  {
    href: "/",
    label: "Dashboard",
    component: "Dashboard/Index",
    pageProps: {
      debts_path: "/debts",
      last_orders_pull_path: "/pull-last-orders",
      sale_debts: [],
      sale_debts_count: 0,
      sales_hook_disabled: false,
      suppliers_debts: [],
      total_suppliers_debt: "$0",
    },
  },
  {
    href: "/debts",
    label: "Debts",
    component: "Dashboard/Debts",
    pageProps: {
      debts: [],
      pagination: emptyPagination,
      search: emptySearch,
      unpaid_purchases: [],
    },
  },
  {
    href: "/sales",
    label: "Sales",
    component: "Sales/Index",
    pageProps: {
      sales: [],
      pagination: emptyPagination,
      search: emptySearch,
      last_sync_at: null,
      last_sync_time: null,
    },
  },
  {
    href: "/purchases",
    label: "Purchases",
    component: "Purchases/Index",
    pageProps: {
      purchases: [],
      pagination: emptyPagination,
      search: emptySearch,
      warehouses: [],
      move_path: "/purchases/move",
    },
  },
  {
    href: "/warehouses",
    label: "Warehouses",
    component: "Warehouses/Index",
    pageProps: { warehouses: [] },
  },
  {
    href: "/products",
    label: "Products",
    component: "Products/Index",
    pageProps: {
      products: [],
      pagination: emptyPagination,
      search: emptySearch,
      last_sync_at: null,
    },
  },
  {
    href: "/customers",
    label: "Customers",
    component: "Customers/Index",
    pageProps: { customers: [], pagination: emptyPagination, search: emptySearch },
  },
];

type DropdownLink = NavLink | { divider: true };

const dropdownLinks: DropdownLink[] = [
  {
    href: "/suppliers",
    label: "Suppliers",
    component: "Suppliers/Index",
    pageProps: { suppliers: [] },
  },
  {
    href: "/shipping_companies",
    label: "Shipping Companies",
    component: "ShippingCompanies/Index",
    pageProps: { shippingCompanies: [] },
  },
  { divider: true },
  { href: "/brands", label: "Brands", component: "Brands/Index", pageProps: { brands: [] } },
  {
    href: "/franchises",
    label: "Franchises",
    component: "Franchises/Index",
    pageProps: { franchises: [] },
  },
  { divider: true },
  {
    href: "/versions",
    label: "Versions",
    component: "Versions/Index",
    pageProps: { versions: [] },
  },
  { href: "/colors", label: "Colors", component: "Colors/Index", pageProps: { colors: [] } },
  { href: "/sizes", label: "Sizes", component: "Sizes/Index", pageProps: { sizes: [] } },
  { divider: true },
];

export default function AppNavigation() {
  const { auth } = usePage<PageProps>().props;
  const user = auth?.user ?? null;
  const isGuest = user?.role === "guest";

  return (
    <header className="container mx-auto pt-2 px-4 lg:px-0">
      <nav
        className="flex flex-col items-stretch gap-3 relative lg:flex-row lg:items-center"
        role="navigation-main"
      >
        <ul className="flex w-full items-center justify-between lg:w-auto" role="navigation-logo">
          <li className="text-gray-700 dark:text-gray-500">
            <i className="icn text-2xl mr-2" aria-hidden="true">
              😸
            </i>
            <strong className="align-text-bottom">StoreMate</strong>
          </li>
        </ul>

        <ul className="text-sm flex flex-wrap items-center gap-2 lg:flex-nowrap lg:whitespace-nowrap">
          {isGuest ? (
            <li>
              <button onClick={logOut} type="button">
                Log Out
              </button>
            </li>
          ) : (
            <>
              {primaryLinks.slice(0, 2).map((link) => (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    component={link.component}
                    pageProps={instantPageProps(link.pageProps)}
                    prefetch
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
              <li aria-hidden="true" className="hidden lg:block lg:ml-6" />
              {primaryLinks.slice(2, 5).map((link) => (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    component={link.component}
                    pageProps={instantPageProps(link.pageProps)}
                    prefetch
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
              <li aria-hidden="true" className="hidden lg:block lg:ml-6" />
              {primaryLinks.slice(5).map((link) => (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    component={link.component}
                    pageProps={instantPageProps(link.pageProps)}
                    prefetch
                  >
                    {link.label}
                  </Link>
                </li>
              ))}

              <nav className="ml-0 lg:ml-6" role="navigation-dropdown">
                <button type="button">
                  <Bars3Icon className="h-5 w-5" aria-hidden="true" />
                </button>
                <ul>
                  {dropdownLinks.map((link, index) =>
                    "divider" in link ? (
                      <li aria-hidden="true" className="pb-3" key={`divider-${index}`} />
                    ) : (
                      <li key={link.href}>
                        <Link
                          href={link.href}
                          component={link.component}
                          pageProps={instantPageProps(link.pageProps)}
                          prefetch
                        >
                          {link.label}
                        </Link>
                      </li>
                    ),
                  )}
                  {user?.role === "admin" ? (
                    <li>
                      <Link
                        href="/users"
                        component="Users/Index"
                        pageProps={instantPageProps({ users: [] })}
                        prefetch
                      >
                        Users
                      </Link>
                    </li>
                  ) : null}
                  <li>
                    <button onClick={logOut} type="button">
                      Log Out
                    </button>
                  </li>
                </ul>
              </nav>
            </>
          )}
        </ul>
      </nav>
    </header>
  );
}

function logOut() {
  if (!window.confirm("Are you sure you want to log out?")) return;

  router.post("/log_out");
}

function instantPageProps(pageProps: Record<string, unknown>) {
  return (_currentProps: Record<string, unknown>, sharedProps: Record<string, unknown>) => ({
    ...sharedProps,
    ...pageProps,
  });
}
