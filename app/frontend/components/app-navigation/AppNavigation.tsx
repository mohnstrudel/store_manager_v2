import { useCallback } from "react";
import { Bars3Icon } from "@heroicons/react/24/outline";
import { Link, router, usePage } from "@inertiajs/react";
import routes from "@/utils/routes";
import type { PageProps } from "@/types/inertia";
import { useNavigationDropdown } from "./useNavigationDropdown";

const emptyPagination = {
  current_page: 1,
  total_pages: 1,
  total_count: 0,
  limit: 50,
};
const emptySearch = { q: "" };

type NavigationLink = {
  href: string;
  label: string;
  component: string;
  pageProps: Record<string, unknown>;
};

type NavigationDivider = {
  divider: true;
  key: string;
};

const primaryLinks: NavigationLink[] = [
  {
    href: routes.dashboard.index.path(),
    label: "Dashboard",
    component: "Dashboard/Index",
    pageProps: {
      debts_path: routes.dashboardDebts.show.path(),
      last_orders_pull_path: routes.dashboardLastOrdersPulls.create.path(),
      sale_debts: [],
      sale_debts_count: 0,
      sales_hook_disabled: false,
      suppliers_debts: [],
      total_suppliers_debt: "$0",
    },
  },
  {
    href: routes.dashboardDebts.show.path(),
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
    href: routes.sales.list.path(),
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
    href: routes.purchases.list.path(),
    label: "Purchases",
    component: "Purchases/Index",
    pageProps: {
      purchases: [],
      pagination: emptyPagination,
      search: emptySearch,
      warehouses: [],
      move_path: routes.purchasesMoves.create.path(),
    },
  },
  {
    href: routes.warehouses.index.path(),
    label: "Warehouses",
    component: "Warehouses/Index",
    pageProps: { warehouses: [] },
  },
  {
    href: routes.products.list.path(),
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
    href: routes.customers.list.path(),
    label: "Customers",
    component: "Customers/Index",
    pageProps: {
      customers: [],
      pagination: emptyPagination,
      search: emptySearch,
    },
  },
];

const overflowLinks: Array<NavigationLink | NavigationDivider> = [
  {
    href: routes.suppliers.index.path(),
    label: "Suppliers",
    component: "Suppliers/Index",
    pageProps: { suppliers: [] },
  },
  {
    href: routes.shippingCompanies.index.path(),
    label: "Shipping Companies",
    component: "ShippingCompanies/Index",
    pageProps: { shippingCompanies: [] },
  },
  { divider: true, key: "divider-suppliers" },
  {
    href: routes.brands.index.path(),
    label: "Brands",
    component: "Brands/Index",
    pageProps: { brands: [] },
  },
  {
    href: routes.franchises.index.path(),
    label: "Franchises",
    component: "Franchises/Index",
    pageProps: { franchises: [] },
  },
  { divider: true, key: "divider-brands" },
  {
    href: routes.versions.index.path(),
    label: "Versions",
    component: "Versions/Index",
    pageProps: { versions: [] },
  },
  {
    href: routes.colors.index.path(),
    label: "Colors",
    component: "Colors/Index",
    pageProps: { colors: [] },
  },
  {
    href: routes.sizes.index.path(),
    label: "Sizes",
    component: "Sizes/Index",
    pageProps: { sizes: [] },
  },
  { divider: true, key: "divider-sections" },
];

const usersLink: NavigationLink = {
  href: routes.users.index.path(),
  label: "Users",
  component: "Users/Index",
  pageProps: { users: [] },
};

export default function AppNavigation() {
  const { auth } = usePage<PageProps>().props;
  const user = auth.user;

  return (
    <header className="container mx-auto pt-2 px-4 lg:px-0">
      <nav
        className="navigation-main relative flex flex-col items-stretch gap-3 lg:flex-row lg:items-center"
        aria-label="Main navigation"
      >
        <NavigationBrand />
        <NavigationActions user={user} />
      </nav>
    </header>
  );
}

function NavigationBrand() {
  return (
    <ul className="navigation-logo flex w-full items-center justify-between lg:w-auto">
      <li className="text-gray-700 dark:text-gray-500">
        <i className="icn mr-2 text-2xl" aria-hidden="true">
          😸
        </i>
        <strong className="align-text-bottom">StoreMate</strong>
      </li>
    </ul>
  );
}

function NavigationActions({ user }: { user: PageProps["auth"]["user"] }) {
  if (user?.role === "guest") {
    return <GuestNavigationActions />;
  }

  return <AuthenticatedNavigationActions user={user} />;
}

function GuestNavigationActions() {
  const handleLogOut = useCallback(() => {
    logOut();
  }, []);

  return (
    <ul className="navigation-links text-sm flex flex-wrap items-center gap-2 lg:flex-nowrap lg:whitespace-nowrap">
      <li>
        <button onClick={handleLogOut} type="button">
          Log Out
        </button>
      </li>
    </ul>
  );
}

function AuthenticatedNavigationActions({ user }: { user: PageProps["auth"]["user"] }) {
  const { closeDropdown, dropdownRef, isOpen, toggleDropdown } = useNavigationDropdown();

  return (
    <ul className="navigation-links text-sm flex flex-wrap items-center gap-2 lg:flex-nowrap lg:whitespace-nowrap">
      <NavigationPrimaryLinks onSelect={closeDropdown} />
      <NavigationOverflowMenu
        closeDropdown={closeDropdown}
        dropdownRef={dropdownRef}
        isOpen={isOpen}
        onToggle={toggleDropdown}
        user={user}
      />
    </ul>
  );
}

function NavigationPrimaryLinks({ onSelect }: { onSelect?: () => void }) {
  return (
    <>
      <NavigationLinkGroup links={primaryLinks.slice(0, 2)} onSelect={onSelect} />
      <NavigationSeparator />
      <NavigationLinkGroup links={primaryLinks.slice(2, 5)} onSelect={onSelect} />
      <NavigationSeparator />
      <NavigationLinkGroup links={primaryLinks.slice(5)} onSelect={onSelect} />
    </>
  );
}

function NavigationOverflowMenu({
  closeDropdown,
  dropdownRef,
  isOpen,
  onToggle,
  user,
}: {
  closeDropdown: () => void;
  dropdownRef: ReturnType<typeof useNavigationDropdown>["dropdownRef"];
  isOpen: boolean;
  onToggle: () => void;
  user: PageProps["auth"]["user"];
}) {
  const handleLogOut = useCallback(() => {
    logOut(closeDropdown);
  }, [closeDropdown]);

  return (
    <li className="navigation-dropdown ml-0 lg:ml-6" data-open={isOpen} ref={dropdownRef}>
      <button
        className="navigation-dropdown_button"
        aria-controls="navigation-dropdown-links"
        aria-expanded={isOpen}
        aria-haspopup="menu"
        aria-label="More navigation links"
        onClick={onToggle}
        type="button"
      >
        <Bars3Icon className="h-5 w-5" aria-hidden="true" />
      </button>
      <ul className="navigation-dropdown_menu" aria-hidden={!isOpen} id="navigation-dropdown-links">
        <NavigationDropdownItems items={overflowLinks} onSelect={closeDropdown} />
        {user?.role === "admin" ? (
          <NavigationLinkItem
            className="navigation-dropdown_link"
            link={usersLink}
            onSelect={closeDropdown}
          />
        ) : null}
        <li>
          <button className="navigation-dropdown_link" onClick={handleLogOut} type="button">
            Log Out
          </button>
        </li>
      </ul>
    </li>
  );
}

function NavigationLinkGroup({
  links,
  onSelect,
}: {
  links: NavigationLink[];
  onSelect?: () => void;
}) {
  return (
    <>
      {links.map((link) => (
        <NavigationLinkItem key={link.href} link={link} onSelect={onSelect} />
      ))}
    </>
  );
}

function NavigationDropdownItems({
  items,
  onSelect,
}: {
  items: Array<NavigationLink | NavigationDivider>;
  onSelect?: () => void;
}) {
  return (
    <>
      {items.map((item) =>
        "divider" in item ? (
          <NavigationSeparator key={item.key} className="pb-3" />
        ) : (
          <NavigationLinkItem
            className="navigation-dropdown_link"
            key={item.href}
            link={item}
            onSelect={onSelect}
          />
        ),
      )}
    </>
  );
}

function NavigationLinkItem({
  className,
  link,
  onSelect,
}: {
  className?: string;
  link: NavigationLink;
  onSelect?: () => void;
}) {
  return (
    <li>
      <Link
        href={link.href}
        component={link.component}
        onClick={onSelect}
        pageProps={withSharedPageProps(link.pageProps)}
        className={className}
        prefetch
      >
        {link.label}
      </Link>
    </li>
  );
}

function NavigationSeparator({ className = "hidden lg:block lg:ml-6" }: { className?: string }) {
  return <li aria-hidden="true" className={className} />;
}

function logOut(onLoggedOut?: () => void) {
  if (!window.confirm("Are you sure you want to log out?")) return;

  onLoggedOut?.();
  router.post(routes.sessions.destroy.path());
}

function withSharedPageProps(pageProps: Record<string, unknown>) {
  return (_currentProps: Record<string, unknown>, sharedProps: Record<string, unknown>) => ({
    ...sharedProps,
    ...pageProps,
  });
}
