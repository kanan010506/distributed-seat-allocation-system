// src/config/constants.js
// Central place for all magic values. Never hardcode these in business logic.

const ROLES = Object.freeze({
  ADMIN:   'Admin',
  COLLEGE: 'College',
  STUDENT: 'Student',
});

// These must exactly match your CHOICE.Status ENUM
const CHOICE_STATUS = Object.freeze({
  ACTIVE:    'Active',
  WITHDRAWN: 'Withdrawn',
  ALLOCATED: 'Allocated',
});

// These must exactly match SEAT_ALLOCATION.Allocation_Status ENUM
const ALLOC_STATUS = Object.freeze({
  ALLOCATED: 'Allocated',
  REJECTED:  'Rejected',
  WITHDRAWN: 'Withdrawn',
});

// These must exactly match SEAT_ALLOCATION.Admission_Status ENUM
const ADMISSION_STATUS = Object.freeze({
  PENDING:   'Pending',
  CONFIRMED: 'Confirmed',
  CANCELLED: 'Cancelled',
});

module.exports = { ROLES, CHOICE_STATUS, ALLOC_STATUS, ADMISSION_STATUS };