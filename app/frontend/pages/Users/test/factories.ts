import type { UserFormValues } from "../components/Form";
import type { UserRecord as IndexUserRecord } from "../components/IndexTable";

export function makeUserForm(
  overrides: Partial<UserFormValues> = {}
): UserFormValues {
  return {
    id: 1,
    email_address: "ash@example.com",
    first_name: "Ash",
    last_name: "Ketchum",
    role: "manager",
    path: "/users/1",
    ...overrides,
  };
}

export function makeUser(
  overrides: Partial<IndexUserRecord> = {}
): IndexUserRecord {
  return {
    id: 1,
    email_address: "ash@example.com",
    first_name: "Ash",
    last_name: "Ketchum",
    role: "manager",
    created_at: "19 May 2026",
    updated_at: "20 May 2026",
    path: "/users/1",
    edit_path: "/users/1/edit",
    destroy_path: "/users/1",
    ...overrides,
  };
}
