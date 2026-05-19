import { Link as InertiaLink } from "@inertiajs/react";
import { ComponentProps, ReactNode } from "react";

type LinkProps = ComponentProps<typeof InertiaLink> & {
  children: ReactNode;
};

export default function Link({ children, ...props }: LinkProps) {
  return <InertiaLink {...props}>{children}</InertiaLink>;
}
