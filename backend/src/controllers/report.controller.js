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
