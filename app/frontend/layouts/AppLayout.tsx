import type { MouseEvent, ReactNode } from "react";
import Breadcrumbs from "@/components/Breadcrumbs";
import FlashMessages from "@/components/FlashMessages";
import AppNavigation from "@/components/AppNavigation";

export default function AppLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex flex-col min-h-screen">
      <AppNavigation />
      <main className="flex flex-col flex-grow container mx-auto mt-4 mb-24 px-4 lg:mt-8 lg:mb-60 lg:px-0">
        <FlashMessages />
        <Breadcrumbs />
        {children}
      </main>
      <footer className="container mx-auto text-center mb-8 px-4 lg:px-0">
        <a className="link no-underline hover:bg-transparent" href="" onClick={handleScrollToTop}>
          <i className="icn text-3xl text-gray-500" aria-hidden="true">
            😸
          </i>
        </a>
      </footer>
    </div>
  );
}

function handleScrollToTop(event: MouseEvent<HTMLAnchorElement>) {
  event.preventDefault();
  window.scrollTo({ top: 0 });
}
