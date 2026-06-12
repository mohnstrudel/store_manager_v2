// Canonical test double for "@inertiajs/react".
//
// Activate per test file with:
//   vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));
//
// Assert navigation via the shared router mock:
//   import { router } from "@inertiajs/react";
//   expect(router.delete).toHaveBeenCalledWith("/products/1", ...);
//
// Drive page-dependent rendering with the helpers:
//   import { mockPage, mockPageProps } from "@/test/mocks/inertia";
//   mockPageProps({ errors: { name: "can't be blank" } }); // before render()
//
// Queue server-side form errors:
//   import { nextFormErrors } from "@/test/mocks/inertia";
//   nextFormErrors.mockReturnValueOnce({ field: "message" });
//
// vitest.config.ts sets mockReset: true — call history and mockReturnValue
// overrides reset automatically before each test. Apply helpers in beforeEach
// or per test, never at module/describe scope.

import { useState, type AnchorHTMLAttributes, type MouseEvent, type ReactNode } from "react";
import { vi } from "vitest";

// Structural match of @inertiajs/core's Page type (transitive dep, not directly importable).
type MockPage = {
  component: string;
  flash: Record<string, unknown>;
  props: Record<string, unknown>;
  rememberedState: Record<string, unknown>;
  rescuedProps: string[];
  url: string;
  version: string | null;
};

type PageOverrides = Partial<MockPage>;

export function buildPage(overrides: PageOverrides = {}): MockPage {
  return {
    component: "TestPage",
    url: "/",
    version: "test",
    flash: {},
    rescuedProps: [],
    rememberedState: {},
    ...overrides,
    props: { errors: {}, ...overrides.props },
  };
}

export const usePage = vi.fn<() => MockPage>(() => buildPage());

export function mockPage(overrides: PageOverrides) {
  usePage.mockReturnValue(buildPage(overrides));
}

export function mockPageProps(props: Record<string, unknown>) {
  mockPage({ props });
}

export const router = {
  delete: vi.fn<(...args: unknown[]) => unknown>(),
  get: vi.fn<(...args: unknown[]) => unknown>(),
  on: vi.fn<(event: string, callback: () => void) => () => void>(() => () => {}),
  patch: vi.fn<(...args: unknown[]) => unknown>(),
  post: vi.fn<(...args: unknown[]) => unknown>(),
  prefetch: vi.fn<(...args: unknown[]) => unknown>(),
  put: vi.fn<(...args: unknown[]) => unknown>(),
  visit: vi.fn<(...args: unknown[]) => unknown>(),
};

export const createInertiaApp = vi.fn<(...args: unknown[]) => unknown>();

type LinkStubProps = Omit<AnchorHTMLAttributes<HTMLAnchorElement>, "href"> & {
  href: string;
  method?: string;
  prefetch?: unknown;
  component?: unknown;
  pageProps?: unknown;
};

export function Link({
  children,
  href,
  method,
  onClick,
  prefetch: _prefetch,
  component: _component,
  pageProps: _pageProps,
  ...anchorProps
}: LinkStubProps) {
  const handleClick = (event: MouseEvent<HTMLAnchorElement>) => {
    event.preventDefault();
    onClick?.(event);
  };

  return (
    <a data-method={method} href={href} {...anchorProps} onClick={handleClick}>
      {children}
    </a>
  );
}

type FormSlot = { errors: Record<string, string>; processing: boolean };

type FormStubProps = {
  action: string;
  children: ReactNode | ((slot: FormSlot) => ReactNode);
  method?: string;
};

export function Form({ action, children, method }: FormStubProps) {
  const errors = (usePage().props.errors ?? {}) as Record<string, string>;
  const slot: FormSlot = { errors, processing: false };

  return (
    <form action={action} data-method={method}>
      {typeof children === "function" ? children(slot) : children}
    </form>
  );
}

// vi.fn with a default impl so mockReset restores () => null between tests.
// Usage: nextFormErrors.mockReturnValueOnce({ field: "message" })
export const nextFormErrors = vi.fn<() => Record<string, string> | null>(() => null);

type SubmitOptions = {
  onBefore?: () => unknown;
  onError?: (errors: Record<string, string>) => void;
  onSuccess?: () => void;
} & Record<string, unknown>;

type SubmitMethod = "delete" | "get" | "patch" | "post" | "put";

function useFormStub<TData extends Record<string, unknown>>(initialData: TData) {
  const [data, setDataState] = useState(initialData);
  const [errors, setErrors] = useState<Record<string, string>>({});
  let transformPayload: ((data: TData) => unknown) | null = null;

  const submit = (method: SubmitMethod, url: string, options: SubmitOptions = {}) => {
    options.onBefore?.();
    router[method](url, transformPayload ? transformPayload(data) : data, options);

    const serverErrors = nextFormErrors();
    if (serverErrors) {
      setErrors(serverErrors);
      options.onError?.(serverErrors);
    } else {
      options.onSuccess?.();
    }
  };

  const form = {
    data,
    errors,
    processing: false,
    clearErrors: (...fields: string[]) => {
      setErrors((currentErrors) => {
        if (fields.length === 0) return {};
        return Object.fromEntries(
          Object.entries(currentErrors).filter(([field]) => !fields.includes(field)),
        );
      });
    },
    setData: (update: TData | ((data: TData) => TData)) => {
      setDataState((currentData) =>
        typeof update === "function" ? (update as (data: TData) => TData)(currentData) : update,
      );
    },
    transform: (callback: (data: TData) => unknown) => {
      transformPayload = callback;
    },
    // Optimistic UI is not observable in component tests (rows render from
    // test-supplied props, not Inertia page props), so the callback is dropped.
    optimistic: (_callback: unknown) => form,
    delete: (url: string, options?: SubmitOptions) => submit("delete", url, options),
    get: (url: string, options?: SubmitOptions) => submit("get", url, options),
    patch: (url: string, options?: SubmitOptions) => submit("patch", url, options),
    post: (url: string, options?: SubmitOptions) => submit("post", url, options),
    put: (url: string, options?: SubmitOptions) => submit("put", url, options),
  };

  return form;
}

export const useForm = vi.fn<typeof useFormStub>(useFormStub);
