import { usePage } from "@inertiajs/react";
import { useEffect } from "react";

import type { PageProps } from "@/types/inertia";

const ENVIRONMENT_TAGS: Record<string, string> = {
  development: "DEV",
  production: "PRD",
  staging: "STG",
  test: "TST",
};

const AUTH_PAGE_TITLES: Record<string, string> = {
  "Passwords/Edit": "Reset password",
  "Passwords/New": "Forgot password",
  "Sessions/New": "Sign in",
  "Signups/New": "Sign up",
};

export function useDocumentTitle() {
  const page = usePage<PageProps>();
  const title = browserTitle(page.component, page.props.breadcrumb, page.props.environment);

  useEffect(() => {
    document.title = title;
  }, [title]);
}

export function browserTitle(
  component: string,
  breadcrumb: string | null,
  environment = "development",
) {
  const title = AUTH_PAGE_TITLES[component] ?? breadcrumb ?? componentTitle(component);
  const tag = ENVIRONMENT_TAGS[environment] ?? environment.slice(0, 3).toUpperCase();

  return `[${tag}] ${title} — Store Mate`;
}

function componentTitle(component: string) {
  const [resource, action] = component.split("/");
  const resourceTitle = resource.replace(/([a-z])([A-Z])/g, "$1 $2");
  const singularResourceTitle = resourceTitle.replace(/s$/, "");

  switch (action) {
    case "Edit":
      return `Edit ${singularResourceTitle}`;
    case "New":
      return `New ${singularResourceTitle}`;
    case "Show":
      return `${singularResourceTitle} details`;
    default:
      return resourceTitle;
  }
}
