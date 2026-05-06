// js/api.js — centralised API client
const BASE_URL = 'http://localhost:5001/api';

const api = {
  _token() { return localStorage.getItem('token'); },

  async _req(path, options = {}) {
    const headers = { 'Content-Type': 'application/json' };
    const token = this._token();
    if (token) headers['Authorization'] = `Bearer ${token}`;
    const res = await fetch(BASE_URL + path, { ...options, headers });
    const data = await res.json();
    if (res.status === 401) { localStorage.clear(); window.location.href = '/index.html'; }
    return data;
  },

  // ── AUTH ──────────────────────────────────────────────────────────────────
  login:    (email, password) =>
    api._req('/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) }),

  register: (body) =>
    api._req('/auth/register', { method: 'POST', body: JSON.stringify(body) }),

  // ── STUDENT ───────────────────────────────────────────────────────────────
  getProfile: () => api._req('/students/me'),

  // ── PROGRAMS (public / student) ───────────────────────────────────────────
  getInstitutes: () => api._req('/programs/institutes'),
  getPrograms:   (instituteId) =>
    api._req('/programs' + (instituteId ? `?instituteId=${instituteId}` : '')),
  getSeatMatrix: (programId) => api._req(`/programs/${programId}/matrix`),

  // ── CHOICES ───────────────────────────────────────────────────────────────
  getChoices:     () => api._req('/choices'),
  addChoices:     (programIds) =>
    api._req('/choices', { method: 'POST', body: JSON.stringify({ programIds }) }),
  deleteChoice:   (choiceId) => api._req(`/choices/${choiceId}`, { method: 'DELETE' }),
  reorderChoices: (orderedChoiceIds) =>
    api._req('/choices/reorder', { method: 'PUT', body: JSON.stringify({ orderedChoiceIds }) }),

  // ── ALLOCATIONS (student) ─────────────────────────────────────────────────
  getMyAllocation: () => api._req('/allocations/me'),
  runAllocation:   () => api._req('/allocations/run', { method: 'POST' }),

  // ── REPORTS (admin) ───────────────────────────────────────────────────────
  getAllocationReport: () => api._req('/reports/allocation'),
  getAllAllocations:   () => api._req('/reports/allocations'),

  // ── COLLEGE ───────────────────────────────────────────────────────────────
  collegeDashboard: () =>
    api._req('/college/dashboard'),

  collegePrograms: () =>
    api._req('/college/programs'),

  collegeSeatMatrix: (programId) =>
    api._req(`/college/programs/${programId}/matrix`),

  collegeAllocations: (programId) =>
    api._req('/college/allocations' + (programId ? `?programId=${programId}` : '')),

  collegeConfirmAdmission: (allocationId) =>
    api._req(`/college/allocations/${allocationId}/confirm`, { method: 'POST' }),

  collegeReport: () =>
    api._req('/college/report'),

  // ── SHARED ────────────────────────────────────────────────────────────────
  logout() { localStorage.clear(); window.location.href = '../index.html'; }
};