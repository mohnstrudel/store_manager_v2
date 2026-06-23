import { lazy } from "react";
import type SmartSelectType from "./SmartSelect";

/**
 * Lazily-loaded SmartSelect. React.lazy erases the component's generic type
 * params, so we restore them with a cast — this is the one place that needs it,
 * keeping the `Option` inference working at every call site.
 */
// eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion -- React.lazy erases generic type params; cast restores Option inference in JSX
const SmartSelect = lazy(() => import("./SmartSelect")) as unknown as typeof SmartSelectType;

export default SmartSelect;
