import { lazy } from "react";

import type SmartSelectType from "./SmartSelect";

// eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion -- React.lazy erases generic type params; cast restores Option inference in JSX
const SmartSelect = lazy(() => import("./SmartSelect")) as unknown as typeof SmartSelectType;

export default SmartSelect;
