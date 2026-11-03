export const keepPageVisit = { preserveScroll: true, preserveState: true } as const;

export const leaveModalVisit = { ...keepPageVisit, replace: true } as const;
