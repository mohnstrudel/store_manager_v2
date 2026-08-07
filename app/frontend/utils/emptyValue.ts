type EmptyableValue = string | number | null | undefined;

export function isEmptyValue(value: EmptyableValue): boolean {
  return value === null || value === undefined || value === "" || value === 0;
}

export function emptyToNull<T extends string | number>(value: T | null | undefined): T | null {
  return isEmptyValue(value) ? null : (value as T);
}
