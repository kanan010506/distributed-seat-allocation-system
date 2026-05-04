const pool = require('../config/db');

exports.getMyAllocation = async (req, res, next) => {
    try {
        const studentId = req.user.studentId;
        const [allocation] = await pool.query(
            `SELECT SA.*, SM.Category as Seat_Category, P.Program_Name, I.Institute_Name 
             FROM SEAT_ALLOCATION SA
             JOIN SEAT_MATRIX SM ON SA.Seat_ID = SM.Seat_ID
             JOIN PROGRAM P ON SM.Program_ID = P.Program_ID
             JOIN INSTITUTE I ON P.Institute_ID = I.Institute_ID
             WHERE SA.Student_ID = ? AND SA.Allocation_Status != 'Withdrawn'`,
            [studentId]
        );
        
        if (allocation.length === 0) {
            return res.json({ success: true, data: null, message: 'No allocation found' });
        }
        
        res.json({ success: true, data: allocation[0] });
    } catch (err) {
        next(err);
    }
};

exports.runAllocation = async (req, res, next) => {
    try {
        const [result] = await pool.query('CALL AllocateSeats()');
        const summary = result[0][0]; 
        res.json({ success: true, message: 'Allocation round completed', data: summary });
    } catch (err) {
        next(err);
    }
};
