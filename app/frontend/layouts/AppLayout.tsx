import type { MouseEvent, ReactNode } from "react";

import AppNavigation from "@/components/app-navigation/AppNavigation";
import Breadcrumbs from "@/components/breadcrumbs/Breadcrumbs";
import GrinningCatIcon from "@/components/GrinningCatIcon";
import Notifications from "@/components/notifications/Notifications";
import { useDocumentTitle } from "@/utils/useDocumentTitle";

export default function AppLayout({ children }: { children: ReactNode }) {
  useDocumentTitle();

  return (
    <div className="flex flex-col min-h-screen">
      <AppNavigation />
      <main className="flex flex-col flex-grow container mx-auto mt-4 mb-24 px-4 lg:mt-8 lg:mb-60 lg:px-0">
        <Notifications live />
        <Breadcrumbs />
        {children}
      </main>
      <footer className="container mx-auto text-center mb-8 px-4 lg:px-0">
        <button
          className="link no-underline hover:bg-transparent"
          type="button"
          onClick={handleScrollToTop}
        >
          <GrinningCatIcon className="text-3xl text-gray-500" />
        </button>
      </footer>
    </div>
  );
}

function handleScrollToTop(_event: MouseEvent<HTMLButtonElement>) {
  window.scrollTo({ top: 0 });
}
