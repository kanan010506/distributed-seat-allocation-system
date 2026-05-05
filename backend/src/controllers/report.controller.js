const pool = require('../config/db');

exports.getAllocationReport = async (req, res, next) => {
    try {
        const [results] = await pool.query('CALL GenerateAllocationReport()');
        // Procedure GenerateAllocationReport returns 3 result sets
        const roundSummary = results[0];
        const programBreakdown = results[1];
        const categoryUsage = results[2];
        
        res.json({
            success: true,
            data: {
                roundSummary,
                programBreakdown,
                categoryUsage
            }
        });
    } catch (err) {
        next(err);
    }
};

exports.getAllAllocations = async (req, res, next) => {
    try {
        const [rows] = await pool.query(`
            SELECT 
                S.Name         AS Student_Name,
                P.Program_Name,
                I.Institute_Name,
                SM.Category    AS Seat_Category,
                SA.Allocation_Status,
                SA.Admission_Status
            FROM SEAT_ALLOCATION SA
            JOIN SEAT_MATRIX SM  ON SM.Seat_ID     = SA.Seat_ID
            JOIN PROGRAM P       ON P.Program_ID   = SM.Program_ID
            JOIN INSTITUTE I     ON I.Institute_ID = P.Institute_ID
            JOIN STUDENT S       ON S.Student_ID   = SA.Student_ID
            ORDER BY SA.Allocation_ID
        `);
        res.json({ success: true, data: rows });
    } catch (err) {
        next(err);
    }
};