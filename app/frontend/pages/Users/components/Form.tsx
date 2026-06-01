import { usePage } from "@inertiajs/react";
import FormControl from "@/components/FormControl";
import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";

export type UserFormValues = {
  id: number;
  email_address: string;
  first_name: string;
  last_name: string;
  role: string;
  path: string;
};

type UserFormProps = {
  canEditRole: boolean;
  roleOptions: [string, string][];
  user: UserFormValues;
};

export default function Form({ canEditRole, roleOptions, user }: UserFormProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <ResourceForm
      action={`/users/${user.id}`}
      cancelHref={user.path}
      method="patch"
      submitLabel="Update User"
    >
      <FormInput
        defaultValue={user.email_address}
        error={errors.email_address}
        label="Email"
        name="user[email_address]"
        type="email"
      />
      <FormInput
        defaultValue={user.first_name}
        error={errors.first_name}
        label="First Name"
        name="user[first_name]"
      />
      <FormInput
        defaultValue={user.last_name}
        error={errors.last_name}
        label="Last Name"
        name="user[last_name]"
      />
      {canEditRole && (
        <FormControl error={errors.role} htmlFor="user_role" label="Role">
          <select defaultValue={user.role} id="user_role" name="user[role]">
            <option value="">Select role</option>
            {roleOptions.map(([label, value]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </FormControl>
      )}
    </ResourceForm>
  );
}
