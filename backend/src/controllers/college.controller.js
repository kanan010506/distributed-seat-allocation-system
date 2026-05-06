// src/controllers/college.controller.js
// Handles all College-role endpoints.
// Every handler reads req.user.instituteId (injected by the JWT
// middleware) so a college user can ONLY see their own data.

const pool = require('../config/db');

// ── GET /api/college/dashboard ───────────────────────────────
// Returns institute profile + aggregate seat/allocation stats.
exports.getDashboard = async (req, res, next) => {
    try {
        const instituteId = req.user.instituteId;

        // Institute profile
        const [[institute]] = await pool.query(
            `SELECT * FROM INSTITUTE WHERE Institute_ID = ?`,
            [instituteId]
        );
        if (!institute) {
            return res.status(404).json({ success: false, error: 'Institute not found.' });
        }

        // Aggregate seat stats across all programs of this institute
        const [[seatStats]] = await pool.query(
            `SELECT
                COUNT(DISTINCT P.Program_ID)    AS total_programs,
                SUM(SM.Total_Seats)             AS total_seats,
                SUM(SM.Filled_Seats)            AS filled_seats,
                SUM(SM.Available_Seats)         AS available_seats
             FROM PROGRAM P
             JOIN SEAT_MATRIX SM ON SM.Program_ID = P.Program_ID
             WHERE P.Institute_ID = ?`,
            [instituteId]
        );

        // Allocation count (non-withdrawn) for this institute
        const [[allocStats]] = await pool.query(
            `SELECT
                COUNT(SA.Allocation_ID)                         AS total_allocated,
                SUM(SA.Admission_Status = 'Confirmed')          AS confirmed,
                SUM(SA.Admission_Status = 'Pending')            AS pending,
                SUM(SA.Allocation_Status = 'Withdrawn')         AS withdrawn
             FROM SEAT_ALLOCATION SA
             JOIN SEAT_MATRIX SM ON SM.Seat_ID = SA.Seat_ID
             JOIN PROGRAM P ON P.Program_ID = SM.Program_ID
             WHERE P.Institute_ID = ?`,
            [instituteId]
        );

        res.json({
            success: true,
            data: { institute, seatStats, allocStats }
        });
    } catch (err) {
        next(err);
    }
};

// ── GET /api/college/programs ────────────────────────────────
// Returns all programs of the college with per-program seat totals.
exports.getPrograms = async (req, res, next) => {
    try {
        const instituteId = req.user.instituteId;

        const [programs] = await pool.query(
            `SELECT
                P.Program_ID,
                P.Program_Name,
                P.Degree,
                P.Duration_Years,
                SUM(SM.Total_Seats)     AS total_seats,
                SUM(SM.Filled_Seats)    AS filled_seats,
                SUM(SM.Available_Seats) AS available_seats
             FROM PROGRAM P
             JOIN SEAT_MATRIX SM ON SM.Program_ID = P.Program_ID
             WHERE P.Institute_ID = ?
             GROUP BY P.Program_ID, P.Program_Name, P.Degree, P.Duration_Years
             ORDER BY P.Program_Name`,
            [instituteId]
        );

        res.json({ success: true, data: programs });
    } catch (err) {
        next(err);
    }
};

// ── GET /api/college/programs/:programId/seats ────────────────
// Returns the category-wise seat matrix for one program.
// Guards that the program belongs to req.user.instituteId.
exports.getSeatMatrix = async (req, res, next) => {
    try {
        const instituteId = req.user.instituteId;
        const { programId } = req.params;

        const [rows] = await pool.query(
            `SELECT SM.*
             FROM SEAT_MATRIX SM
             JOIN PROGRAM P ON P.Program_ID = SM.Program_ID
             WHERE SM.Program_ID = ? AND P.Institute_ID = ?
             ORDER BY SM.Category`,
            [programId, instituteId]
        );

        res.json({ success: true, data: rows });
    } catch (err) {
        next(err);
    }
};

// ── GET /api/college/allocations ─────────────────────────────
// Returns all allocated students for this institute.
// Supports optional ?programId= filter.
exports.getAllocations = async (req, res, next) => {
    try {
        const instituteId = req.user.instituteId;
        const { programId } = req.query;

        let query = `
            SELECT
                SA.Allocation_ID,
                S.Student_ID,
                S.Name          AS student_name,
                S.Email         AS student_email,
                S.Gender,
                S.Category,
                S.JEE_Rank,
                P.Program_ID,
                P.Program_Name,
                P.Degree,
                SM.Category     AS seat_category,
                SA.Allocation_Status,
                SA.Admission_Status,
                SA.Allocation_Date
            FROM SEAT_ALLOCATION SA
            JOIN STUDENT     S   ON S.Student_ID  = SA.Student_ID
            JOIN SEAT_MATRIX SM  ON SM.Seat_ID    = SA.Seat_ID
            JOIN PROGRAM     P   ON P.Program_ID  = SM.Program_ID
            WHERE P.Institute_ID = ?
        `;
        const params = [instituteId];

        if (programId) {
            query += ' AND P.Program_ID = ?';
            params.push(programId);
        }

        query += ' ORDER BY S.JEE_Rank ASC';

        const [allocations] = await pool.query(query, params);
        res.json({ success: true, data: allocations });
    } catch (err) {
        next(err);
    }
};

// ── PATCH /api/college/allocations/:allocationId/confirm ─────
// College marks a student's admission as Confirmed.
exports.confirmAdmission = async (req, res, next) => {
    try {
        const instituteId = req.user.instituteId;
        const { allocationId } = req.params;

        // Verify the allocation belongs to this institute
        const [[row]] = await pool.query(
            `SELECT SA.Allocation_ID
             FROM SEAT_ALLOCATION SA
             JOIN SEAT_MATRIX SM ON SM.Seat_ID = SA.Seat_ID
             JOIN PROGRAM P ON P.Program_ID = SM.Program_ID
             WHERE SA.Allocation_ID = ? AND P.Institute_ID = ?`,
            [allocationId, instituteId]
        );

        if (!row) {
            return res.status(403).json({ success: false, error: 'Allocation not found or access denied.' });
        }

        await pool.query(
            `UPDATE SEAT_ALLOCATION
             SET Admission_Status = 'Confirmed'
             WHERE Allocation_ID = ?`,
            [allocationId]
        );

        res.json({ success: true, message: 'Admission confirmed.' });
    } catch (err) {
        next(err);
    }
};

// ── GET /api/college/report ───────────────────────────────────
// Category-wise fill report for the college — mirrors
// GenerateAllocationReport() result set 3, scoped to this institute.
exports.getReport = async (req, res, next) => {
    try {
        const instituteId = req.user.instituteId;

        const [rows] = await pool.query(
            `SELECT
                P.Program_Name,
                P.Degree,
                SM.Category,
                SM.Total_Seats,
                SM.Filled_Seats,
                SM.Available_Seats,
                SM.Cutoff_Rank,
                ROUND(100.0 * SM.Filled_Seats / NULLIF(SM.Total_Seats, 0), 2) AS utilisation_pct
             FROM SEAT_MATRIX SM
             JOIN PROGRAM P ON P.Program_ID = SM.Program_ID
             WHERE P.Institute_ID = ?
             ORDER BY P.Program_Name, SM.Category`,
            [instituteId]
        );

        res.json({ success: true, data: rows });
    } catch (err) {
        next(err);
    }
};